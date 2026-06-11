from fastapi import APIRouter, Header, HTTPException

from app.config import get_settings
from app.db import get_supabase
from app.schemas import TelemetryAck, TelemetryIn, ThresholdConfig

router = APIRouter(prefix="/api/v1/telemetry", tags=["telemetry"])


@router.post("", response_model=TelemetryAck)
def ingest_telemetry(payload: TelemetryIn, x_device_key: str = Header(default="")):
    """Ingest one sensor cycle from an ESP32.

    The device authenticates with a shared secret header, never user credentials.
    The response echoes the plant's thresholds so edits made in the app reach
    the device on its next report cycle.
    """
    settings = get_settings()
    if x_device_key != settings.device_api_key:
        raise HTTPException(status_code=401, detail="Invalid device key")

    sb = get_supabase()
    plant = (
        sb.table("plant_profiles")
        .select("*")
        .eq("device_id", payload.device_id)
        .limit(1)
        .execute()
    )
    if not plant.data:
        raise HTTPException(
            status_code=404,
            detail=f"No plant profile registered for device '{payload.device_id}'",
        )
    plant = plant.data[0]

    log = (
        sb.table("sensor_logs")
        .insert(
            {
                "plant_id": plant["id"],
                "device_id": payload.device_id,
                "soil_moisture": payload.soil_moisture,
                "soil_raw": payload.soil_raw,
                "temperature_c": payload.temperature_c,
                "pump_triggered": payload.pump_triggered,
                "pump_duration_s": payload.pump_duration_s,
            }
        )
        .execute()
    )

    return TelemetryAck(
        log_id=log.data[0]["id"],
        plant_id=plant["id"],
        config=ThresholdConfig(
            moisture_min=plant["moisture_min"],
            moisture_max=plant["moisture_max"],
            temp_min_c=plant["temp_min_c"],
            temp_max_c=plant["temp_max_c"],
            pump_duration_s=plant["pump_duration_s"],
        ),
    )
