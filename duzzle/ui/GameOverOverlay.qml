pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool gameWon: false
    property bool gameLost: false
    property int duration: 0
    property bool isDaily: false
    property int currentStreak: 0
    property bool dismissed: false

    signal playAgainRequested()

    visible: (gameWon || gameLost) && !dismissed
    anchors.fill: parent

    function formatTime(totalSec) {
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        if (mins > 0) {
            return mins + "m " + secs + "s";
        }
        return secs + "s";
    }

    // Dim background
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: 0.55

        MouseArea {
            anchors.fill: parent
            // Block clicks behind overlay
            preventStealing: true
        }
    }

    // Modal Card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacingXL * 2, 340)
        implicitHeight: contentColumn.height + Theme.spacingXL * 2
        radius: Theme.cornerRadiusLarge
        color: Theme.surfaceContainerHighest
        border.width: Theme.layerOutlineWidth
        border.color: root.gameWon ? Theme.primary : Theme.outlineMedium

        Column {
            id: contentColumn
            anchors.centerIn: parent
            width: parent.width - Theme.spacingL * 2
            spacing: Theme.spacingM

            // Header Icon
            Item {
                width: parent.width
                height: Theme.buttonHeightL

                DankIcon {
                    anchors.centerIn: parent
                    name: root.gameWon ? "military_tech" : "sentiment_very_dissatisfied"
                    size: Theme.iconSizeLarge * 1.5
                    color: root.gameWon ? Theme.primary : Theme.error
                }
            }

            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.gameWon ? I18n.trFor("duzzle", "Victory") : I18n.trFor("duzzle", "Game Over")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: root.gameWon ? Theme.primary : Theme.error
            }

            // Time / Subtitle
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.gameWon
                    ? I18n.trFor("duzzle", "Completed in %1").arg(root.formatTime(root.duration))
                    : I18n.trFor("duzzle", "Hit a mine. Try again.")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
            }

            // Streak indicator (for daily wins)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.gameWon && root.isDaily && root.currentStreak > 0
                spacing: Theme.spacingXS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "bolt"
                    size: Theme.iconSizeMedium
                    color: Theme.primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.trFor("duzzle", "Daily Streak: %1 days").arg(root.currentStreak)
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }
            }

            Item {
                width: 1
                height: Theme.spacingXS
            }

            // Action Buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                DankButton {
                    text: I18n.trFor("duzzle", "Review")
                    iconName: "visibility"
                    backgroundColor: Theme.surfaceContainerLow
                    textColor: Theme.surfaceText
                    onClicked: root.dismissed = true
                }

                DankButton {
                    text: root.isDaily ? I18n.trFor("duzzle", "Replay") : I18n.trFor("duzzle", "Play Again")
                    iconName: "refresh"
                    backgroundColor: Theme.primary
                    textColor: Theme.primaryText
                    onClicked: {
                        root.dismissed = false;
                        root.playAgainRequested();
                    }
                }
            }
        }
    }
}
