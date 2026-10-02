pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property int remainingMines: 10
    property int elapsedSeconds: 0
    property bool gameWon: false
    property bool gameLost: false
    property bool isDaily: false

    signal resetRequested()

    implicitHeight: Theme.buttonHeightL
    radius: Theme.cornerRadiusMedium
    color: Theme.surfaceContainerHigh
    border.width: Theme.layerOutlineWidth
    border.color: Theme.outlineMedium

    function formatTime(totalSec) {
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        var mStr = mins < 10 ? "0" + mins : "" + mins;
        var sStr = secs < 10 ? "0" + secs : "" + secs;
        return mStr + ":" + sStr;
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingM

        // Flag / Remaining Mines Display
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "flag"
                size: Theme.iconSizeMedium
                color: Theme.primary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "" + root.remainingMines
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
            }
        }

        Item {
            // Spacer
            width: (root.width - (parent.spacing * 4) - Theme.spacingM * 2 - (centerButton.width * 3)) / 2
            height: 1
        }

        // Center Reset / Smile Button
        DankActionButton {
            id: centerButton
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.buttonHeightM
            iconSize: Theme.iconSizeLarge
            iconName: {
                if (root.gameWon) return "sentiment_very_satisfied";
                if (root.gameLost) return "sentiment_very_dissatisfied";
                return "sentiment_satisfied";
            }
            iconColor: {
                if (root.gameWon) return Theme.primary;
                if (root.gameLost) return Theme.error;
                return Theme.surfaceText;
            }
            tooltipText: I18n.trFor("duzzle", "Reset Board")
            onClicked: root.resetRequested()
        }

        Item {
            // Spacer
            width: (root.width - (parent.spacing * 4) - Theme.spacingM * 2 - (centerButton.width * 3)) / 2
            height: 1
        }

        // Timer Display
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "timer"
                size: Theme.iconSizeMedium
                color: Theme.surfaceVariantText
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.formatTime(root.elapsedSeconds)
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }
        }
    }
}
