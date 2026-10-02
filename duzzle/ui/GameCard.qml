pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string gameId: ""
    property string title: ""
    property string description: ""
    property string iconName: "extension"
    property string badgeText: ""
    property bool enabledGame: true

    signal selected()

    width: parent ? parent.width : 480
    implicitHeight: Math.max(Theme.buttonHeightL * 2, contentRow.implicitHeight + Theme.spacingM * 2)
    radius: Theme.cornerRadiusLarge
    color: {
        if (!root.enabledGame) return Theme.surfaceContainerLow;
        if (mouseArea.pressed) return Theme.surfaceContainerHighest;
        if (mouseArea.containsMouse) return Theme.surfaceContainerHigh;
        return Theme.surfaceContainer;
    }

    border.width: Theme.layerOutlineWidth
    border.color: (mouseArea.containsMouse && root.enabledGame) ? Theme.primary : Theme.outlineLowest

    opacity: root.enabledGame ? 1.0 : 0.6

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Game Icon Box
        Rectangle {
            id: iconBox
            width: Theme.buttonHeightL
            height: Theme.buttonHeightL
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.cornerRadiusMedium
            color: root.enabledGame ? Theme.primaryContainer : Theme.surfaceContainerHighest

            DankIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: Theme.iconSizeLarge
                color: root.enabledGame ? Theme.onPrimaryContainer : Theme.surfaceVariantText
            }
        }

        // Info Column
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - iconBox.width - actionIcon.width - parent.spacing * 2
            spacing: Theme.spacingXXS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                Text {
                    text: root.title
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Badge Chip
                Rectangle {
                    visible: root.badgeText !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    height: Theme.buttonHeightXXS
                    implicitWidth: badgeLabel.implicitWidth + Theme.spacingS * 2
                    radius: Theme.cornerRadiusSmall
                    color: root.enabledGame ? Theme.primary : Theme.surfaceContainerHighest

                    Text {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: root.badgeText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.weight: Font.DemiBold
                        color: root.enabledGame ? Theme.onPrimary : Theme.surfaceVariantText
                    }
                }
            }

            Text {
                width: parent.width
                text: root.description
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        // Forward Action Arrow
        DankIcon {
            id: actionIcon
            anchors.verticalCenter: parent.verticalCenter
            visible: root.enabledGame
            name: "arrow_forward"
            size: Theme.iconSizeMedium
            color: mouseArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabledGame
        hoverEnabled: true
        cursorShape: root.enabledGame ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.selected()
    }
}
