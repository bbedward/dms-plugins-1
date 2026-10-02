# Duzzle (Daily Puzzle)

Daily puzzle challenge and minigames for DankMaterialShell (DMS).

## Features

- **Daily Challenge** - Deterministic daily seed generated per date (`YYYY-MM-DD`). Everyone worldwide plays the exact same puzzle each day.
- **Minesweeper Engine** - Classic puzzle mechanics with modern Material You styling:
  - First-click safety guarantee (never lose on move 1).
  - Contiguous 0-flood reveal.
  - Chording (double click or middle click on revealed numbers).
  - Flag counter, live timer, and smiley status reset button.
- **Streak Tracking & Stats** - Persistent daily streak counter, win rate, total games played, and best completion times.
- **Free Play Mode** - Unlimited replay with selectable difficulty levels:
  - Beginner (9x9, 10 mines)
  - Intermediate (16x16, 40 mines)
  - Expert (16x30, 99 mines)
- **Extensible Architecture** - Modular registry design allowing easy addition of future puzzle types (Sudoku, 2048, Wordle, etc.).
- **Control Center Surface** - Integrated into DMS Control Center; opens as a native floating window with drag and edge resize controls.

## Controls

| Action | Function |
|---|---|
| Left Click | Reveal cell |
| Right Click | Place / remove flag |
| Double Click / Middle Click | Chord cell (reveal all unflagged neighbors when flags match number) |
| Smiley Face | Reset game |

## Install

Clone into your DMS plugins directory:
```bash
git clone https://github.com/hthienloc/dms-duzzle ~/.config/DankMaterialShell/plugins/duzzle
```

Or enable from local repository:
```bash
ln -s "$(pwd)/duzzle" ~/.config/DankMaterialShell/plugins/duzzle
dms ipc call plugins reload duzzle
```
