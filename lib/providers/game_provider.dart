// File: lib/providers/game_provider.dart
// Location: ./lib/providers/game_provider.dart

import 'dart:async';
import 'dart:math'; // Import for random number generation
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
// No longer need to import ColorPalette here unless for type hinting in loadNewPuzzle
// import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';

// Manages the state of the current game board and timer
class GameProvider extends ChangeNotifier {
  List<List<SudokuCellData>> _board = [];
  List<List<int?>> _solutionBoard = []; // Store the solved board for validation
  // --- Removed: No longer store palette directly in GameProvider ---
  // ColorPalette _currentPalette = ColorPalette.classic;
  bool _isPuzzleLoaded = false;
  bool _isEditingCandidates = false; // Are we placing main colors or candidates?
  int? _selectedRow;
  int? _selectedCol;
  final Random _random = Random();

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
  // --- Removed: Palette getter ---
  // ColorPalette get currentPalette => _currentPalette;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;
  bool get canUndo => _history.isNotEmpty;

  // --- Game Setup ---
  // Load puzzle now only needs difficulty, palette comes from SettingsProvider at render time
  void loadNewPuzzle({int difficulty = 1}) {
    // 1. Generate a fully solved Sudoku board (indices 0-8)
    _solutionBoard = List.generate(9, (_) => List.generate(9, (_) => null));
    _generateSolvedBoard(_solutionBoard);

    if (_solutionBoard.any((row) => row.any((cell) => cell == null))) {
       if (kDebugMode) print("Error: Failed to generate a solved Sudoku board.");
       _isPuzzleLoaded = false;
       notifyListeners();
       return;
    }

    // 2. Create the playable puzzle board by removing cells
    _board = _createPuzzleFromSolvedBoard(_solutionBoard, difficulty);

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
    notifyListeners();
  }

  // --- Sudoku Generation Logic ---
  // ( _generateSolvedBoard and _createPuzzleFromSolvedBoard remain the same )
   bool _generateSolvedBoard(List<List<int?>> board) {
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

  List<List<SudokuCellData>> _createPuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int difficulty) {
      int cellsToRemove;
      switch (difficulty) {
          case 0: cellsToRemove = 30; break; // Easy
          case 1: cellsToRemove = 40; break; // Medium
          case 2: cellsToRemove = 50; break; // Hard
          case 3: cellsToRemove = 55; break; // Very Hard
          default: cellsToRemove = 40;
      }
      cellsToRemove = min(cellsToRemove, 64);
       List<List<SudokuCellData>> puzzleBoard = List.generate(
          9,
          (r) => List.generate(
              9,
              (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true)
          )
      );
      int removedCount = 0;
      while (removedCount < cellsToRemove) {
          int r = _random.nextInt(9);
          int c = _random.nextInt(9);
          if (puzzleBoard[r][c].value != null) {
             puzzleBoard[r][c] = SudokuCellData(value: null, isFixed: false);
             removedCount++;
          }
      }
      return puzzleBoard;
  }


  // --- Validation Logic ---
  // ( _isValidPlacement remains the same )
   bool _isValidPlacement(List<List<int?>> board, int row, int col, int num) {
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


   // --- Renamed to public and added notifyListeners check ---
   // Updates the error state of the board after a move or settings change
  void updateBoardErrors(bool showErrors) {
      bool errorsChanged = false;
      List<List<int?>> currentBoardState = List.generate(9,
          (r) => List.generate(9, (c) => _board[r][c].value)
      );

      for (int r = 0; r < 9; r++) {
         for (int c = 0; c < 9; c++) {
            SudokuCellData cell = _board[r][c];
            int? currentValue = cell.value;
            bool oldErrorState = cell.hasError; // Store previous state

            if (currentValue == null || cell.isFixed) {
               cell.hasError = false;
               if(oldErrorState != cell.hasError) errorsChanged = true; // Check if state changed
               continue;
            }

            currentBoardState[r][c] = null;
            bool isValid = _isValidPlacement(currentBoardState, r, c, currentValue);
            currentBoardState[r][c] = currentValue;

            cell.hasError = !isValid && showErrors;
             if(oldErrorState != cell.hasError) errorsChanged = true; // Check if state changed
         }
      }
       // Notify listeners only if any error state actually changed
       if (errorsChanged) {
          notifyListeners();
       }
  }

  // ( _isBoardCompleteAndCorrect remains the same )
   bool _isBoardCompleteAndCorrect() {
      for (int r = 0; r < 9; r++) {
         for (int c = 0; c < 9; c++) {
             if (_board[r][c].value == null || _board[r][c].value != _solutionBoard[r][c]) return false;
             if (_board[r][c].hasError) return false;
         }
      }
      return true;
  }

  // --- Cell Interaction ---
  // ( selectCell remains the same )
  void selectCell(int row, int col) {
    if (_selectedRow == row && _selectedCol == col) {
       _selectedRow = null;
       _selectedCol = null;
    } else {
      _selectedRow = row;
      _selectedCol = col;
    }
    notifyListeners();
  }


  // placeValue now only deals with index, gets showErrors flag passed in
  void placeValue(int colorIndex, {required bool showErrors}) {
    if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
       final cell = _board[_selectedRow!][_selectedCol!];
       if (!cell.isFixed) {
          _saveStateToHistory(); // Save current state before modification

          if (_isEditingCandidates) {
            if (cell.candidates.contains(colorIndex)) {
              cell.candidates.remove(colorIndex);
            } else {
               cell.candidates.add(colorIndex);
            }
            if(cell.value != null) cell.value = null;
          } else {
            if (cell.value == colorIndex) {
              cell.value = null; // Clear if same color tapped again
            } else {
              cell.value = colorIndex;
            }
            cell.candidates.clear();
          }

          // Update error states across the board based on the passed setting
          updateBoardErrors(showErrors);

          // Check for game completion
          if (_isBoardCompleteAndCorrect()) {
              _isCompleted = true;
              stopTimer();
              if (kDebugMode) print("Game Completed!");
              // Completion dialog handled by GameScreen listener
          } else {
             _isCompleted = false;
          }

          // Notify listeners about changes to board data (value/candidates)
          // Error updates will notify separately if errors changed
          notifyListeners();
       }
    }
  }

  // ( toggleEditMode remains the same )
  void toggleEditMode() {
    _isEditingCandidates = !_isEditingCandidates;
    notifyListeners();
  }


   // eraseSelectedCell now gets showErrors flag passed in
   void eraseSelectedCell({required bool showErrors}) {
       if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
           final cell = _board[_selectedRow!][_selectedCol!];
           if (!cell.isFixed) {
               if (cell.value != null || cell.candidates.isNotEmpty) {
                  _saveStateToHistory(); // Save state before erasing
                  cell.value = null;
                  cell.candidates.clear();
                  updateBoardErrors(showErrors); // Re-validate after erasing
                   // Notify about value/candidate changes
                   notifyListeners();
               }
           }
       }
   }

  // --- Back/Undo ---
  // ( _saveStateToHistory remains the same )
  void _saveStateToHistory() {
      List<List<SudokuCellData>> boardCopy = List.generate(
          9, (r) => List.generate(9, (c) => _board[r][c].clone())
      );
      _history.add(boardCopy);
      if (_history.length > _maxHistory) { _history.removeAt(0); }
      // Optional: Notify if UI depends on canUndo, maybe not needed
      // notifyListeners();
  }


  // performUndo now gets showErrors flag passed in
  void performUndo({required bool showErrors}) {
      if (_history.isNotEmpty) {
         _board = _history.removeLast();
         // No need to reset error flags manually, updateBoardErrors handles it
         updateBoardErrors(showErrors); // Re-validate the restored board state

         _isCompleted = _isBoardCompleteAndCorrect();
         if(_isCompleted) stopTimer();

         notifyListeners(); // Notify about board restoration
      } else {
          if (kDebugMode) print("Undo history is empty.");
      }
  }

  // --- Timer Control ---
  // ( startTimer, pauseTimer, resumeTimer, stopTimer, resetTimer remain the same )
 void startTimer() {
    if (_timer != null && _timer!.isActive) return; // Already running
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_isPaused && !_isCompleted) {
           _elapsedTime += const Duration(seconds: 1);
           // --- REMOVED notifyListeners() FROM HERE ---
           // notifyListeners(); // This was causing excessive rebuilds
        }
    });
  }
  void pauseTimer() {
    _isPaused = true;
    // notifyListeners(); // May not be needed if UI doesn't react to pause state directly
   }
  void resumeTimer() {
     _isPaused = false;
     // notifyListeners(); // May not be needed
   }
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
   }
  void resetTimer() {
    stopTimer();
    _elapsedTime = Duration.zero;
   }


  // --- Game State Control ---
  // ( pauseGame, resumeGame remain the same )
   void pauseGame() {
    pauseTimer();
    _isPaused = true; // Ensure state is set
    // Maybe overlay a pause menu
    notifyListeners();
   }
  void resumeGame() {
    _isPaused = false; // Ensure state is set
    resumeTimer();
    notifyListeners();
   }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}