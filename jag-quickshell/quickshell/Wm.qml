pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// bspwm state + control. `bspc subscribe report` streams every desktop /
// layout change (no WM patch needed — this is the interface bspwm was built
// around); the focused window title comes from a two-stage xprop spy, since
// bspc reports don't carry titles. Actions go straight through bspc.
Singleton {
    id: root

    property int seltags: 1
    property int occtags: 0
    property int urgtags: 0
    property int tagCount: 12
    property string title: ""
    property string activeWinId: ""

    // --- layout (scripts/layout engine on top of bspwm's native tiled/monocle) ---

    readonly property var layouts: ["tiled", "tall", "rtall", "wide", "rwide",
                                    "grid", "rgrid", "even", "monocle"]
    property string bspLayout: "-"      // scripts/layout get; "-" = never set
    property bool nativeMonocle: false  // report L flag fallback
    readonly property string layout: bspLayout !== "-" && bspLayout !== ""
        ? bspLayout : (nativeMonocle ? "monocle" : "tiled")

    function refreshLayout() {
        layoutGet.running = false
        layoutGet.running = true
    }

    Process {
        id: layoutGet
        command: [Theme.configDir + "/scripts/layout", "get"]
        running: true
        stdout: SplitParser {
            onRead: line => root.bspLayout = line.trim()
        }
    }

    // scripts/layout pokes this after every change it applies
    IpcHandler {
        target: "wm"
        function refreshLayout(): void { root.refreshLayout() }
    }

    // --- Awesome / EWMH workspace state ---

    function refreshTags() {
        workspaceState.running = false
        workspaceState.running = true
    }

    Process {
        id: workspaceState
        command: [Theme.configDir + "/scripts/awesome-workspaces"]

        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(/\s+/)
                if (p.length < 3)
                    return

                const current = parseInt(p[0])
                const count = parseInt(p[1])
                const occupied = parseInt(p[2])

                root.tagCount = count
                root.seltags = 1 << current
                root.occtags = occupied
                root.urgtags = 0
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshTags()
    }

    // --- focused window title ---

    Process {
        command: ["xprop", "-spy", "-root", "_NET_ACTIVE_WINDOW"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/window id # (0x[0-9a-fA-F]+)/)
                const id = m ? m[1] : ""
                if (id !== root.activeWinId) {
                    root.activeWinId = id
                    titleSpy.running = false
                    if (id !== "")
                        titleSpy.running = true
                    else
                        root.title = ""
                }
            }
        }
    }

    Process {
        id: titleSpy
        command: ["xprop", "-spy", "-id", root.activeWinId, "_NET_WM_NAME"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/= "([\s\S]*)"$/)
                if (m)
                    root.title = m[1].replace(/\\"/g, '"').replace(/\\\\/g, "\\")
            }
        }
    }

    // --- actions ---

    function viewTag(i) {
        Quickshell.execDetached([
            Theme.configDir + "/scripts/awesome-workspace-action",
            "view", String(i + 1)
        ])
    }

    function toggleViewTag(i) {
        viewTag(i)
    }

    function sendToTag(i) {
        Quickshell.execDetached([
            Theme.configDir + "/scripts/awesome-workspace-action",
            "send", String(i + 1)
        ])
    }

    function cycleTag(dir) {
        let current = 0
        for (let i = 0; i < root.tagCount; ++i) {
            if ((root.seltags & (1 << i)) !== 0) {
                current = i
                break
            }
        }

        let target = (current + dir + root.tagCount) % root.tagCount
        viewTag(target)
    }
    function setLayout(name) { Quickshell.execDetached([Theme.configDir + "/scripts/layout", "set", name]) }
    function cycleLayout(dir) { Quickshell.execDetached([Theme.configDir + "/scripts/layout", dir > 0 ? "prev" : "next"]) }

    function openLauncher() {
        Quickshell.execDetached(["rofi", "-show", "drun", "-modi", "drun",
            "-line-padding", "4", "-hide-scrollbar", "-show-icons",
            "-theme", Theme.configDir + "/rofi/config.rasi"])
    }
    function openPowerMenu() {
        Quickshell.execDetached([Theme.configDir + "/scripts/power"])
    }
}
