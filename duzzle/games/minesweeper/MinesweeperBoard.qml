pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "MinesweeperEngine.js" as Engine
import "../../engine/SeedRandom.js" as SeedRandom

Item {
    id: root

    property var gameConfig: ({
        rows: 9,
        cols: 9,
        mines: 10,
        seed: null,
        isDaily: false
    })

    property bool gameActive: false
    property bool gameWon: false
    property bool gameLost: false
    property bool firstClickMade: false
    property int flagCount: 0
    property int remainingMines: Math.max(0, (gameConfig ? gameConfig.mines : 10) - flagCount)
    property int elapsedSeconds: 0

    property var rawBoard: []

    signal gameStarted()
    signal gameOver(bool won, int duration)
    signal boardReset()

    readonly property int boardRows: gameConfig ? gameConfig.rows : 9
    readonly property int boardCols: gameConfig ? gameConfig.cols : 9
    readonly property int totalMines: gameConfig ? gameConfig.mines : 10
    readonly property int totalCells: boardRows * boardCols

    readonly property int cellSpacing: 2
    readonly property int calculatedCellSize: {
        var maxW = flickable.width - (boardCols - 1) * cellSpacing - Theme.spacingM * 2;
        var maxH = flickable.height - (boardRows - 1) * cellSpacing - Theme.spacingM * 2;
        var fitW = Math.floor(maxW / Math.max(1, boardCols));
        var fitH = Math.floor(maxH / Math.max(1, boardRows));
        return Math.min(46, Math.max(26, Math.min(fitW, fitH)));
    }

    Timer {
        id: gameTimer
        interval: 1000
        repeat: true
        running: root.gameActive && !root.gameWon && !root.gameLost
        onTriggered: root.elapsedSeconds++
    }

    function initGame() {
        gameTimer.stop();
        root.gameActive = false;
        root.gameWon = false;
        root.gameLost = false;
        root.firstClickMade = false;
        root.elapsedSeconds = 0;
        root.flagCount = 0;

        root.rawBoard = Engine.createEmptyBoard(root.boardRows, root.boardCols);

        var total = root.boardRows * root.boardCols;
        for (var i = 0; i < total; i++) {
            var item = cellsRepeater.itemAt(i);
            if (item) {
                item.hasMine = false;
                item.neighborMines = 0;
                item.isRevealed = false;
                item.isFlagged = false;
                item.isExploded = false;
                item.isWrongFlag = false;
            }
        }
        root.boardReset();
    }

    function handleFirstClick(r, c) {
        var rng;
        if (root.gameConfig && root.gameConfig.seed) {
            rng = SeedRandom.createRng(root.gameConfig.seed);
        } else {
            rng = SeedRandom.createRng(null);
        }

        Engine.populateMines(root.rawBoard, root.boardRows, root.boardCols, root.totalMines, r, c, rng);
        root.firstClickMade = true;
        root.gameActive = true;
        root.gameStarted();
    }

    function syncChanged(changedIndices) {
        for (var i = 0; i < changedIndices.length; i++) {
            var idx = changedIndices[i];
            var raw = root.rawBoard[idx];
            var item = cellsRepeater.itemAt(idx);
            if (item) {
                item.hasMine = raw.hasMine;
                item.neighborMines = raw.neighborMines;
                item.isRevealed = raw.isRevealed;
                item.isFlagged = raw.isFlagged;
                item.isExploded = raw.isExploded;
                item.isWrongFlag = raw.isWrongFlag;
            }
        }
    }

    function handleReveal(r, c) {
        if (root.gameWon || root.gameLost) return;

        if (!root.firstClickMade) {
            handleFirstClick(r, c);
        }

        var res = Engine.revealCell(root.rawBoard, root.boardRows, root.boardCols, r, c);
        syncChanged(res.changedIndices);
        root.flagCount = Engine.countFlags(root.rawBoard, root.boardRows, root.boardCols);

        if (res.hitMine) {
            root.gameLost = true;
            root.gameActive = false;
            root.gameOver(false, root.elapsedSeconds);
        } else if (res.won) {
            root.gameWon = true;
            root.gameActive = false;
            root.gameOver(true, root.elapsedSeconds);
        }
    }

    function handleToggleFlag(r, c) {
        if (root.gameWon || root.gameLost) return;
        var changed = Engine.toggleFlag(root.rawBoard, root.boardRows, root.boardCols, r, c);
        if (changed) {
            var idx = r * root.boardCols + c;
            var raw = root.rawBoard[idx];
            var item = cellsRepeater.itemAt(idx);
            if (item) {
                item.isFlagged = raw.isFlagged;
            }
            root.flagCount = Engine.countFlags(root.rawBoard, root.boardRows, root.boardCols);
        }
    }

    function handleChord(r, c) {
        if (root.gameWon || root.gameLost || !root.firstClickMade) return;
        var res = Engine.chordCell(root.rawBoard, root.boardRows, root.boardCols, r, c);
        if (!res) return;

        syncChanged(res.changedIndices);
        root.flagCount = Engine.countFlags(root.rawBoard, root.boardRows, root.boardCols);

        if (res.hitMine) {
            root.gameLost = true;
            root.gameActive = false;
            root.gameOver(false, root.elapsedSeconds);
        } else if (res.won) {
            root.gameWon = true;
            root.gameActive = false;
            root.gameOver(true, root.elapsedSeconds);
        }
    }

    onGameConfigChanged: {
        initGame();
    }

    Component.onCompleted: {
        initGame();
    }

    DankFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: Math.max(width, boardGrid.width + Theme.spacingM * 2)
        contentHeight: Math.max(height, boardGrid.height + Theme.spacingM * 2)

        Item {
            width: flickable.contentWidth
            height: flickable.contentHeight

            Grid {
                id: boardGrid
                anchors.centerIn: parent
                columns: root.boardCols
                rows: root.boardRows
                spacing: root.cellSpacing

                Repeater {
                    id: cellsRepeater
                    model: root.totalCells

                    delegate: Cell {
                        id: cellDelegate
                        required property int index

                        cellSize: root.calculatedCellSize
                        row: Math.floor(cellDelegate.index / root.boardCols)
                        col: cellDelegate.index % root.boardCols
                        interactive: !root.gameWon && !root.gameLost

                        onRevealRequested: root.handleReveal(cellDelegate.row, cellDelegate.col)
                        onFlagRequested: root.handleToggleFlag(cellDelegate.row, cellDelegate.col)
                        onChordRequested: root.handleChord(cellDelegate.row, cellDelegate.col)
                    }
                }
            }
        }
    }
}
