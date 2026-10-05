import QtQuick
import Quickshell
import Quickshell.Io

// FreeBSD OSS volume control using mixer.
BarModule {
    id: root

    property bool muted: false
    property int volume: 0
    property bool flash: false

    Process {
        id: volumeProc
        command: ["mixer", "vol"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")

                for (const line of lines) {
                    if (line.startsWith("vol.volume=")) {
                        const value = line.split("=")[1].split(":")[0]
                        root.volume = Math.round(parseFloat(value) * 100)
                    } else if (line.startsWith("vol.mute=")) {
                        root.muted = line.split("=")[1].trim() === "on"
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volumeProc.running = true
    }

    Timer {
        id: flashTimer
        interval: 2000
        onTriggered: root.flash = false
    }

    function refresh() {
        flash = true
        flashTimer.restart()
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: volumeProc.running = true
    }

    icon: muted ? "󰝟" : volume < 25 ? "󰕿" : volume < 65 ? "󰖀" : "󰕾"
    iconColor: muted ? Qt.alpha(Theme.fg, 0.45) : Theme.green
    label: hovered || flash ? (muted ? "--" : volume + "%") : ""

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            // No pavucontrol needed with native FreeBSD OSS.
        } else {
            Quickshell.execDetached([
                "mixer", "vol.mute=" + (muted ? "off" : "on")
            ])
            refresh()
        }
    }

    onScrolled: dir => {
        const next = Math.max(0, Math.min(100, volume + dir * 5))

        if (muted)
            Quickshell.execDetached(["mixer", "vol.mute=off"])

        Quickshell.execDetached([
            "mixer", "vol.volume=" + (next / 100).toFixed(2)
        ])

        refresh()
    }
}
