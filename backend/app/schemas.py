from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

HealthStatus = Literal["healthy", "dry", "wet", "hot", "cold", "unknown"]


class TelemetryIn(BaseModel):
    """Payload the ESP32 POSTs after each sensor cycle."""

    device_id: str
    soil_moisture: float = Field(ge=0, le=100, description="Normalized soil moisture %")
    soil_raw: Optional[int] = Field(default=None, description="Raw ADC value")
    temperature_c: float = Field(ge=-40, le=85)
    pump_triggered: bool = False
    pump_duration_s: Optional[int] = None


class ThresholdConfig(BaseModel):
    """Echoed back to the device so remote threshold edits propagate."""

    moisture_min: float
    moisture_max: float
    temp_min_c: float
    temp_max_c: float
    pump_duration_s: int


class TelemetryAck(BaseModel):
    ok: bool = True
    log_id: int
    plant_id: str
    config: ThresholdConfig


class Reading(BaseModel):
    soil_moisture: Optional[float]
    soil_raw: Optional[int]
    temperature_c: Optional[float]
    pump_triggered: bool
    pump_duration_s: Optional[int]
    recorded_at: datetime


class PlantSummary(BaseModel):
    id: str
    name: str
    species: Optional[str]
    location: Optional[str]
    device_id: str
    thresholds: ThresholdConfig
    status: HealthStatus
    latest: Optional[Reading]


class PlantHistory(BaseModel):
    plant_id: str
    hours: int
    readings: list[Reading]
