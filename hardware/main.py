# main.py — sensor/water/report loop for the IoE Urban Agriculture node.
#
# Each cycle:
#   1. read soil moisture (analog ADC) and temperature (DS18B20)
#   2. decide locally whether to water (works fully offline)
#   3. POST telemetry to the FastAPI backend
#   4. apply threshold config echoed back by the server (remote re-config)

import json
import time

import machine
import network
import onewire
import ds18x20

import config

try:
    import requests  # MicroPython >= 1.21 bundles this
except ImportError:
    import urequests as requests

THRESHOLDS_FILE = "thresholds.json"

# --- hardware setup -------------------------------------------------------

soil_adc = machine.ADC(machine.Pin(config.PIN_SOIL_ADC))
soil_adc.atten(machine.ADC.ATTN_11DB)  # full 0-3.3V range

temp_bus = ds18x20.DS18X20(onewire.OneWire(machine.Pin(config.PIN_TEMP_DATA)))
temp_roms = temp_bus.scan()
if not temp_roms:
    print("WARNING: no DS18B20 found on pin", config.PIN_TEMP_DATA)

relay = machine.Pin(config.PIN_RELAY, machine.Pin.OUT)


def relay_off():
    relay.value(1 if config.RELAY_ACTIVE_LOW else 0)


def relay_on():
    relay.value(0 if config.RELAY_ACTIVE_LOW else 1)


relay_off()  # never boot with the pump running

# --- thresholds: config.py defaults -> thresholds.json -> server ACK ------

thresholds = {
    "moisture_min": config.MOISTURE_MIN,
    "moisture_max": config.MOISTURE_MAX,
    "pump_duration_s": config.PUMP_DURATION_S,
}

try:
    with open(THRESHOLDS_FILE) as f:
        thresholds.update(json.load(f))
    print("Loaded thresholds:", thresholds)
except OSError:
    pass  # first boot, no saved config yet


def apply_server_config(cfg):
    """Adopt thresholds from the telemetry ACK and persist across reboots."""
    updated = {
        "moisture_min": float(cfg["moisture_min"]),
        "moisture_max": float(cfg["moisture_max"]),
        "pump_duration_s": int(cfg["pump_duration_s"]),
    }
    if updated != thresholds:
        thresholds.update(updated)
        with open(THRESHOLDS_FILE, "w") as f:
            json.dump(thresholds, f)
        print("Thresholds updated from server:", thresholds)


# --- sensors --------------------------------------------------------------

def read_soil():
    """Average 10 ADC samples, map calibration range to 0-100%."""
    raw = sum(soil_adc.read() for _ in range(10)) // 10
    span = config.SOIL_RAW_AIR - config.SOIL_RAW_WATER
    pct = (config.SOIL_RAW_AIR - raw) * 100.0 / span
    return max(0.0, min(100.0, pct)), raw


def read_temp():
    if not temp_roms:
        return None
    try:
        temp_bus.convert_temp()
        time.sleep_ms(750)  # DS18B20 12-bit conversion time
        return temp_bus.read_temp(temp_roms[0])
    except Exception as e:
        print("Temp read failed:", e)
        return None


# --- watering -------------------------------------------------------------

last_pump_ticks = None


def maybe_water(moisture_pct):
    """Pump if soil below minimum, respecting cooldown. Returns seconds run, or 0."""
    global last_pump_ticks

    if moisture_pct >= thresholds["moisture_min"]:
        return 0
    if moisture_pct > thresholds["moisture_max"]:  # safety: never overwater
        return 0
    if last_pump_ticks is not None:
        elapsed = time.ticks_diff(time.ticks_ms(), last_pump_ticks) // 1000
        if elapsed < config.PUMP_COOLDOWN_S:
            print("Soil dry but pump in cooldown (%ds left)" % (config.PUMP_COOLDOWN_S - elapsed))
            return 0

    duration = thresholds["pump_duration_s"]
    print("Watering for %ds (moisture %.1f%% < %.1f%%)" % (duration, moisture_pct, thresholds["moisture_min"]))
    relay_on()
    time.sleep(duration)
    relay_off()
    last_pump_ticks = time.ticks_ms()
    return duration


# --- networking -----------------------------------------------------------

def wifi_ok():
    wlan = network.WLAN(network.STA_IF)
    if wlan.isconnected():
        return True
    print("Wi-Fi down, reconnecting...")
    wlan.active(True)
    wlan.connect(config.WIFI_SSID, config.WIFI_PASSWORD)
    for _ in range(20):
        if wlan.isconnected():
            print("Wi-Fi reconnected.")
            return True
        time.sleep(0.5)
    return False


def post_telemetry(payload):
    resp = None
    try:
        resp = requests.post(
            config.BACKEND_URL,
            data=json.dumps(payload),
            headers={
                "Content-Type": "application/json",
                "X-Device-Key": config.DEVICE_API_KEY,
            },
        )
        if resp.status_code == 200:
            apply_server_config(resp.json()["config"])
        else:
            print("Backend rejected telemetry: HTTP", resp.status_code, resp.text)
    except Exception as e:
        print("Telemetry POST failed:", e)
    finally:
        if resp:
            resp.close()


# --- main loop --------------------------------------------------------------

print("IoE node '%s' starting. Reporting every %ds." % (config.DEVICE_ID, config.REPORT_INTERVAL_S))

while True:
    try:
        moisture_pct, soil_raw = read_soil()
        temp_c = read_temp()
        print("Soil %.1f%% (raw %d) | Temp %s°C" % (moisture_pct, soil_raw, temp_c))

        # Local decision first — plant survives even if Wi-Fi/backend is down.
        pumped_s = maybe_water(moisture_pct)

        payload = {
            "device_id": config.DEVICE_ID,
            "soil_moisture": round(moisture_pct, 2),
            "soil_raw": soil_raw,
            "temperature_c": round(temp_c, 2) if temp_c is not None else None,
            "pump_triggered": pumped_s > 0,
            "pump_duration_s": pumped_s if pumped_s > 0 else None,
        }

        if wifi_ok():
            post_telemetry(payload)

    except Exception as e:
        # Never let one bad cycle kill the loop; the relay is forced off.
        relay_off()
        print("Cycle error:", e)

    time.sleep(config.REPORT_INTERVAL_S)
