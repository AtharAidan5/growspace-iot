# IoE Urban Agriculture — Backend (FastAPI)

Telemetry ingestion for ESP32 devices and plant-health data for the Flutter dashboard.
Data lives in Supabase (project `ioe-urban-agriculture`, ref `owiudniwxjyochztmuar`).

## Setup

> The venv lives at `C:\Users\asus\.venvs\ioe-backend`, **not** inside the project.
> This project's OneDrive path is so long that a venv inside it exceeds the Windows
> 260-character path limit (`WinError 206` during `ensurepip`).

```powershell
cd backend
python -m venv C:\Users\asus\.venvs\ioe-backend
C:\Users\asus\.venvs\ioe-backend\Scripts\python -m pip install -r requirements.txt
copy .env.example .env   # then fill in SUPABASE_SERVICE_ROLE_KEY and DEVICE_API_KEY
```

The service-role key is in the Supabase Dashboard under **Project Settings → API Keys**.
It bypasses Row Level Security — keep it only in `backend/.env`, never on the ESP32 or in the app.

## Run

```powershell
.\run.bat
# or explicitly:
C:\Users\asus\.venvs\ioe-backend\Scripts\uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

> Bare `uvicorn` runs the global Microsoft Store Python, which lacks this project's
> dependencies (`ModuleNotFoundError: No module named 'pydantic_settings'`). Always
> use the venv path or `run.bat`.

Interactive docs: http://localhost:8000/docs

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/telemetry` | `X-Device-Key` header | ESP32 posts one sensor cycle; response echoes thresholds so the device syncs config |
| GET | `/api/v1/plants` | Bearer JWT (or anon in dev mode) | All plants with latest reading + health status |
| GET | `/api/v1/plants/{id}/current` | Bearer JWT (or anon) | Latest reading + status for one plant |
| GET | `/api/v1/plants/{id}/history?hours=24&limit=500` | Bearer JWT (or anon) | Time-ordered readings for charts |
| GET | `/healthz` | none | Liveness probe |

`DEV_ALLOW_ANON=true` in `.env` lets the GET endpoints work without a user token
(classroom/demo mode). Set it to `false` once the Flutter app sends Supabase Auth JWTs.

## Health status logic

Computed from the latest reading vs the plant profile thresholds, moisture first:
`dry` (< moisture_min) → `wet` (> moisture_max) → `hot` / `cold` (outside temp range) → `healthy`.
