.pragma library

var GAMES = [
    {
        id: "minesweeper",
        name: "Minesweeper",
        icon: "grid_view",
        description: "Flag hidden mines and clear the grid without detonating them.",
        badge: "Daily Ready",
        enabled: true,
        component: "../games/minesweeper/MinesweeperBoard.qml",
        difficulties: [
            { id: "beginner", name: "Beginner", rows: 9, cols: 9, mines: 10 },
            { id: "intermediate", name: "Intermediate", rows: 16, cols: 16, mines: 40 },
            { id: "expert", name: "Expert", rows: 16, cols: 30, mines: 99 }
        ]
    },
    {
        id: "2048",
        name: "2048",
        icon: "filter_9_plus",
        description: "Slide numbered tiles on a grid to combine them and reach 2048.",
        badge: "Coming Soon",
        enabled: false,
        difficulties: []
    },
    {
        id: "sudoku",
        name: "Sudoku",
        icon: "apps",
        description: "Fill the 9x9 grid with digits so each column, row, and section contains 1-9.",
        badge: "Coming Soon",
        enabled: false,
        difficulties: []
    },
    {
        id: "wordle",
        name: "Wordle",
        icon: "spellcheck",
        description: "Guess the hidden 5-letter word in six tries with colored clue tiles.",
        badge: "Coming Soon",
        enabled: false,
        difficulties: []
    }
];

function getAllGames() {
    return GAMES;
}

function getGame(id) {
    for (var i = 0; i < GAMES.length; i++) {
        if (GAMES[i].id === id) {
            return GAMES[i];
        }
    }
    return GAMES[0];
}

function getDifficulties(gameId) {
    var game = getGame(gameId);
    return (game && game.difficulties) ? game.difficulties : [];
}

function getDifficulty(gameId, diffId) {
    var diffs = getDifficulties(gameId);
    for (var i = 0; i < diffs.length; i++) {
        if (diffs[i].id === diffId) {
            return diffs[i];
        }
    }
    return diffs.length > 0 ? diffs[0] : null;
}
