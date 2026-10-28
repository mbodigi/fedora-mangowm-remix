pragma Singleton
// Weather from wttr.in (location from IP, Celsius): current conditions + 3-day forecast, refreshed every 30 minutes.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string temp: ""
    property string feelsLike: ""
    property string condition: ""
    property string location: ""
    property int code: 0
    property var days: []   // [{date, max, min, code}]

    function refresh() { fetch.running = true; }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=j1&m"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const now = d.current_condition[0];
                    root.temp = now.temp_C + "°";
                    root.feelsLike = now.FeelsLikeC + "°";
                    root.condition = now.weatherDesc[0].value;
                    root.code = Number(now.weatherCode);
                    const area = d.nearest_area?.[0];
                    root.location = area ? area.areaName[0].value : "";
                    root.days = d.weather.map(w => ({
                        date: w.date,
                        max: w.maxtempC + "°",
                        min: w.mintempC + "°",
                        code: Number(w.hourly[4]?.weatherCode ?? 113)
                    }));
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetch.running = true
    }

    // Material Symbols name for a wttr.in weather code
    function icon(c, allowNight) {
        const h = new Date().getHours();
        const night = allowNight && (h < 6 || h >= 19);
        if (c === 113) return night ? "clear_night" : "clear_day";
        if (c === 116) return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if (c === 119 || c === 122) return "cloud";
        if ([143, 248, 260].includes(c)) return "foggy";
        if ([200, 386, 389, 392, 395].includes(c)) return "thunderstorm";
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(c)) return "weather_snowy";
        return "rainy";
    }
}
