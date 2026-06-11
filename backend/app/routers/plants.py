from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query

from app.config import get_settings
from app.db import get_supabase
from app.schemas import (
    HealthStatus,
    PlantHistory,
    PlantSummary,
    Reading,
    ThresholdConfig,
)

router = APIRouter(prefix="/api/v1/plants", tags=["plants"])


def get_user_id(authorization: str = Header(default="")) -> Optional[str]:
    """Resolve the Supabase user from a Bearer JWT.

    In DEV_ALLOW_ANON mode requests without a token see all plants —
    useful for classroom demos before auth is wired into the app.
    """
    settings = get_settings()
    if authorization.startswith("Bearer "):
        token = authorization.removeprefix("Bearer ")
        try:
            user = get_supabase().auth.get_user(token)
            return user.user.id
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
    if settings.dev_allow_anon:
        return None
    raise HTTPException(status_code=401, detail="Missing Bearer token")


def compute_status(reading: Optional[Reading], plant: dict) -> HealthStatus:
    """Plant health from latest reading vs profile thresholds. Moisture beats temp:
    a dry plant needs action regardless of temperature."""
    if reading is None or reading.soil_moisture is None:
        return "unknown"
    if reading.soil_moisture < float(plant["moisture_min"]):
        return "dry"
    if reading.soil_moisture > float(plant["moisture_max"]):
        return "wet"
    if reading.temperature_c is not None:
        if reading.temperature_c > float(plant["temp_max_c"]):
            return "hot"
        if reading.temperature_c < float(plant["temp_min_c"]):
            return "cold"
    return "healthy"


def to_reading(row: dict) -> Reading:
    return Reading(
        soil_moisture=row["soil_moisture"],
        soil_raw=row["soil_raw"],
        temperature_c=row["temperature_c"],
        pump_triggered=row["pump_triggered"],
        pump_duration_s=row["pump_duration_s"],
        recorded_at=row["recorded_at"],
    )


def to_summary(plant: dict, latest_row: Optional[dict]) -> PlantSummary:
    latest = to_reading(latest_row) if latest_row else None
    return PlantSummary(
        id=plant["id"],
        name=plant["name"],
        species=plant["species"],
        location=plant["location"],
        device_id=plant["device_id"],
        thresholds=ThresholdConfig(
            moisture_min=plant["moisture_min"],
            moisture_max=plant["moisture_max"],
            temp_min_c=plant["temp_min_c"],
            temp_max_c=plant["temp_max_c"],
            pump_duration_s=plant["pump_duration_s"],
        ),
        status=compute_status(latest, plant),
        latest=latest,
    )


@router.get("", response_model=list[PlantSummary])
def list_plants(user_id: Optional[str] = Depends(get_user_id)):
    """All plants for the user, each with its latest reading and health status."""
    sb = get_supabase()
    query = sb.table("plant_profiles").select("*")
    if user_id is not None:
        query = query.eq("user_id", user_id)
    plants = query.order("created_at").execute().data

    summaries = []
    for plant in plants:
        latest = (
            sb.table("sensor_logs")
            .select("*")
            .eq("plant_id", plant["id"])
            .order("recorded_at", desc=True)
            .limit(1)
            .execute()
        )
        summaries.append(to_summary(plant, latest.data[0] if latest.data else None))
    return summaries


def fetch_plant(plant_id: str, user_id: Optional[str]) -> dict:
    sb = get_supabase()
    query = sb.table("plant_profiles").select("*").eq("id", plant_id)
    if user_id is not None:
        query = query.eq("user_id", user_id)
    result = query.limit(1).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Plant not found")
    return result.data[0]


@router.get("/{plant_id}/current", response_model=PlantSummary)
def current_health(plant_id: str, user_id: Optional[str] = Depends(get_user_id)):
    """Latest reading + computed health status for one plant."""
    plant = fetch_plant(plant_id, user_id)
    latest = (
        get_supabase()
        .table("sensor_logs")
        .select("*")
        .eq("plant_id", plant_id)
        .order("recorded_at", desc=True)
        .limit(1)
        .execute()
    )
    return to_summary(plant, latest.data[0] if latest.data else None)


@router.get("/{plant_id}/history", response_model=PlantHistory)
def history(
    plant_id: str,
    hours: int = Query(default=24, ge=1, le=720),
    limit: int = Query(default=500, ge=1, le=2000),
    user_id: Optional[str] = Depends(get_user_id),
):
    """Time-ordered readings for charts. Defaults to the last 24 hours."""
    fetch_plant(plant_id, user_id)  # 404 / ownership check
    since = datetime.now(timezone.utc) - timedelta(hours=hours)
    rows = (
        get_supabase()
        .table("sensor_logs")
        .select("*")
        .eq("plant_id", plant_id)
        .gte("recorded_at", since.isoformat())
        .order("recorded_at")
        .limit(limit)
        .execute()
    )
    return PlantHistory(
        plant_id=plant_id,
        hours=hours,
        readings=[to_reading(r) for r in rows.data],
    )
