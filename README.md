# Rainboku 🌈

A colorful twist on the classic Sudoku game built in Flutter, but with colors instead of numbers.

## Features

* Classic 9x9 Sudoku logic with colors.
* Multiple difficulty levels (Easy, Medium, Hard, Painful, and Random).
* Selectable color palettes (Classic, Retro, Forest, Ocean, Pastel, etc.).
* Optional cell overlays: Show numbers (1-9) or unique patterns instead of just colors.
* Gameplay assistance:
    * Highlight peer cells (row, column, box).
    * Instant error checking.
    * Candidate/"pencil mark" mode.
    * Hint system (tracks number of hints used).
    * Undo functionality.
    * Optional gameplay timer.
    * Optionally dim completed colors or colors used in the current selection context.
* Background animations (Bokeh effect) and themes (Light/Dark).
* **Puzzle Sharing:** Share the exact puzzle you played with friends using a unique code!
* Import shared puzzle codes to challenge friends' scores.

## Getting Started

This is a Flutter project.

1.  Ensure you have the Flutter SDK installed.
2.  Clone the repository (or ensure you have the project files).
3.  Navigate to the project directory: `cd path/to/rainboku`
4.  Install dependencies: `flutter pub get`
5.  Run the app: `flutter run`

## Project Structure (lib folder)

The `lib` folder contains the core source code:

* `main.dart`: App entry point, sets up providers and theme.
* `constants.dart`: Defines game constants like grid size, timings, padding, etc.
* `themes.dart`: Defines light and dark themes, including custom gradients.
* **`models/`**: Contains data structures:
    * `color_palette.dart`: Defines available color palettes and cell overlay options.
    * `sudoku_cell_data.dart`: Represents the state of a single cell (value, fixed status, candidates, errors, hints).
* **`providers/`**: Manages application state using Provider:
    * `game_provider.dart`: Handles game logic, board state, timer, hints, puzzle generation, and puzzle code import/export.
    * `settings_provider.dart`: Manages user preferences like theme, palette, and gameplay options.
* **`screens/`**: Contains the main UI screens:
    * `home_screen.dart`: Starting screen with difficulty selection and puzzle import.
    * `game_screen.dart`: Main gameplay screen displaying the grid, controls, and palette.
    * `settings_screen.dart`: Screen for configuring app settings (uses `settings_content.dart`).
* **`widgets/`**: Contains reusable UI components:
    * `sudoku_grid_widget.dart`: Renders the main 9x9 grid structure.
    * `sudoku_cell_widget.dart`: Renders a single cell within the grid.
    * `palette_selector_widget.dart`: Displays the color selection palette.
    * `game_controls.dart`: Displays buttons for undo, edit mode, erase, hint, overlay toggle.
    * `settings_content.dart`: Reusable widget containing the settings options.
    * `timer_widget.dart`: Displays the gameplay timer.
    * `bokeh_painter.dart`: Custom painter for the animated background effect.
    * `pattern_painter.dart`: Custom painter for rendering cell patterns.

## Puzzle Sharing Code Format

You can share puzzles with friends using a generated code. This code represents the **initial state** of the puzzle, allowing others to play the same challenge.

**Format:** `D:BOARD_STRING`

* **`D`**: A single character representing the difficulty:
    * `E`: Easy
    * `M`: Medium
    * `H`: Hard
    * `P`: Painful (Expert)
    * `R`: Random (The actual difficulty is determined when the puzzle is generated, but the code might reflect 'R' if that was the initial selection).
* **`:`**: A colon separator.
* **`BOARD_STRING`**: An 81-character string representing the 9x9 grid, read row by row.
    * `1` through `9`: Represents a cell that was **fixed** (part of the initial puzzle) with the corresponding color index (0-8) plus 1.
        * `1` = Color Index 0
        * `2` = Color Index 1
        * ...
        * `9` = Color Index 8
    * `0`: Represents a cell that was **initially empty**.

**Example:** `M:003050100...`

* `M`: Medium difficulty.
* The first `0` means the top-left cell (row 0, col 0) was empty.
* The `3` means the cell at row 0, col 2 was fixed with color index 2.
* The `5` means the cell at row 0, col 4 was fixed with color index 4.
* ...and so on for all 81 cells.

**How it's Generated:**
This code is created within the `GameProvider` right after a new puzzle is generated. It iterates through the initial board state and encodes each cell based on whether it's fixed or empty.

## Future Enhancements

* Save/Load game state.
* Some statistics tracking.
* Customizable palettes.
* Sound effects.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.
