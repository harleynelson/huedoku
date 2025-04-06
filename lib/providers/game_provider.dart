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
  List<List<int?>> _solutionBoard = []; // Solution board needed for global check
  bool _isPuzzleLoaded = false;
  bool _isEditingCandidates = false;
  int? _selectedRow;
  int? _selectedCol;
  final Random _random = Random();
  int? _currentPuzzleDifficulty;

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;
  bool _isCompleted = false;
  final List<List<List<SudokuCellData>>> _history = [];
  final int _maxHistory = 20;

  // Minimum clues required per row/col/box after removal
  static const int _minCluesConstraint = 2;

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

  // --- loadNewPuzzle, _generateSolvedBoard, _createSolvablePuzzleFromSolvedBoard ---
  // --- _checkConstraints, _checkRowCount, _checkColCount, _checkBlockCount ---
  // --- _isValidPlacement, updateBoardErrors, _isBoardCompleteAndCorrect ---
  // --- provideHint, selectCell, placeValue, toggleEditMode, eraseSelectedCell ---
  // --- _saveStateToHistory, performUndo ---
  // --- startTimer, pauseTimer, resumeTimer, stopTimer, resetTimer ---
  // --- pauseGame, resumeGame ---
  // (These methods remain unchanged from the previous version)
  void loadNewPuzzle({int difficulty = 1}) {
      int actualDifficulty;
      if (difficulty == -1) { actualDifficulty = _random.nextInt(4); }
      else { actualDifficulty = difficulty.clamp(0, 3); }
      _currentPuzzleDifficulty = actualDifficulty;

      if (kDebugMode) print("Loading new puzzle with actual difficulty: $actualDifficulty (${difficultyLabels[actualDifficulty]})");

      _solutionBoard = List.generate(9, (_) => List.generate(9, (_) => null));
      if (!_generateSolvedBoard(_solutionBoard)) {
         if (kDebugMode) print("Error: Failed to generate a solved Sudoku board.");
         _isPuzzleLoaded = false;
         _currentPuzzleDifficulty = null;
         notifyListeners();
         return;
      }

      _board = _createSolvablePuzzleFromSolvedBoard(_solutionBoard, actualDifficulty);

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

  bool _generateSolvedBoard(List<List<int?>> board) {
    int? row, col; bool foundEmpty=false;
    for(row=0; row!<9; row++){for(col=0; col!<9; col++){if(board[row][col]==null){foundEmpty=true; break;}}if(foundEmpty)break;}
    if(!foundEmpty)return true;
    List<int> nums=List.generate(9,(i)=>i)..shuffle(_random);
    for(int n in nums){if(_isValidPlacement(board,row!,col!,n)){board[row][col]=n;if(_generateSolvedBoard(board))return true;board[row][col]=null;}}
    return false;
  }

  List<List<SudokuCellData>> _createSolvablePuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int actualDifficulty) {
      int cellsToRemove;
      switch (actualDifficulty) {
          case 0: cellsToRemove = 30; break; // Easy
          case 1: cellsToRemove = 40; break; // Medium
          case 2: cellsToRemove = 50; break; // Hard
          case 3: cellsToRemove = 55; break; // Expert
          default: cellsToRemove = 40;
      }
      cellsToRemove = min(cellsToRemove, 64);

       List<List<SudokuCellData>> puzzleBoard = List.generate(
          9, (r) => List.generate(9, (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true))
      );

      int removedCount = 0;
      int attempts = 0;
      final int maxAttempts = 81 * 3;
      List<int> cellIndices = List.generate(81, (i) => i)..shuffle(_random);

      for (int index in cellIndices) {
          if (removedCount >= cellsToRemove || attempts >= maxAttempts) break;
          attempts++;

          int r = index ~/ 9;
          int c = index % 9;
          if (puzzleBoard[r][c].value == null) continue;

          int? tempValue = puzzleBoard[r][c].value;
          puzzleBoard[r][c].value = null;

          if (_checkConstraints(puzzleBoard, r, c)) {
              puzzleBoard[r][c] = SudokuCellData(value: null, isFixed: false);
              removedCount++;
          } else {
              puzzleBoard[r][c].value = tempValue;
          }
      }

      if (kDebugMode && removedCount < cellsToRemove) {
          print("Warning: Could only remove $removedCount cells (Target: $cellsToRemove). Difficulty: $actualDifficulty");
      }
       if (kDebugMode) print("Final removed count: $removedCount");

       for (int r = 0; r < 9; r++) {
           for (int c = 0; c < 9; c++) {
               if (puzzleBoard[r][c].value != null) {
                   puzzleBoard[r][c] = SudokuCellData(value: puzzleBoard[r][c].value, isFixed: true);
               }
           }
       }
      return puzzleBoard;
  }

  bool _checkConstraints(List<List<SudokuCellData>> board, int row, int col) {
    return _checkRowCount(board, row) >= _minCluesConstraint &&
           _checkColCount(board, col) >= _minCluesConstraint &&
           _checkBlockCount(board, row, col) >= _minCluesConstraint;
  }

  int _checkRowCount(List<List<SudokuCellData>> board, int row) {
    int count = 0;
    for (int c = 0; c < 9; c++) { if (board[row][c].value != null) count++; } return count;
  }

  int _checkColCount(List<List<SudokuCellData>> board, int col) {
    int count = 0;
    for (int r = 0; r < 9; r++) { if (board[r][col].value != null) count++; } return count;
  }

  int _checkBlockCount(List<List<SudokuCellData>> board, int row, int col) {
    int count = 0;
    int startRow = (row ~/ 3) * 3; int startCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) { for (int c = 0; c < 3; c++) {
        if (board[startRow + r][startCol + c].value != null) count++;
    }} return count;
  }

  bool _isValidPlacement(List<List<int?>> board, int row, int col, int num) {
     for(int c=0;c<9;c++){if(board[row][c]==num)return false;}
     for(int r=0;r<9;r++){if(board[r][col]==num)return false;}
     int sr=(row~/3)*3; int sc=(col~/3)*3;
     for(int r=0;r<3;r++){for(int c=0;c<3;c++){if(board[sr+r][sc+c]==num)return false;}}
     return true;
  }

  void updateBoardErrors(bool showErrors) {
     bool errCh=false;List<List<int?>> cbs=List.generate(9,(r)=>List.generate(9,(c)=>_board[r][c].value));
     for(int r=0;r<9;r++){for(int c=0;c<9;c++){SudokuCellData cell=_board[r][c];int? cv=cell.value;bool oes=cell.hasError;
     if(cv==null||cell.isFixed){cell.hasError=false;if(oes!=cell.hasError)errCh=true;continue;}
     cbs[r][c]=null;bool iv=_isValidPlacement(cbs,r,c,cv);cbs[r][c]=cv;
     cell.hasError=!iv&&showErrors;if(oes!=cell.hasError)errCh=true;}}
     if(errCh){notifyListeners();}
  }

   bool _isBoardCompleteAndCorrect() {
       for(int r=0;r<9;r++){for(int c=0;c<9;c++){if(_board[r][c].value==null||_board[r][c].value!=_solutionBoard[r][c])return false;if(_board[r][c].hasError)return false;}} return true;
   }

  bool provideHint({required bool showErrors}) {
    if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
      final cell = _board[_selectedRow!][_selectedCol!];
      if (!cell.isFixed && cell.value == null) {
        int? solutionValue = _solutionBoard[_selectedRow!][_selectedCol!];
        if (solutionValue != null) {
          _saveStateToHistory();
          cell.value = solutionValue;
          cell.candidates.clear();
          cell.isHint = true;
          updateBoardErrors(showErrors);
          if (_isBoardCompleteAndCorrect()) {
              _isCompleted = true; stopTimer();
              if (kDebugMode) print("Game Completed via Hint!");
          } else { _isCompleted = false; }
           notifyListeners();
          return true;
        }
      }
    } return false;
  }

  void selectCell(int row, int col) {
      if(_selectedRow==row&&_selectedCol==col){_selectedRow=null;_selectedCol=null;}else{_selectedRow=row;_selectedCol=col;} notifyListeners();
  }

  void placeValue(int colorIndex, {required bool showErrors}) {
      if(_selectedRow!=null&&_selectedCol!=null&&!_isCompleted){final cell=_board[_selectedRow!][_selectedCol!];
      if(!cell.isFixed){_saveStateToHistory();if(_isEditingCandidates){if(cell.candidates.contains(colorIndex)){cell.candidates.remove(colorIndex);}else{cell.candidates.add(colorIndex);}if(cell.value!=null)cell.value=null;}
      else{if(cell.value==colorIndex){cell.value=null;}else{cell.value=colorIndex;}cell.candidates.clear();} updateBoardErrors(showErrors);
      if(_isBoardCompleteAndCorrect()){_isCompleted=true;stopTimer();if(kDebugMode)print("Game Completed!");}else{_isCompleted=false;} notifyListeners();}}}

  void toggleEditMode() { _isEditingCandidates=!_isEditingCandidates; notifyListeners(); }

  void eraseSelectedCell({required bool showErrors}) {
       if(_selectedRow!=null&&_selectedCol!=null&&!_isCompleted){final cell=_board[_selectedRow!][_selectedCol!];
       if(!cell.isFixed){if(cell.value!=null||cell.candidates.isNotEmpty){_saveStateToHistory();cell.value=null;cell.candidates.clear();updateBoardErrors(showErrors);notifyListeners();}}}
   }

  void _saveStateToHistory() {
      List<List<SudokuCellData>> bc=List.generate(9,(r)=>List.generate(9,(c)=>_board[r][c].clone()));_history.add(bc);if(_history.length>_maxHistory){_history.removeAt(0);}
  }

  void performUndo({required bool showErrors}) {
      if(_history.isNotEmpty){_board=_history.removeLast();updateBoardErrors(showErrors);_isCompleted=_isBoardCompleteAndCorrect();if(_isCompleted){stopTimer();}else if(!_isPaused&&_timer==null){startTimer();}notifyListeners();}else{if(kDebugMode)print("Undo history is empty.");}
  }

   void startTimer() {
       if (_timer != null && _timer!.isActive) return;
       _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
           if (!_isPaused && !_isCompleted) { _elapsedTime += const Duration(seconds: 1); notifyListeners(); }
       });
   }
   void pauseTimer(){_isPaused=true;notifyListeners();}
   void resumeTimer(){_isPaused=false;if(_timer==null||!_timer!.isActive){startTimer();}notifyListeners();}
   void stopTimer(){_timer?.cancel();_timer=null;notifyListeners();}
   void resetTimer(){stopTimer();_elapsedTime=Duration.zero;notifyListeners();}

   void pauseGame(){pauseTimer();notifyListeners();}
   void resumeGame(){resumeTimer();notifyListeners();}


  // --- Helper Methods for Palette Dimming (Updated) ---

  /// Checks if a specific color/pattern index is fully placed correctly on the board.
  /// (Checks against the solution board).
  bool isColorGloballyComplete(int colorIndex) {
    if (!_isPuzzleLoaded || _solutionBoard.isEmpty || _board.isEmpty) return false;

    int solutionCount = 0;
    int boardCorrectCount = 0;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_solutionBoard[r][c] == colorIndex) {
          solutionCount++;
          // Check if the current board has the correct value at this position
          // and it doesn't have an error flag (though correct placement implies no error)
          if (_board[r][c].value == colorIndex && !_board[r][c].hasError) {
            boardCorrectCount++;
          }
        }
      }
    }

    // Globally complete if exactly 9 instances are expected AND correctly placed
    // (solutionCount should always be 9 for a valid Sudoku)
    return solutionCount == 9 && boardCorrectCount == 9;
  }


  /// Checks if a specific color/pattern index is currently placed (value is set)
  /// within the selected row, column, OR 3x3 block.
  /// (Checks only the current board state).
  bool isColorUsedInSelectionContext(int colorIndex, int row, int col) {
    if (!_isPuzzleLoaded || _board.isEmpty) return false;

    // Check Row
    for (int c = 0; c < 9; c++) {
      if (_board[row][c].value == colorIndex) return true;
    }

    // Check Column
    for (int r = 0; r < 9; r++) {
      if (_board[r][col].value == colorIndex) return true;
    }

    // Check Block
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (_board[startRow + r][startCol + c].value == colorIndex) return true;
      }
    }

    return false; // Not used in row, column, or block
  }
  // --- End Helper Methods ---


  @override
  void dispose() { stopTimer(); super.dispose(); }
}