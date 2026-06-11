from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import plants, telemetry

app = FastAPI(
    title="IoE Urban Agriculture API",
    description="Telemetry ingestion for ESP32 devices and plant health data for the Flutter dashboard.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(telemetry.router)
app.include_router(plants.router)


@app.get("/healthz", tags=["meta"])
def healthz():
    return {"status": "ok"}
