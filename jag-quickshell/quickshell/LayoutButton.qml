import QtQuick

// Current layout as a live mini-diagram. Scroll cycles layouts, click
// opens the combined layout picker + desktop tweaks panel.
BarModule {
    id: root

    onClicked: picker.visible = !picker.visible
    onScrolled: dir => Wm.cycleLayout(dir)

    LayoutIcon {
        anchors.verticalCenter: parent.verticalCenter
        layout: Wm.layout
    }

    LayoutPicker {
        id: picker
        anchorItem: root
    }
}
