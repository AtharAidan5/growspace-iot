# Device configuration — edit before flashing.

# --- Wi-Fi ---
WIFI_SSID = "YOUR_WIFI_SSID"
WIFI_PASSWORD = "YOUR_WIFI_PASSWORD"
WIFI_CONNECT_TIMEOUT_S = 20

# --- Backend ---
# LAN IP of the machine running FastAPI (not localhost — that is the ESP32 itself).
BACKEND_URL = "http://192.168.1.100:8000/api/v1/telemetry"
# Must match DEVICE_API_KEY in backend/.env
DEVICE_API_KEY = "change-me-to-a-long-random-string"
# Must match a plant_profiles.device_id row in Supabase
DEVICE_ID = "esp32-tower-01"

# --- Pins ---
PIN_SOIL_ADC = 34      # analog soil moisture sensor AOUT (input-only pin, ADC1)
PIN_TEMP_DATA = 4      # DS18B20 data line (needs 4.7k pull-up to 3V3)
PIN_RELAY = 26         # relay IN
RELAY_ACTIVE_LOW = True  # most 5V relay boards trigger on LOW

# --- Soil calibration (raw 12-bit ADC values, 0-4095) ---
# Measure your own: read soil_raw with the probe in dry air, then in a glass of water.
SOIL_RAW_AIR = 3100    # bone dry reading
SOIL_RAW_WATER = 1350  # fully submerged reading

# --- Local fallback thresholds ---
# Used until the backend ACK supplies the plant profile values.
# Overridden at runtime and persisted to thresholds.json.
MOISTURE_MIN = 30.0    # % — water below this
MOISTURE_MAX = 70.0    # % — never water above this
PUMP_DURATION_S = 5

# --- Timing ---
REPORT_INTERVAL_S = 60   # sensor/report cycle
PUMP_COOLDOWN_S = 300    # min seconds between waterings (let water soak in)
