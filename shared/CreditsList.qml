import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    property alias items: repeater.model
    property bool expanded: true

    width: parent.width
    clip: true
    implicitHeight: layout.implicitHeight + (expanded ? Theme.spacingXS * 2 : 0)
    height: expanded ? implicitHeight : 0
    visible: height > 0

    opacity: expanded ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: Appearance.anim.durations.quick }
    }

    Column {
        id: layout
        width: parent.width
        spacing: Theme.spacingS
        anchors.top: parent.top
        anchors.topMargin: expanded ? Theme.spacingXS : 0

        Repeater {
            id: repeater

            delegate: Row {
                id: creditRow
                width: root.width
                spacing: Theme.spacingM

                readonly property var itemData: typeof modelData === "object" ? modelData : null
                readonly property string authorText: itemData ? (itemData.author || "") : ""
                readonly property string authorUrl: itemData ? (itemData.url || "") : ""
                readonly property string roleText: itemData ? (itemData.role || "") : String(modelData)
                readonly property string chipIcon: itemData ? (itemData.icon || "person") : "favorite"

                readonly property int authorColumnWidth: 140

                // ── Material 3 Chip / Badge Container (Fixed Column Width) ──
                Item {
                    id: chipContainer
                    visible: creditRow.authorText !== ""
                    width: creditRow.authorColumnWidth
                    height: 26
                    anchors.verticalCenter: parent.verticalCenter

                    StyledRect {
                        id: chipBadge
                        implicitWidth: Math.min(chipLayout.implicitWidth + Theme.spacingS * 2, creditRow.authorColumnWidth)
                        implicitHeight: parent.height
                        radius: height / 2

                        readonly property bool isHovered: chipHover.hovered && creditRow.authorUrl !== ""

                        color: isHovered
                            ? Theme.withAlpha(Theme.primary, 0.22)
                            : Theme.withAlpha(Theme.primaryContainer, 0.45)
                        border.width: 1
                        border.color: isHovered
                            ? Theme.primary
                            : Theme.withAlpha(Theme.outlineVariant, 0.4)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        HoverHandler {
                            id: chipHover
                            cursorShape: creditRow.authorUrl !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }

                        TapHandler {
                            enabled: creditRow.authorUrl !== ""
                            onTapped: Quickshell.execDetached(["dms", "open", creditRow.authorUrl])
                        }

                        Row {
                            id: chipLayout
                            anchors.centerIn: parent
                            spacing: 5

                            DIcon {
                                name: creditRow.chipIcon
                                size: 13
                                color: chipBadge.isHovered ? Theme.primary : Theme.onPrimaryContainer
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            StyledText {
                                text: creditRow.authorText
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.weight: Font.DemiBold
                                color: chipBadge.isHovered ? Theme.primary : Theme.onPrimaryContainer
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            DIcon {
                                visible: creditRow.authorUrl !== ""
                                name: "north_east"
                                size: 11
                                color: chipBadge.isHovered ? Theme.primary : Theme.onPrimaryContainer
                                opacity: chipBadge.isHovered ? 1.0 : 0.65
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                // ── Attribution / Description Text ───────────────────────
                StyledText {
                    width: creditRow.authorText !== ""
                        ? creditRow.width - creditRow.authorColumnWidth - parent.spacing
                        : creditRow.width
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    textFormat: Text.StyledText
                    text: creditRow.roleText
                }
            }
        }
    }
}
