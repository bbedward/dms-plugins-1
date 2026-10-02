pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "../engine/SeedRandom.js" as SeedRandom
import "../engine/DailyStats.js" as DailyStats
import "../engine/GameRegistry.js" as GameRegistry
import "../games/minesweeper"
import "../shared"
import "."

DankFloatingWindow {
    id: root

    property var pluginService: null
    property string pluginId: "duzzle"

    property string currentView: "gallery" // "gallery" or "game"
    property string activeGameId: "minesweeper"
    property bool isDailyMode: true
    property string activeDifficulty: "beginner"
    property int currentStreak: 0
    property bool dailyCompleted: false

    readonly property string windowTitle: {
        if (root.currentView === "gallery") {
            return I18n.trFor("duzzle", "Duzzle");
        }
        var g = GameRegistry.getGame(root.activeGameId);
        var gName = g ? g.name : "";
        return gName ? "Duzzle - " + gName : I18n.trFor("duzzle", "Duzzle");
    }

    objectName: "duzzleWindow"
    title: root.windowTitle

    minimumSize: Qt.size(480, 580)
    implicitWidth: 560
    implicitHeight: 680
    visible: false

    function toggle() {
        visible = !visible;
        if (visible) {
            refreshDailyState();
            contentFocusScope.forceActiveFocus();
        }
    }

    function show() {
        visible = true;
        refreshDailyState();
        contentFocusScope.forceActiveFocus();
    }

    function hide() {
        visible = false;
    }

    onClosed: hide()

    function refreshDailyState() {
        if (!root.pluginService) return;
        var stats = DailyStats.loadStats(root.pluginService, root.pluginId);
        root.currentStreak = stats.streak || 0;
        var today = SeedRandom.getDailySeedString();
        root.dailyCompleted = (stats.lastCompletedDate === today);
    }

    function getActiveConfig() {
        var diff = GameRegistry.getDifficulty(root.activeGameId, root.activeDifficulty);
        var seed = null;
        if (root.isDailyMode) {
            seed = SeedRandom.getDailySeedString();
        }
        return {
            rows: diff ? diff.rows : 9,
            cols: diff ? diff.cols : 9,
            mines: diff ? diff.mines : 10,
            seed: seed,
            isDaily: root.isDailyMode
        };
    }

    FocusScope {
        id: contentFocusScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: event => {
            if (root.currentView === "game") {
                root.currentView = "gallery";
                event.accepted = true;
            } else {
                root.hide();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            DankWindowHeader {
                id: titleBar
                Layout.fillWidth: true
                z: 10
                controls: windowControls
                title: root.windowTitle
                onCloseRequested: root.hide()
            }

            // View 1: Game Gallery (Hub)
            GameGallery {
                id: gameGallery
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentView === "gallery"
                currentStreak: root.currentStreak
                dailyCompleted: root.dailyCompleted

                onGameSelected: gameId => {
                    root.activeGameId = gameId;
                    root.isDailyMode = false;
                    root.currentView = "game";
                    board.initGame();
                }

                onPlayDailyRequested: {
                    root.activeGameId = "minesweeper";
                    root.isDailyMode = true;
                    root.currentView = "game";
                    board.initGame();
                }
            }

            // View 2: Active Puzzle Game
            ColumnLayout {
                id: gameViewContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentView === "game"
                spacing: 0

                // Game Top Toolbar (Back button + Daily/Free Play tabs)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
                    Layout.leftMargin: Theme.spacingM
                    Layout.rightMargin: Theme.spacingM
                    spacing: Theme.spacingM

                    DankButton {
                        text: I18n.trFor("duzzle", "Gallery")
                        iconName: "arrow_back"
                        backgroundColor: Theme.surfaceContainer
                        textColor: Theme.surfaceText
                        onClicked: root.currentView = "gallery"
                    }

                    DankTabBar {
                        id: modeTabBar
                        Layout.fillWidth: true
                        currentIndex: root.isDailyMode ? 0 : 1
                        model: [
                            {
                                text: I18n.trFor("duzzle", "Daily Challenge"),
                                icon: "event"
                            },
                            {
                                text: I18n.trFor("duzzle", "Free Play"),
                                icon: "casino"
                            }
                        ]
                        onTabClicked: index => {
                            var newDaily = (index === 0);
                            if (root.isDailyMode !== newDaily) {
                                root.isDailyMode = newDaily;
                                board.initGame();
                            }
                        }
                    }
                }

                // Sub-toolbar for Free Play difficulties
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
                    Layout.leftMargin: Theme.spacingM
                    Layout.rightMargin: Theme.spacingM
                    visible: !root.isDailyMode
                    spacing: Theme.spacingS

                    Repeater {
                        model: GameRegistry.getDifficulties(root.activeGameId)

                        delegate: DankButton {
                            id: diffBtn
                            required property var modelData
                            text: diffBtn.modelData.name
                            backgroundColor: root.activeDifficulty === diffBtn.modelData.id ? Theme.primary : Theme.surfaceContainer
                            textColor: root.activeDifficulty === diffBtn.modelData.id ? Theme.primaryText : Theme.surfaceText
                            onClicked: {
                                if (root.activeDifficulty !== diffBtn.modelData.id) {
                                    root.activeDifficulty = diffBtn.modelData.id;
                                    board.initGame();
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Game Board Area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: Theme.spacingM
                    Layout.rightMargin: Theme.spacingM
                    Layout.bottomMargin: Theme.spacingM
                    Layout.topMargin: Theme.spacingL

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.spacingL

                        GameHeader {
                            id: gameHeader
                            Layout.fillWidth: true
                            remainingMines: board.remainingMines
                            elapsedSeconds: board.elapsedSeconds
                            gameWon: board.gameWon
                            gameLost: board.gameLost
                            isDaily: root.isDailyMode
                            onResetRequested: board.initGame()
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            MinesweeperBoard {
                                id: board
                                anchors.fill: parent
                                gameConfig: root.getActiveConfig()

                                onGameOver: (won, duration) => {
                                    if (root.pluginService) {
                                        var dateStr = SeedRandom.getDailySeedString();
                                        var resStats = DailyStats.recordGameResult(
                                            root.pluginService,
                                            root.pluginId,
                                            root.activeGameId,
                                            root.isDailyMode,
                                            dateStr,
                                            won,
                                            duration
                                        );
                                        root.currentStreak = resStats.streak || 0;
                                        root.dailyCompleted = (resStats.lastCompletedDate === dateStr);
                                    }
                                }
                            }

                            GameOverOverlay {
                                id: gameOverOverlay
                                gameWon: board.gameWon
                                gameLost: board.gameLost
                                duration: board.elapsedSeconds
                                isDaily: root.isDailyMode
                                currentStreak: root.currentStreak
                                onPlayAgainRequested: board.initGame()
                            }
                        }
                    }
                }
            }
        }
    }

    FloatingWindowControls {
        id: windowControls
        targetWindow: root
    }
}
