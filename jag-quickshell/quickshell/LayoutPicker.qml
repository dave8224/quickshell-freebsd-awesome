import QtQuick
import Quickshell
import Quickshell.Io

// Layout + desktop-tweaks popup anchored under the layout button.
// Top: the nine layouts as mini-diagram tiles (click applies, panel
// stays open for experimenting). Bottom: live bspwm tweaks — sliders apply
// instantly through bspc while dragging; releasing persists the value into
// bspwmrc so it survives restarts.
Popout {
    id: root

    cardWidth: 340
    cardHeight: col.implicitHeight + 2 * cardPadding

    // current bspwm settings, re-read on every open
    property int gap: 8
    property int borderW: 4
    property real split: 0.5

    onVisibleChanged: if (visible) cfgRead.running = true

    // scriptable open/close: qs -p ~/.config/jag-quickshell/quickshell ipc call tweaks toggle
    IpcHandler {
        target: "tweaks"
        function toggle(): void { root.visible = !root.visible }
    }

    Process {
        id: cfgRead
        command: ["sh", "-c",
            "for k in window_gap border_width split_ratio; do " +
            "printf '%s=%s\\n' \"$k\" \"$(bspc config $k)\"; done"]
        stdout: SplitParser {
            onRead: line => {
                const i = line.indexOf("=")
                const k = line.slice(0, i), v = line.slice(i + 1).trim()
                if (k === "window_gap") root.gap = parseInt(v)
                else if (k === "border_width") root.borderW = parseInt(v)
                else if (k === "split_ratio") root.split = parseFloat(v)
            }
        }
    }

    function applyCfg(key, val) {
        Quickshell.execDetached(["bspc", "config", key, String(val)])
    }
    // rewrite the matching bspwmrc line, preserving its whitespace
    function persistCfg(key, val) {
        Quickshell.execDetached(["sed", "-i",
            "s/^\\(bspc config " + key + "[[:space:]]*\\).*/\\1" + val + "/",
            Theme.configDir + "/bspwmrc"])
    }

    // --- inline components ---

    component SectionLabel: Text {
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
        topPadding: 6
    }

    // --- panel --- (chrome comes from Popout; sliders are the shared TweakSlider)

    Item {
        anchors.fill: parent

        Column {
            id: col
            anchors.fill: parent
            spacing: 6

            SectionLabel { text: "Layout" }

            Grid {
                id: layoutGrid
                width: parent.width
                columns: 3
                spacing: 4

                Repeater {
                    model: Wm.layouts

                    Rectangle {
                        id: tile
                        required property string modelData
                        readonly property bool current: Wm.layout === modelData

                        width: (layoutGrid.width - 8) / 3
                        height: 52
                        radius: 8
                        color: current ? Theme.selbg
                             : tileMa.containsMouse ? Qt.alpha(Theme.fg, 0.12)
                             : Qt.alpha(Theme.fg, 0.04)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            LayoutIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 26
                                height: 17
                                layout: tile.modelData
                                masterColor: tile.current ? Theme.selfg : Theme.cyan
                                paneColor: tile.current ? Qt.alpha(Theme.selfg, 0.55)
                                                        : Qt.alpha(Theme.fg, 0.38)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData
                                color: tile.current ? Theme.selfg : Qt.alpha(Theme.fg, 0.8)
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: tile.current
                            }
                        }

                        MouseArea {
                            id: tileMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Wm.setLayout(tile.modelData)
                        }
                    }
                }
            }

            SectionLabel { text: "Desktop" }

            TweakSlider {
                label: "window gap"
                from: 0; to: 40
                value: root.gap
                suffix: " px"
                applyFn: v => root.applyCfg("window_gap", v)
                persistFn: v => root.persistCfg("window_gap", v)
                onCommitted: v => root.gap = v
            }
            TweakSlider {
                label: "border width"
                from: 0; to: 12
                value: root.borderW
                suffix: " px"
                applyFn: v => root.applyCfg("border_width", v)
                persistFn: v => root.persistCfg("border_width", v)
                onCommitted: v => root.borderW = v
            }
            TweakSlider {
                label: "bar height"
                from: 36; to: 72
                value: Theme.barHeight
                suffix: " px"
                applyFn: v => Theme.barHeight = v
                persistFn: v => Quickshell.execDetached(["sh", "-c",
                    "printf '%s\\n' " + v + " > '" + Theme.configDir + "/bar-height'"])
            }
            TweakSlider {
                label: "element scale"
                from: 0.7; to: 2.0
                value: Theme.barUserScale
                isInt: false
                suffix: "×"
                applyFn: v => Theme.barUserScale = v
                persistFn: v => Quickshell.execDetached(["sh", "-c",
                    "printf '%s\\n' " + v + " > '" + Theme.configDir + "/bar-scale'"])
            }
            TweakSlider {
                label: "split ratio (new splits)"
                from: 0.3; to: 0.7
                value: root.split
                isInt: false
                applyFn: v => root.applyCfg("split_ratio", v)
                persistFn: v => root.persistCfg("split_ratio", v)
                onCommitted: v => root.split = v
            }
        }
    }
}
