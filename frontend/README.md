# GrowSpace — IoE Urban Agriculture Dashboard (Flutter)

Dark-mode plant telemetry dashboard. Fetches live data from the FastAPI backend.

## Structure

```
lib/
├── main.dart                       # entry, theme wiring
├── theme.dart                      # palette, status colors/labels/emoji, typography
├── api/api_client.dart             # REST client (http)
├── models/plant.dart               # PlantSummary, Reading, Thresholds, PlantHistory
├── screens/
│   ├── dashboard_screen.dart       # plant list, summary banner, pull-to-refresh
│   └── plant_detail_screen.dart    # hero gauge, metric tiles, history charts
└── widgets/
    ├── plant_card.dart             # card with gauge, status, temp, pump badge
    ├── moisture_gauge.dart         # animated circular gauge
    ├── status_chip.dart            # animated health pill
    └── history_chart.dart          # fl_chart line chart + pump event markers
```

## Run

The API base URL defaults to `http://localhost:8000`. Override per platform:

```powershell
# Chrome (quickest demo, backend on same machine)
flutter run -d chrome

# Android emulator (host loopback is 10.0.2.2)
flutter run --dart-define=API_BASE=http://10.0.2.2:8000

# Physical phone on the same Wi-Fi (use your PC's LAN IP)
flutter run --dart-define=API_BASE=http://192.168.1.50:8000
```

Backend must be running (`backend/README.md`) with `DEV_ALLOW_ANON=true` until
Supabase Auth is wired into the app.

## UX behavior

- Dashboard polls every 30 s; pull-to-refresh for instant update.
- Staggered card entrance, Hero transition card → detail, animated gauge sweep,
  morphing status chips.
- Status colors: Thriving (green), Thirsty (orange, card glows), Soaked (blue),
  Too hot (red), Too cold (cyan), No data (grey).
- Detail screen: moisture + temperature charts (6h / 24h / 7d), dashed lime
  vertical lines mark pump events, "last watered" tile.

## Notes

- Built against Flutter 3.10.6 / Dart 3.0.6 — deps pinned accordingly
  (`fl_chart 0.63`, `http 1.x`, `google_fonts 5.x`). If you `flutter upgrade`,
  bump these.
- Seed a test plant in Supabase before demoing:
  ```sql
  insert into plant_profiles (device_id, name, species, location)
  values ('esp32-tower-01', 'Basil Tower A', 'Ocimum basilicum', 'Balcony rack 1');
  ```
