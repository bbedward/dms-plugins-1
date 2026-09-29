import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string iconName: ""
    property string label: ""
    property string shortcut: ""
    property color activeColor: Theme.primary
    property bool disabled: false

    signal clicked()

    radius: Theme.cornerRadius
    width: parent.width
    height: 52

    color: root.disabled ? Theme.withAlpha(Theme.surfaceVariant, 0.04) : (mouseArea.containsMouse ? Theme.withAlpha(activeColor, 0.12) : Theme.withAlpha(Theme.surfaceVariant, 0.08))
    border.color: root.disabled ? "transparent" : (mouseArea.containsMouse ? activeColor : "transparent")
    border.width: 1
    opacity: root.disabled ? 0.4 : 1.0

    DankIcon {
        name: root.iconName
        size: Theme.iconSize
        color: Theme.surfaceText
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
        text: root.label
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingL * 2 + Theme.iconSize
        anchors.right: shortcutKeycap.visible ? shortcutKeycap.left : parent.right
        anchors.rightMargin: Theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
    }

    DankKeycap {
        id: shortcutKeycap
        visible: root.shortcut !== ""
        text: root.shortcut
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !root.disabled
        enabled: !root.disabled
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}