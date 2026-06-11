# IoE Urban Agriculture — ESP32 Node (MicroPython)

Reads soil moisture + temperature, waters autonomously via relay, reports to the FastAPI backend.

## Bill of materials

- ESP32 dev board (WROOM-32 or similar)
- Capacitive soil moisture sensor (analog out) — capacitive over resistive: no electrode corrosion
- DS18B20 waterproof temperature probe + 4.7 kΩ resistor
- 1-channel 5V relay module
- 5V water pump + tubing, separate 5V supply for the pump

## Wiring

| Component | Pin | ESP32 |
|---|---|---|
| Soil sensor | VCC / GND / AOUT | 3V3 / GND / **GPIO34** |
| DS18B20 | VCC / GND / DATA | 3V3 / GND / **GPIO4** (4.7 kΩ between DATA and 3V3) |
| Relay module | VCC / GND / IN | 5V (VIN) / GND / **GPIO26** |
| Pump | via relay COM + NO | powered by its own 5V supply |

**Important:** the pump must NOT draw power from the ESP32's 3V3/5V pins — use a separate
supply through the relay contacts, and tie all grounds together.

## Flash

1. Flash MicroPython firmware (>= 1.21): https://micropython.org/download/ESP32_GENERIC/
   ```powershell
   pip install esptool mpremote
   esptool --port COM3 erase_flash
   esptool --port COM3 write_flash 0x1000 ESP32_GENERIC-xxxxxxxx.bin
   ```
2. Edit `config.py`: Wi-Fi credentials, `BACKEND_URL` (LAN IP of the FastAPI machine),
   `DEVICE_API_KEY` (must match `backend/.env`), `DEVICE_ID` (must match a
   `plant_profiles.device_id` row in Supabase).
3. Upload the three files:
   ```powershell
   mpremote connect COM3 fs cp config.py boot.py main.py :
   mpremote connect COM3 reset
   ```
4. Watch logs: `mpremote connect COM3 repl`

## Calibrate the soil sensor

Readings are raw 12-bit ADC (0-4095). In the REPL with the node running, note `soil_raw`:

1. Probe in dry air → set `SOIL_RAW_AIR` in `config.py`
2. Probe in a glass of water → set `SOIL_RAW_WATER`

## Behavior

- Cycle every `REPORT_INTERVAL_S` (default 60 s): read → decide → water → report.
- **Offline-first:** watering decisions use local thresholds, so the plant survives
  Wi-Fi or backend outages. Telemetry resumes when the network returns.
- Thresholds sync from the backend: each telemetry ACK carries the plant profile's
  values, which are applied and persisted to `thresholds.json` on the device.
  Change thresholds in the app/DB → the device adopts them within one cycle.
- Pump safety: 5 s bursts (configurable), `PUMP_COOLDOWN_S` (default 300 s) between
  waterings so water can soak in; relay forced off on boot and on any error.

## Using a DHT22 instead of DS18B20

Swap `read_temp()` in `main.py`:

```python
import dht
sensor = dht.DHT22(machine.Pin(config.PIN_TEMP_DATA))

def read_temp():
    try:
        sensor.measure()
        return sensor.temperature()
    except Exception as e:
        print("Temp read failed:", e)
        return None
```

No pull-up resistor needed (most DHT22 boards have one onboard).
