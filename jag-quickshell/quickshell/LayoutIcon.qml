import QtQuick

// Miniature diagram of a layout: up to 4 panes whose geometry morphs when
// the layout changes. Master pane is tinted, stack panes are dim; layouts
// with fewer panes collapse the extras into the last pane and fade them.
Item {
    id: root

    property string layout: "tiled"
    property color masterColor: Theme.cyan
    property color paneColor: Qt.alpha(Theme.fg, 0.38)

    // in-bar default; explicit sizes (picker tiles) override and stay fixed
    implicitWidth: Math.round(20 * Theme.barScale)
    implicitHeight: Math.round(14 * Theme.barScale)

    // normalized [x, y, w, h] per pane, master first
    readonly property var shapes: ({
        tiled:   [[0, 0, .5, 1], [.5, 0, .5, .5], [.5, .5, .3, .5], [.8, .5, .2, .5]],
        monocle: [[0, 0, 1, 1]],
        tall:    [[0, 0, .58, 1], [.58, 0, .42, .5], [.58, .5, .42, .5]],
        rtall:   [[.42, 0, .58, 1], [0, 0, .42, .5], [0, .5, .42, .5]],
        wide:    [[0, 0, 1, .58], [0, .58, .5, .42], [.5, .58, .5, .42]],
        rwide:   [[0, .42, 1, .58], [0, 0, .5, .42], [.5, 0, .5, .42]],
        grid:    [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, .5, .5], [.5, .5, .5, .5]],
        rgrid:   [[.5, .5, .5, .5], [0, .5, .5, .5], [.5, 0, .5, .5], [0, 0, .5, .5]],
        even:    [[0, 0, .25, 1], [.25, 0, .25, 1], [.5, 0, .25, 1], [.75, 0, .25, 1]]
    })

    Repeater {
        model: 4

        Rectangle {
            id: pane
            required property int index
            readonly property var panes: root.shapes[root.layout] ?? root.shapes.tiled
            readonly property var r: panes[Math.min(index, panes.length - 1)]
            readonly property real inset: 0.75

            x: r[0] * root.width + inset
            y: r[1] * root.height + inset
            width: r[2] * root.width - 2 * inset
            height: r[3] * root.height - 2 * inset
            radius: 2
            color: index === 0 ? root.masterColor : root.paneColor
            opacity: index < panes.length ? 1 : 0

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }
}
