pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config" as QsConfig

// Current weather for `weather.city` in user.json (units: weather.units "metric" | "imperial", default metric).
// Data: open-meteo.com (no key). The city is looked up once per name, then the forecast every 30 minutes
// while something reads `summary`. Nothing is requested when no city is set.
Singleton {
    id: root

    readonly property string city: QsConfig.Config.data.weather?.city ?? ""
    readonly property bool imperial: (QsConfig.Config.data.weather?.units ?? "metric") === "imperial"

    property string summary: ""          // "18° · Partly cloudy"
    property string place: ""
    property real lat: NaN
    property real lon: NaN
    readonly property bool ok: summary !== ""

    // WMO weather codes
    function describe(c) {
        if (c === 0) return "Clear"
        if (c <= 2) return "Partly cloudy"
        if (c === 3) return "Overcast"
        if (c === 45 || c === 48) return "Fog"
        if (c >= 51 && c <= 57) return "Drizzle"
        if (c >= 61 && c <= 67) return "Rain"
        if (c >= 71 && c <= 77) return "Snow"
        if (c >= 80 && c <= 82) return "Showers"
        if (c === 85 || c === 86) return "Snow showers"
        if (c >= 95) return "Thunderstorm"
        return ""
    }

    onCityChanged: { lat = NaN; lon = NaN; summary = ""; place = ""; refresh() }

    function refresh() {
        if (city === "" || geo.running || fetch.running) return
        if (isNaN(lat)) geo.running = true
        else fetch.running = true
    }

    Timer { interval: 1800000; running: root.city !== ""; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    Process {
        id: geo
        command: ["curl", "-fsS", "--max-time", "15", "-G", "https://geocoding-api.open-meteo.com/v1/search",
                  "--data-urlencode", "name=" + root.city, "-d", "count=1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text).results?.[0]
                    if (r) { root.lat = r.latitude; root.lon = r.longitude; root.place = r.name; fetch.running = true }
                } catch (e) {}
            }
        }
    }
    Process {
        id: fetch
        command: ["curl", "-fsS", "--max-time", "15", "-G", "https://api.open-meteo.com/v1/forecast",
                  "-d", `latitude=${root.lat}&longitude=${root.lon}&current=temperature_2m,weather_code`
                        + (root.imperial ? "&temperature_unit=fahrenheit" : "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).current
                    root.summary = `${Math.round(c.temperature_2m)}°${root.imperial ? "F" : ""} · ${root.describe(c.weather_code)}`
                } catch (e) {}
            }
        }
    }
}
