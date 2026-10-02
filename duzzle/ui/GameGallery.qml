pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../engine/GameRegistry.js" as GameRegistry
import "."

Item {
    id: root

    property int currentStreak: 0
    property bool dailyCompleted: false

    signal gameSelected(string gameId)
    signal playDailyRequested()

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: galleryColumn.implicitHeight + Theme.spacingL * 2

        Column {
            id: galleryColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingL

            // Daily Feature Banner Card
            Rectangle {
                width: parent.width
                implicitHeight: dailyContent.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadiusLarge
                color: Theme.surfaceContainerHigh
                border.width: Theme.layerOutlineWidth
                border.color: Theme.outlineMedium

                Row {
                    id: dailyContent
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: Theme.buttonHeightL
                        height: Theme.buttonHeightL
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.cornerRadiusMedium
                        color: root.dailyCompleted ? Theme.secondaryContainer : Theme.primaryContainer

                        DankIcon {
                            anchors.centerIn: parent
                            name: root.dailyCompleted ? "check_circle" : "bolt"
                            size: Theme.iconSizeLarge
                            color: root.dailyCompleted ? Theme.onSecondaryContainer : Theme.onPrimaryContainer
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Theme.buttonHeightL - dailyBtn.width - parent.spacing * 2
                        spacing: Theme.spacingXXS

                        Row {
                            spacing: Theme.spacingS

                            Text {
                                text: I18n.trFor("duzzle", "Daily Challenge")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }

                            Text {
                                text: I18n.trFor("duzzle", "🔥 %1 streak").arg(root.currentStreak)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: Theme.primary
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.dailyCompleted
                                ? I18n.trFor("duzzle", "Today's daily challenge completed. Great job.")
                                : I18n.trFor("duzzle", "Play today's seeded puzzle to maintain your streak.")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                        }
                    }

                    DankButton {
                        id: dailyBtn
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.dailyCompleted ? I18n.trFor("duzzle", "Replay") : I18n.trFor("duzzle", "Play Now")
                        iconName: root.dailyCompleted ? "refresh" : "play_arrow"
                        backgroundColor: Theme.primary
                        textColor: Theme.primaryText
                        onClicked: root.playDailyRequested()
                    }
                }
            }

            // Section Header
            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "grid_view"
                    size: Theme.iconSizeMedium
                    color: Theme.primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.trFor("duzzle", "Puzzle Games")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }

            // Games Grid / List
            Column {
                width: parent.width
                spacing: Theme.spacingM

                Repeater {
                    model: GameRegistry.getAllGames()

                    delegate: GameCard {
                        id: gameCard
                        required property var modelData

                        gameId: gameCard.modelData.id
                        title: gameCard.modelData.name
                        description: gameCard.modelData.description
                        iconName: gameCard.modelData.icon
                        badgeText: gameCard.modelData.badge || ""
                        enabledGame: gameCard.modelData.enabled !== false

                        onSelected: root.gameSelected(gameCard.gameId)
                    }
                }
            }
        }
    }
}
