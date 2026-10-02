pragma ComponentBehavior: Bound

import "./shared"
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "engine/DailyStats.js" as DailyStats

PluginSettings {
    id: rootSettings
    pluginId: "duzzle"

    property var stats: ({
        streak: 0,
        totalPlayed: 0,
        totalWon: 0,
        gameStats: {}
    })

    function loadStats() {
        if (rootSettings.pluginService) {
            stats = DailyStats.loadStats(rootSettings.pluginService, rootSettings.pluginId);
        }
    }

    function formatDuration(sec) {
        if (!sec || sec >= 999999) return "--:--";
        var mins = Math.floor(sec / 60);
        var secs = sec % 60;
        var mStr = mins < 10 ? "0" + mins : "" + mins;
        var sStr = secs < 10 ? "0" + secs : "" + secs;
        return mStr + ":" + sStr;
    }

    Component.onCompleted: {
        loadStats();
    }

    onPluginServiceChanged: {
        loadStats();
    }

    SectionTitle {
        text: I18n.trFor("duzzle", "Statistics")
        icon: "military_tech"
    }

    SettingsCard {
        Row {
            width: parent.width
            spacing: Theme.spacingL

            // Daily Streak
            Column {
                spacing: Theme.spacingXS
                width: (parent.width - Theme.spacingL * 2) / 3

                Row {
                    spacing: Theme.spacingXS
                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "bolt"
                        size: Theme.iconSizeMedium
                        color: Theme.primary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.trFor("duzzle", "Streak")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                Text {
                    text: I18n.trFor("duzzle", "%1 days").arg(rootSettings.stats ? (rootSettings.stats.streak || 0) : 0)
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }

            // Total Played
            Column {
                spacing: Theme.spacingXS
                width: (parent.width - Theme.spacingL * 2) / 3

                Row {
                    spacing: Theme.spacingXS
                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "videogame_asset"
                        size: Theme.iconSizeMedium
                        color: Theme.secondary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.trFor("duzzle", "Played")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                Text {
                    text: "" + (rootSettings.stats ? (rootSettings.stats.totalPlayed || 0) : 0)
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }

            // Win Rate
            Column {
                spacing: Theme.spacingXS
                width: (parent.width - Theme.spacingL * 2) / 3

                Row {
                    spacing: Theme.spacingXS
                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "emoji_events"
                        size: Theme.iconSizeMedium
                        color: Theme.tertiary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.trFor("duzzle", "Won")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                Text {
                    property int won: rootSettings.stats ? (rootSettings.stats.totalWon || 0) : 0
                    property int played: rootSettings.stats ? (rootSettings.stats.totalPlayed || 0) : 0
                    text: played > 0 ? Math.round((won / played) * 100) + "%" : "0%"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }
        }
    }

    SectionTitle {
        text: I18n.trFor("duzzle", "Minesweeper Best Times")
        icon: "timer"
    }

    SettingsCard {
        Row {
            width: parent.width
            spacing: Theme.spacingL

            Column {
                spacing: Theme.spacingXS
                width: (parent.width - Theme.spacingL * 2) / 3
                Text {
                    text: I18n.trFor("duzzle", "Best Time")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Text {
                    property var g: rootSettings.stats && rootSettings.stats.gameStats ? rootSettings.stats.gameStats["minesweeper"] : null
                    text: rootSettings.formatDuration(g ? g.bestTime : 0)
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }

            Column {
                spacing: Theme.spacingXS
                width: (parent.width - Theme.spacingL * 2) / 3
                Text {
                    text: I18n.trFor("duzzle", "Games Won")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Text {
                    property var g: rootSettings.stats && rootSettings.stats.gameStats ? rootSettings.stats.gameStats["minesweeper"] : null
                    text: "" + (g ? (g.gamesWon || 0) : 0)
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }

            Column {
                spacing: Theme.spacingXS
                width: (parent.width - Theme.spacingL * 2) / 3
                DankButton {
                    text: I18n.trFor("duzzle", "Reset Stats")
                    iconName: "delete_outline"
                    backgroundColor: Theme.surfaceContainerLow
                    textColor: Theme.error
                    onClicked: {
                        if (rootSettings.pluginService) {
                            rootSettings.pluginService.savePluginData(rootSettings.pluginId, "streak", 0);
                            rootSettings.pluginService.savePluginData(rootSettings.pluginId, "lastCompletedDate", "");
                            rootSettings.pluginService.savePluginData(rootSettings.pluginId, "totalPlayed", 0);
                            rootSettings.pluginService.savePluginData(rootSettings.pluginId, "totalWon", 0);
                            rootSettings.pluginService.savePluginData(rootSettings.pluginId, "gameStats", {});
                            rootSettings.loadStats();
                        }
                    }
                }
            }
        }
    }

    SectionTitle {
        text: I18n.trFor("duzzle", "How to Play")
        icon: "help_outline"
    }

    SettingsCard {
        UsageGuide {
            items: [
                I18n.trFor("duzzle", "Left Click: Reveal a safe cell. The first click is guaranteed safe."),
                I18n.trFor("duzzle", "Right Click: Place or remove a flag on a suspected mine."),
                I18n.trFor("duzzle", "Double Click or Middle Click: Chord an uncovered number cell to instantly reveal all unflagged neighbors."),
                I18n.trFor("duzzle", "Daily Challenge: Generates the exact same daily puzzle for everyone worldwide. Win to advance your streak.")
            ]
        }
    }
}
