# IoE Urban Agriculture — Student / Community Hands-On Project

End-to-end IoT plant monitoring: ESP32 nodes measure soil moisture + temperature,
water autonomously, and stream telemetry to a mobile dashboard.

```
ESP32 (MicroPython)  ──HTTP POST──▶  FastAPI backend  ──▶  Supabase (PostgreSQL)
        ▲                                  │
        └── thresholds sync (ACK) ◀────────┤
                                           ▼
                              Flutter app "GrowSpace" (GET, 30 s polling)
```

| Directory | Stack | Docs |
|---|---|---|
| `backend/` | Python FastAPI + supabase-py | `backend/README.md` |
| `hardware/` | MicroPython for ESP32 | `hardware/README.md` |
| `frontend/` | Flutter (dark dashboard UI) | `frontend/README.md` |

Supabase project: `ioe-urban-agriculture` (ref `owiudniwxjyochztmuar`, ap-southeast-1)
— tables `users`, `plant_profiles`, `sensor_logs`, RLS enabled.

> The project lives at `C:\ioe` deliberately. It was relocated out of OneDrive
> (2026-06-12) because the ~200-character OneDrive path broke the Windows 260-char
> limit and OneDrive sync locked build artifacts mid-build. Keep it on a short,
> unsynced path. The backend venv is at `C:\Users\asus\.venvs\ioe-backend`.

## Quick start (demo)

```powershell
# 1. backend (backend\.env must contain the Supabase service-role key)
cd C:\ioe\backend
.\run.bat

# 2. dashboard
cd C:\ioe\frontend
flutter run -d chrome
```

A demo plant (`Basil Tower A`, device `esp32-tower-01`) with 12 h of seeded telemetry
including one pump event is already in the database.

## Security model

- ESP32 holds only a shared `DEVICE_API_KEY` — no user credentials, no DB keys.
- The Supabase **service-role key** exists only in `backend/.env` (gitignored).
- The Flutter app reads via the backend; Supabase RLS protects direct access.
- `DEV_ALLOW_ANON=true` (classroom mode) leaves GET endpoints open — set to
  `false` and wire Supabase Auth into the app before any public deployment.
