# boot.py — runs on every reset, before main.py.
# Job: bring up Wi-Fi. main.py re-checks the connection each cycle.

import network
import time

import config


def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if wlan.isconnected():
        print("Wi-Fi already connected:", wlan.ifconfig()[0])
        return wlan

    print("Connecting to Wi-Fi '%s'..." % config.WIFI_SSID)
    wlan.connect(config.WIFI_SSID, config.WIFI_PASSWORD)

    deadline = time.time() + config.WIFI_CONNECT_TIMEOUT_S
    while not wlan.isconnected() and time.time() < deadline:
        time.sleep(0.5)

    if wlan.isconnected():
        print("Wi-Fi connected. IP:", wlan.ifconfig()[0])
    else:
        # Don't block boot forever — main.py keeps retrying and the plant
        # still gets watered offline using local thresholds.
        print("Wi-Fi connect timed out; continuing offline.")
    return wlan


wlan = connect_wifi()
