import QtQuick
import Quickshell

// The bar window, effectiveBarHeight px tall. bspwm ignores dock struts:
// each Bar syncs monitor top_padding to reserve its space — that sync is
// what re-tiles windows live when the sliders resize the bar.
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.effectiveBarHeight
    color: "transparent"
    // map once, at final size — see Theme.barStateReady
    visible: Theme.barStateReady

    readonly property int reserved: Theme.effectiveBarHeight
    onReservedChanged: syncPadding()
    Component.onCompleted: syncPadding()
    function syncPadding() {
        Quickshell.execDetached(["bspc", "config", "-m", screen.name,
                                 "top_padding", String(reserved)])
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 2

        radius: 10
        color: Qt.alpha(Theme.bg, 0.94)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.35)

        Behavior on color { ColorAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 400 } }

        Row {
            id: leftCluster
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Launcher {}
            Tags {}
            LayoutButton {}
        }

        Item {
            id: centerLane

            anchors.left: leftCluster.right
            anchors.right: rightCluster.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            anchors.leftMargin: 20
            anchors.rightMargin: 20

            clip: true

            Title {
                anchors.centerIn: parent
                width: Math.min(implicitWidth, centerLane.width)
            }
        }

        Row {
            id: rightCluster
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Media {}
            Weather {}
            Metrics {}
            Volume {}
            Network {}
            Tray {}
            Bell {}
            Clock {}
            CapsLock {}
            Screenshot {}
            PowerButton {}
        }
    }
}
