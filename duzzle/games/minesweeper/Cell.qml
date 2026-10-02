pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property int cellSize: 38
    property int row: 0
    property int col: 0
    property bool hasMine: false
    property int neighborMines: 0
    property bool isRevealed: false
    property bool isFlagged: false
    property bool isExploded: false
    property bool isWrongFlag: false
    property bool interactive: true

    signal revealRequested()
    signal flagRequested()
    signal chordRequested()

    width: cellSize
    height: cellSize

    function getNumberColor(count) {
        switch (count) {
        case 1: return "#2563eb"; // Blue
        case 2: return "#16a34a"; // Green
        case 3: return "#dc2626"; // Red
        case 4: return "#7c3aed"; // Purple
        case 5: return "#b91c1c"; // Maroon
        case 6: return "#0891b2"; // Cyan
        case 7: return "#1e293b"; // Slate
        case 8: return "#64748b"; // Gray
        default: return Theme.surfaceText;
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: Theme.cornerRadiusSmall / 2

        color: {
            if (root.isExploded) {
                return Theme.errorContainer;
            }
            if (root.isRevealed) {
                return root.hasMine ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow;
            }
            if (mouseArea.pressed && mouseArea.containsMouse && root.interactive) {
                return Theme.surfaceContainerHighest;
            }
            if (mouseArea.containsMouse && root.interactive) {
                return Theme.surfaceContainerHigh;
            }
            return Theme.surfaceContainer;
        }

        border.width: Theme.layerOutlineWidth
        border.color: {
            if (root.isExploded) return Theme.error;
            if (root.isRevealed) return Theme.outlineLowest;
            return Theme.outlineMedium;
        }

        // Revealed Mine
        DankIcon {
            id: mineIcon
            anchors.centerIn: parent
            visible: root.isRevealed && root.hasMine
            name: "emergency"
            size: Math.round(root.cellSize * 0.58)
            color: root.isExploded ? Theme.onErrorContainer : Theme.error
        }

        // Incorrect Flag on Game Over
        DankIcon {
            id: wrongFlagIcon
            anchors.centerIn: parent
            visible: root.isWrongFlag
            name: "close"
            size: Math.round(root.cellSize * 0.62)
            color: Theme.error
        }

        // Flag (when cell is unrevealed and flagged)
        DankIcon {
            id: flagIcon
            anchors.centerIn: parent
            visible: !root.isRevealed && root.isFlagged && !root.isWrongFlag
            name: "flag"
            size: Math.round(root.cellSize * 0.58)
            color: Theme.primary
        }

        // Number (1-8) when cell is revealed without mine
        Text {
            id: numberLabel
            anchors.centerIn: parent
            visible: root.isRevealed && !root.hasMine && root.neighborMines > 0
            text: root.neighborMines > 0 ? root.neighborMines : ""
            font.family: SettingsData.monoFontFamily || "monospace"
            font.pixelSize: Math.round(root.cellSize * 0.64)
            font.weight: Font.Bold
            color: root.getNumberColor(root.neighborMines)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.flagRequested();
            } else if (mouse.button === Qt.LeftButton) {
                if (root.isRevealed) {
                    root.chordRequested();
                } else {
                    root.revealRequested();
                }
            } else if (mouse.button === Qt.MiddleButton) {
                root.chordRequested();
            }
        }

        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.isRevealed) {
                    root.chordRequested();
                }
            }
        }
    }
}
