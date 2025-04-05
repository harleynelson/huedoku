// File: lib/providers/game_provider.dart
// Location: ./lib/providers/game_provider.dart

import 'dart:async';
import 'dart:math'; // Import for random number generation
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart'; // Needed for CellOverlay enum access if required elsewhere
import 'package:huedoku/models/sudoku_cell_data.dart';

// --- Define Difficulty Levels ---
// Used for mapping internal int values to UI and logic
// -1 represents Random
const Map<int, String> difficultyLabels = {
  -1: "Random",
  0: "Easy",
  1: "Medium",
  2: "Hard",
  3: "Expert", // Renamed from Very Hard for better UI
};


// Manages the state of the current game board and timer
class GameProvider extends ChangeNotifier {
  List<List<SudokuCellData>> _board = [];
  List<List<int?>> _solutionBoard = [];
  bool _isPuzzleLoaded = false;
  bool _isEditingCandidates = false;
  int? _selectedRow;
  int? _selectedCol;
  final Random _random = Random();

  // --- New: Store current puzzle difficulty ---
  int? _currentPuzzleDifficulty; // Stores the actual difficulty level (0-3) used for the current puzzle

  // Timer related state
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  // Game State
  bool _isPaused = false;
  bool _isCompleted = false;

  // Undo History
  final List<List<List<SudokuCellData>>> _history = [];
  final int _maxHistory = 20; // Limit undo history size

  // --- Getters ---
  List<List<SudokuCellData>> get board => _board;
  bool get isPuzzleLoaded => _isPuzzleLoaded;
  bool get isEditingCandidates => _isEditingCandidates;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  Duration get elapsedTime => _elapsedTime;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;
  bool get canUndo => _history.isNotEmpty;
  // --- New Getter ---
  int? get currentPuzzleDifficulty => _currentPuzzleDifficulty; // Getter for the current difficulty level


  // --- Game Setup ---
  // Load puzzle now accepts selected difficulty (including -1 for Random)
  void loadNewPuzzle({int difficulty = 1}) { // Default to Medium
      int actualDifficulty;

      // Handle Random selection
      if (difficulty == -1) {
          actualDifficulty = _random.nextInt(4); // Generates 0, 1, 2, or 3
      } else {
          actualDifficulty = difficulty.clamp(0, 3); // Ensure difficulty is within range 0-3
      }
      _currentPuzzleDifficulty = actualDifficulty; // Store the actual difficulty used

      if (kDebugMode) print("Loading new puzzle with actual difficulty: $actualDifficulty (${difficultyLabels[actualDifficulty]})");

      // 1. Generate a fully solved Sudoku board
      _solutionBoard = List.generate(9, (_) => List.generate(9, (_) => null));
      if (!_generateSolvedBoard(_solutionBoard)) { // Check if generation succeeded
         if (kDebugMode) print("Error: Failed to generate a solved Sudoku board.");
         _isPuzzleLoaded = false;
         _currentPuzzleDifficulty = null; // Reset difficulty if failed
         notifyListeners();
         return;
      }

      // 2. Create the playable puzzle board by removing cells based on actualDifficulty
      _board = _createPuzzleFromSolvedBoard(_solutionBoard, actualDifficulty);

      // 3. Reset game state
      _isPuzzleLoaded = true;
      _isCompleted = false;
      _isPaused = false;
      _selectedRow = null;
      _selectedCol = null;
      _isEditingCandidates = false;
      _history.clear();
      resetTimer();
      startTimer();
      notifyListeners(); // Notify that puzzle is loaded and difficulty is set
  }

  // --- Sudoku Generation Logic ---
  bool _generateSolvedBoard(List<List<int?>> board) {
    // (Implementation remains the same)
    int? row, col;
    bool foundEmpty = false;
    for (row = 0; row! < 9; row++) {
      for (col = 0; col! < 9; col++) {
        if (board[row][col] == null) {
          foundEmpty = true;
          break;
        }
      }
      if (foundEmpty) break;
    }
    if (!foundEmpty) return true;

    List<int> numbers = List.generate(9, (i) => i)..shuffle(_random);
    for (int num in numbers) {
      if (_isValidPlacement(board, row!, col!, num)) {
        board[row][col] = num;
        if (_generateSolvedBoard(board)) return true;
        board[row][col] = null; // Backtrack
      }
    }
    return false;
  }

  List<List<SudokuCellData>> _createPuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int actualDifficulty) {
      // (Implementation uses actualDifficulty passed in)
      int cellsToRemove;
      switch (actualDifficulty) {
          case 0: cellsToRemove = 30; break; // Easy
          case 1: cellsToRemove = 40; break; // Medium
          case 2: cellsToRemove = 50; break; // Hard
          case 3: cellsToRemove = 55; break; // Expert
          default: cellsToRemove = 40; // Fallback to Medium
      }
      cellsToRemove = min(cellsToRemove, 64); // Limit cells to remove
       List<List<SudokuCellData>> puzzleBoard = List.generate(
          9,
          (r) => List.generate(
              9,
              (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true)
          )
      );
      int removedCount = 0;
      List<int> cellIndices = List.generate(81, (i) => i)..shuffle(_random); // Shuffle indices for random removal
      for (int index in cellIndices) {
          if (removedCount >= cellsToRemove) break;
          int r = index ~/ 9;
          int c = index % 9;
          if (puzzleBoard[r][c].value != null) {
             // --- TODO: Add unique solvability check here if needed ---
             // This is complex, for now we just remove randomly
             puzzleBoard[r][c] = SudokuCellData(value: null, isFixed: false);
             removedCount++;
          }
      }
      // Ensure enough cells were removed (might happen with very easy boards)
      // if (removedCount < cellsToRemove) { print("Warning: Could only remove $removedCount cells."); }

      return puzzleBoard;
  }


  // --- Validation Logic ---
  bool _isValidPlacement(List<List<int?>> board, int row, int col, int num) {
      // (Implementation remains the same)
      for (int c = 0; c < 9; c++) { if (board[row][c] == num) return false; }
      for (int r = 0; r < 9; r++) { if (board[r][col] == num) return false; }
      int startRow = (row ~/ 3) * 3;
      int startCol = (col ~/ 3) * 3;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          if (board[startRow + r][startCol + c] == num) return false;
        }
      }
      return true;
  }

  void updateBoardErrors(bool showErrors) {
      // (Implementation remains the same)
      bool errorsChanged = false;
      List<List<int?>> currentBoardState = List.generate(9,
          (r) => List.generate(9, (c) => _board[r][c].value)
      );

      for (int r = 0; r < 9; r++) {
         for (int c = 0; c < 9; c++) {
            SudokuCellData cell = _board[r][c];
            int? currentValue = cell.value;
            bool oldErrorState = cell.hasError;

            if (currentValue == null || cell.isFixed) {
               cell.hasError = false;
               if(oldErrorState != cell.hasError) errorsChanged = true;
               continue;
            }

            currentBoardState[r][c] = null;
            bool isValid = _isValidPlacement(currentBoardState, r, c, currentValue);
            currentBoardState[r][c] = currentValue;

            cell.hasError = !isValid && showErrors;
             if(oldErrorState != cell.hasError) errorsChanged = true;
         }
      }
       if (errorsChanged) {
          notifyListeners();
       }
  }

   bool _isBoardCompleteAndCorrect() {
       // (Implementation remains the same)
      for (int r = 0; r < 9; r++) {
         for (int c = 0; c < 9; c++) {
             if (_board[r][c].value == null || _board[r][c].value != _solutionBoard[r][c]) return false;
             if (_board[r][c].hasError) return false; // Also check for errors
         }
      }
      return true;
  }

  // --- Cell Interaction ---
  void selectCell(int row, int col) {
      // (Implementation remains the same)
      if (_selectedRow == row && _selectedCol == col) {
         _selectedRow = null;
         _selectedCol = null;
      } else {
        _selectedRow = row;
        _selectedCol = col;
      }
      notifyListeners();
  }

  void placeValue(int colorIndex, {required bool showErrors}) {
      // (Implementation remains the same)
      if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
         final cell = _board[_selectedRow!][_selectedCol!];
         if (!cell.isFixed) {
            _saveStateToHistory();

            if (_isEditingCandidates) {
              if (cell.candidates.contains(colorIndex)) {
                cell.candidates.remove(colorIndex);
              } else {
                 cell.candidates.add(colorIndex);
              }
              if(cell.value != null) cell.value = null; // Clear value if editing candidates
            } else {
              if (cell.value == colorIndex) {
                cell.value = null; // Clear if same color tapped again
              } else {
                cell.value = colorIndex;
              }
              cell.candidates.clear(); // Clear candidates when placing value
            }

            updateBoardErrors(showErrors);

            if (_isBoardCompleteAndCorrect()) {
                _isCompleted = true;
                stopTimer();
                if (kDebugMode) print("Game Completed!");
            } else {
               _isCompleted = false; // Ensure completion flag is reset if board becomes incomplete
            }
            notifyListeners();
         }
      }
  }

  void toggleEditMode() {
      // (Implementation remains the same)
      _isEditingCandidates = !_isEditingCandidates;
      notifyListeners();
  }

  void eraseSelectedCell({required bool showErrors}) {
       // (Implementation remains the same)
       if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
           final cell = _board[_selectedRow!][_selectedCol!];
           if (!cell.isFixed) {
               if (cell.value != null || cell.candidates.isNotEmpty) {
                  _saveStateToHistory();
                  cell.value = null;
                  cell.candidates.clear();
                  updateBoardErrors(showErrors);
                  notifyListeners();
               }
           }
       }
   }

  // --- Back/Undo ---
  void _saveStateToHistory() {
      // (Implementation remains the same)
      List<List<SudokuCellData>> boardCopy = List.generate(
          9, (r) => List.generate(9, (c) => _board[r][c].clone())
      );
      _history.add(boardCopy);
      if (_history.length > _maxHistory) { _history.removeAt(0); }
      // notifyListeners(); // Not needed usually
  }

  void performUndo({required bool showErrors}) {
      // (Implementation remains the same)
      if (_history.isNotEmpty) {
         _board = _history.removeLast();
         updateBoardErrors(showErrors);

         _isCompleted = _isBoardCompleteAndCorrect(); // Recheck completion on undo
         if(_isCompleted) {
             stopTimer();
         } else if (!_isPaused && _timer == null){ // Restart timer if game was completed and now isn't
            startTimer();
         }

         notifyListeners();
      } else {
          if (kDebugMode) print("Undo history is empty.");
      }
  }

  // --- Timer Control ---
  void startTimer() {
      // (Implementation remains the same)
      if (_timer != null && _timer!.isActive) return;
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) { // Update display more often if needed
          if (!_isPaused && !_isCompleted) {
             // Only notify listeners here if UI strictly needs sub-second updates
             // Otherwise, let TimerWidget handle its own display updates
          }
      });
       // --- Sync elapsed time immediately on start ---
       // This helps if timer was stopped/reset and needs instant UI update
      notifyListeners();
  }
  void pauseTimer() {
      // (Implementation remains the same)
      _isPaused = true;
      notifyListeners(); // Notify UI about pause state
  }
  void resumeTimer() {
       // (Implementation remains the same)
       _isPaused = false;
       if (_timer == null || !_timer!.isActive) {
          startTimer(); // Restart timer if it wasn't running
       }
       notifyListeners(); // Notify UI about resume state
  }
  void stopTimer() {
      // (Implementation remains the same)
      _timer?.cancel();
      _timer = null;
       // Notify potentially, e.g., if UI shows final time on completion
       notifyListeners();
  }
  void resetTimer() {
      // (Implementation remains the same)
      stopTimer();
      _elapsedTime = Duration.zero;
      notifyListeners(); // Notify UI about reset time
  }


  // --- Game State Control ---
   void pauseGame() {
       // (Implementation remains the same)
      pauseTimer();
      // _isPaused = true; // Already set in pauseTimer
      notifyListeners();
   }
  void resumeGame() {
       // (Implementation remains the same)
      // _isPaused = false; // Already set in resumeTimer
      resumeTimer();
      notifyListeners();
   }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}