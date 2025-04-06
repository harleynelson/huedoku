// File: lib/providers/game_provider.dart
// Location: ./lib/providers/game_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';

const Map<int, String> difficultyLabels = {
  -1: "Random", 0: "Easy", 1: "Medium", 2: "Hard", 3: "Expert",
};

class GameProvider extends ChangeNotifier {
  List<List<SudokuCellData>> _board = [];
  List<List<int?>> _solutionBoard = []; // Store the original solution
  bool _isPuzzleLoaded = false;
  bool _isEditingCandidates = false;
  int? _selectedRow;
  int? _selectedCol;
  final Random _random = Random();
  int? _currentPuzzleDifficulty;
  int? _initialDifficultySelection;

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;
  bool _isCompleted = false;
  final List<List<List<SudokuCellData>>> _history = [];
  final int _maxHistory = 20;

  // --- REMOVED _minCluesConstraint (no longer used directly for generation) ---
  // static const int _minCluesConstraint = 2;

  List<List<SudokuCellData>> get board => _board;
  bool get isPuzzleLoaded => _isPuzzleLoaded;
  bool get isEditingCandidates => _isEditingCandidates;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  Duration get elapsedTime => _elapsedTime;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;
  bool get canUndo => _history.isNotEmpty;
  int? get currentPuzzleDifficulty => _currentPuzzleDifficulty;
  int? get initialDifficultySelection => _initialDifficultySelection;

  // --- loadNewPuzzle (logic remains the same) ---
  void loadNewPuzzle({int difficulty = 1}) {
      _initialDifficultySelection = difficulty;
      int actualDifficulty;
      if (difficulty == -1) { actualDifficulty = _random.nextInt(4); }
      else { actualDifficulty = difficulty.clamp(0, 3); }
      _currentPuzzleDifficulty = actualDifficulty;

      if (kDebugMode) { print("Loading new puzzle. Initial selection: $difficulty -> Actual difficulty: $actualDifficulty (${difficultyLabels[actualDifficulty]})"); }

      _solutionBoard = List.generate(9, (_) => List.generate(9, (_) => null));
      if (!_generateSolvedBoard(_solutionBoard)) {
         if (kDebugMode) print("Error: Failed to generate a solved Sudoku board.");
         _isPuzzleLoaded = false; _currentPuzzleDifficulty = null; _initialDifficultySelection = null;
         notifyListeners(); return;
      }

      // --- *** Use NEW puzzle creation method *** ---
      var puzzleResult = _createUniquePuzzleFromSolvedBoard(_solutionBoard, actualDifficulty);
      if (puzzleResult == null) {
         if (kDebugMode) print("Error: Failed to create a unique puzzle. Retrying...");
         // Optionally add retry logic here or notify user
         _isPuzzleLoaded = false; _currentPuzzleDifficulty = null; _initialDifficultySelection = null;
         notifyListeners(); return;
      }
      _board = puzzleResult;
      // --- *** End NEW puzzle creation method usage *** ---

      _isPuzzleLoaded = true; _isCompleted = false; _isPaused = false;
      _selectedRow = null; _selectedCol = null; _isEditingCandidates = false;
      _history.clear(); resetTimer(); startTimer();
      notifyListeners();
  }

  // --- _generateSolvedBoard (unchanged) ---
  bool _generateSolvedBoard(List<List<int?>> board) {
    int? row, col; bool foundEmpty=false;
    for(row=0; row!<9; row++){for(col=0; col!<9; col++){if(board[row][col]==null){foundEmpty=true; break;}}if(foundEmpty)break;}
    if(!foundEmpty)return true;
    List<int> nums=List.generate(9,(i)=>i)..shuffle(_random);
    for(int n in nums){if(_isValidPlacementInternal(board,row!,col!,n)){board[row][col]=n;if(_generateSolvedBoard(board))return true;board[row][col]=null;}}
    return false;
  }

  // --- *** NEW: Puzzle Creation with Uniqueness Check *** ---
  List<List<SudokuCellData>>? _createUniquePuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int actualDifficulty) {
      int cellsToRemove;
      // Adjust these targets based on desired difficulty and performance
      // Fewer cells removed = easier, More cells removed = harder (but takes longer)
      switch (actualDifficulty) {
          case 0: cellsToRemove = 35; break; // Easy (35 normally)
          case 1: cellsToRemove = 42; break; // Medium
          case 2: cellsToRemove = 49; break; // Hard
          case 3: cellsToRemove = 53; break; // Expert (may take noticeable time)
          default: cellsToRemove = 42;
      }
      cellsToRemove = min(cellsToRemove, 60); // Limit removals to avoid excessive generation time

      // Start with the fully solved board converted to SudokuCellData
      List<List<SudokuCellData>> puzzleBoardData = List.generate( 9,
         (r) => List.generate(9, (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true))
      );
      // Create a mutable int board for the solver
      List<List<int?>> currentPuzzleState = List.generate(9, (r) => List.from(solvedBoard[r]));

      int removedCount = 0;
      int attempts = 0;
      final int maxTotalAttempts = 81 * 2; // Limit total attempts to prevent very long generation

      // Get all possible cell indices and shuffle them
      List<int> cellIndices = List.generate(81, (i) => i)..shuffle(_random);

      for (int index in cellIndices) {
          if (removedCount >= cellsToRemove || attempts >= maxTotalAttempts) break;
          attempts++;

          int r = index ~/ 9;
          int c = index % 9;

          // Skip if already removed
          if (currentPuzzleState[r][c] == null) continue;

          // Temporarily remove the value and check uniqueness
          int? tempValue = currentPuzzleState[r][c];
          currentPuzzleState[r][c] = null;

          // --- Check number of solutions ---
          int solutionCount = _countSolutions(currentPuzzleState);

          if (solutionCount == 1) {
              // Removal is valid, keep it removed
              removedCount++;
          } else {
              // Removal leads to 0 or >1 solutions, put the value back
              currentPuzzleState[r][c] = tempValue;
          }
      }

      if (kDebugMode) print("Puzzle Generation: Target removals: $cellsToRemove, Actual removals: $removedCount, Attempts: $attempts");

      // If we couldn't remove enough cells (e.g., uniqueness constraint too strict),
      // we might return null or a potentially easier puzzle than intended.
      // For now, return the puzzle generated, even if fewer cells were removed.
      // if (removedCount < cellsToRemove / 2) return null; // Example: fail if drastically fewer cells removed

      // Finalize the SudokuCellData board based on the final state
      for (int r = 0; r < 9; r++) {
         for (int c = 0; c < 9; c++) {
            if (currentPuzzleState[r][c] != null) {
               // Keep value, mark as fixed
               puzzleBoardData[r][c] = SudokuCellData(value: currentPuzzleState[r][c], isFixed: true);
            } else {
               // Cell was removed, mark as empty and not fixed
               puzzleBoardData[r][c] = SudokuCellData(value: null, isFixed: false);
            }
         }
      }

      return puzzleBoardData;
  }
  // --- *** END NEW Puzzle Creation Method *** ---


  // --- *** NEW: Solution Counter (Backtracking) *** ---
  int _countSolutions(List<List<int?>> board) {
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

    // If no empty cell, we found one complete solution
    if (!foundEmpty) {
      return 1;
    }

    int count = 0;
    // Try numbers 0-8 (representing colors/patterns)
    for (int num = 0; num < 9; num++) {
      if (_isValidPlacementInternal(board, row!, col!, num)) {
        board[row][col] = num; // Place number

        // Recurse and add solutions found from this placement
        count += _countSolutions(board);

        board[row][col] = null; // Backtrack: Remove number

        // Optimization: If we already found more than one solution, stop counting
        if (count > 1) {
          return count;
        }
      }
    }
    return count;
  }
  // --- *** END Solution Counter *** ---


  // --- Validation Logic ---
  // Internal helper for solvers (uses int? board)
  bool _isValidPlacementInternal(List<List<int?>> board, int row, int col, int num) {
     // Check row
     for(int c=0;c<9;c++){ if(board[row][c]==num) return false; }
     // Check column
     for(int r=0;r<9;r++){ if(board[r][col]==num) return false; }
     // Check 3x3 block
     int startRow=(row~/3)*3; int startCol=(col~/3)*3;
     for(int r=0;r<3;r++){ for(int c=0;c<3;c++){ if(board[startRow+r][startCol+c]==num) return false; } }
     return true;
  }

  // Public helper used for error checking (uses current board state)
  bool isValidPlacementForCell(int row, int col, int num) {
      // Creates a temporary board reflecting current user input for checking
      List<List<int?>> tempBoard = List.generate(9, (r) => List.generate(9, (c) => _board[r][c].value));
      // Temporarily clear the cell being checked if it already has a value
      tempBoard[row][col] = null;
      return _isValidPlacementInternal(tempBoard, row, col, num);
  }


  // Update Board Errors (uses the public validity check)
  void updateBoardErrors(bool showErrors) {
     bool errorStateChanged = false;
     for(int r=0; r<9; r++){
       for(int c=0; c<9; c++){
         SudokuCellData cell = _board[r][c];
         int? cellValue = cell.value;
         bool previousError = cell.hasError;

         if(cellValue == null || cell.isFixed){
           cell.hasError = false; // Fixed cells or empty cells have no errors
         } else {
           // Check if the current placement is valid according to rules
           cell.hasError = !isValidPlacementForCell(r, c, cellValue);
         }

         if(previousError != cell.hasError) {
           errorStateChanged = true;
         }
       }
     }
     // Only notify if errors should be shown OR if an error state actually changed
     // (prevents notifying just because the setting is toggled)
     if (showErrors && errorStateChanged) {
        notifyListeners();
     } else if (!showErrors && errorStateChanged) {
        // If errors are hidden now, but state changed (likely errors cleared), notify to update UI
        notifyListeners();
     }
  }

  // --- *** NEW: Helper to check if a completed board state is valid *** ---
  bool _isBoardStateValid(List<List<SudokuCellData>> boardData) {
     // Convert to int? grid first
     List<List<int?>> boardValues = List.generate(9, (r) => List.generate(9, (c) {
        // If any cell is null, the board isn't fully complete, thus not valid *yet*
        if (boardData[r][c].value == null) return -1; // Use -1 temporarily to signal incompletion
        return boardData[r][c].value;
     }));

     for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
           int? currentValue = boardValues[r][c];
           if (currentValue == -1 || currentValue == null) return false; // Should not happen if called correctly after _isBoardCompleteAndCorrect check

           // Temporarily remove value to check placement validity
           boardValues[r][c] = null;
           if (!_isValidPlacementInternal(boardValues, r, c, currentValue)) {
              return false; // Found a violation
           }
           boardValues[r][c] = currentValue; // Put back value
        }
     }
     return true; // All checks passed
  }
 // --- *** END Board State Validity Check *** ---


   // --- *** UPDATED Win Condition Check *** ---
   bool _isBoardCompleteAndCorrect() {
       // 1. Check if all cells are filled
       for(int r=0; r<9; r++){
          for(int c=0; c<9; c++){
             if(_board[r][c].value == null) return false; // Not complete
          }
       }

       // 2. Check if the current board state is a valid Sudoku solution
       return _isBoardStateValid(_board);
   }
   // --- *** END UPDATED Win Condition Check *** ---


   // --- Hint Logic (unchanged) ---
    bool provideHint({required bool showErrors}) {
    if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
      final cell = _board[_selectedRow!][_selectedCol!];
      if (!cell.isFixed && cell.value == null) {
        int? solutionValue = _solutionBoard[_selectedRow!][_selectedCol!]; // Hint uses original solution
        if (solutionValue != null) {
          _saveStateToHistory(); cell.value = solutionValue; cell.candidates.clear(); cell.isHint = true;
          updateBoardErrors(showErrors);
          // Check completion using the updated method
          if (_isBoardCompleteAndCorrect()) { _isCompleted = true; stopTimer(); if (kDebugMode) print("Game Completed via Hint!");
          } else { _isCompleted = false; }
           notifyListeners(); return true;
        } } } return false; }

  // --- Cell Interaction (placeValue uses updated completion check indirectly) ---
  void selectCell(int row, int col) { if(_selectedRow==row&&_selectedCol==col){_selectedRow=null;_selectedCol=null;}else{_selectedRow=row;_selectedCol=col;} notifyListeners(); }

  void placeValue(int colorIndex, {required bool showErrors}) {
      if(_selectedRow!=null&&_selectedCol!=null&&!_isCompleted){final cell=_board[_selectedRow!][_selectedCol!];
      if(!cell.isFixed){_saveStateToHistory();if(_isEditingCandidates){if(cell.candidates.contains(colorIndex)){cell.candidates.remove(colorIndex);}else{cell.candidates.add(colorIndex);}if(cell.value!=null)cell.value=null;}
      else{if(cell.value==colorIndex){cell.value=null;}else{cell.value=colorIndex;}cell.candidates.clear();}
      updateBoardErrors(showErrors); // Update errors based on current placement
      // Check completion using the updated method
      if(_isBoardCompleteAndCorrect()){_isCompleted=true;stopTimer();if(kDebugMode)print("Game Completed!");}else{_isCompleted=false;}
      notifyListeners();}}}

  void toggleEditMode() { _isEditingCandidates=!_isEditingCandidates; notifyListeners(); }
  void eraseSelectedCell({required bool showErrors}) { if(_selectedRow!=null&&_selectedCol!=null&&!_isCompleted){final cell=_board[_selectedRow!][_selectedCol!]; if(!cell.isFixed){if(cell.value!=null||cell.candidates.isNotEmpty){_saveStateToHistory();cell.value=null;cell.candidates.clear();updateBoardErrors(showErrors);notifyListeners();}}} }

  // --- Back/Undo (unchanged) ---
  void _saveStateToHistory() { List<List<SudokuCellData>> bc=List.generate(9,(r)=>List.generate(9,(c)=>_board[r][c].clone()));_history.add(bc);if(_history.length>_maxHistory){_history.removeAt(0);} }
  void performUndo({required bool showErrors}) { if(_history.isNotEmpty){_board=_history.removeLast();updateBoardErrors(showErrors);_isCompleted=_isBoardCompleteAndCorrect();if(_isCompleted){stopTimer();}else if(!_isPaused&&_timer==null){startTimer();}notifyListeners();}else{if(kDebugMode)print("Undo history is empty.");} }

  // --- Timer Control (unchanged) ---
   void startTimer() { if (_timer != null && _timer!.isActive) return; _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (!_isPaused && !_isCompleted) { _elapsedTime += const Duration(seconds: 1); notifyListeners(); } }); }
   void pauseTimer(){_isPaused=true;notifyListeners();}
   void resumeTimer(){_isPaused=false;if(_timer==null||!_timer!.isActive){startTimer();}notifyListeners();}
   void stopTimer(){_timer?.cancel();_timer=null;notifyListeners();}
   void resetTimer(){stopTimer();_elapsedTime=Duration.zero;notifyListeners();}
   void pauseGame(){pauseTimer();notifyListeners();}
   void resumeGame(){resumeTimer();notifyListeners();}

  // --- Palette Dimming Helpers (unchanged) ---
  bool isColorGloballyComplete(int colorIndex) { if (!_isPuzzleLoaded || _solutionBoard.isEmpty || _board.isEmpty) return false; int solutionCount = 0; int boardCorrectCount = 0; for (int r = 0; r < 9; r++) { for (int c = 0; c < 9; c++) { if (_solutionBoard[r][c] == colorIndex) { solutionCount++; if (_board[r][c].value == colorIndex && !_board[r][c].hasError) { boardCorrectCount++; } } } } return solutionCount == 9 && boardCorrectCount == 9; }
  bool isColorUsedInSelectionContext(int colorIndex, int row, int col) { if (!_isPuzzleLoaded || _board.isEmpty) return false; for (int c = 0; c < 9; c++) { if (_board[row][c].value == colorIndex) return true; } for (int r = 0; r < 9; r++) { if (_board[r][col].value == colorIndex) return true; } int startRow = (row ~/ 3) * 3; int startCol = (col ~/ 3) * 3; for (int r = 0; r < 3; r++) { for (int c = 0; c < 3; c++) { if (_board[startRow + r][startCol + c].value == colorIndex) return true; }} return false; }

  @override
  void dispose() { stopTimer(); super.dispose(); }
}