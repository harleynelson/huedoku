// File: lib/providers/game_provider.dart
// Location: ./lib/providers/game_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';

const Map<int, String> difficultyLabels = {
  -1: "Random", 0: "Easy", 1: "Medium", 2: "Hard", 3: "Painful",
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

  // --- NEW: Flag for intro number animation ---
  bool _runIntroNumberAnimation = false;

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
  // --- NEW: Getter for intro animation flag ---
  bool get runIntroNumberAnimation => _runIntroNumberAnimation;


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

      var puzzleResult = _createUniquePuzzleFromSolvedBoard(_solutionBoard, actualDifficulty);
      if (puzzleResult == null) {
         if (kDebugMode) print("Error: Failed to create a unique puzzle. Retrying...");
         _isPuzzleLoaded = false; _currentPuzzleDifficulty = null; _initialDifficultySelection = null;
         notifyListeners(); return;
      }
      _board = puzzleResult;

      _isPuzzleLoaded = true; _isCompleted = false; _isPaused = false;
      _selectedRow = null; _selectedCol = null; _isEditingCandidates = false;
      _history.clear(); resetTimer(); startTimer();
      // --- NEW: Reset intro animation flag on new puzzle ---
      _runIntroNumberAnimation = false;
      notifyListeners();
  }

  // --- Methods to control intro animation flag ---
  void triggerIntroNumberAnimation() {
    if (!_runIntroNumberAnimation) {
      _runIntroNumberAnimation = true;
      notifyListeners();
      // Optionally, set a timer to turn it off automatically after a duration
      // Timer(Duration(seconds: 3), () { // Example duration
      //   resetIntroNumberAnimation();
      // });
    }
  }

  void resetIntroNumberAnimation() {
    if (_runIntroNumberAnimation) {
      _runIntroNumberAnimation = false;
      // Do we need to notify here? Maybe not, depends on usage.
      // Let's notify for now to be safe.
      notifyListeners();
    }
  }
  // --- End NEW Methods ---

  // --- _generateSolvedBoard (unchanged) ---
  bool _generateSolvedBoard(List<List<int?>> board) {
    int? row, col; bool foundEmpty=false;
    for(row=0; row!<9; row++){for(col=0; col!<9; col++){if(board[row][col]==null){foundEmpty=true; break;}}if(foundEmpty)break;}
    if(!foundEmpty)return true;
    List<int> nums=List.generate(9,(i)=>i)..shuffle(_random);
    for(int n in nums){if(_isValidPlacementInternal(board,row!,col!,n)){board[row][col]=n;if(_generateSolvedBoard(board))return true;board[row][col]=null;}}
    return false;
  }

  // --- _createUniquePuzzleFromSolvedBoard (unchanged) ---
  List<List<SudokuCellData>>? _createUniquePuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int actualDifficulty) {
      int cellsToRemove;
      switch (actualDifficulty) {
          case 0: cellsToRemove = 28; break; // Easy
          case 1: cellsToRemove = 38; break; // Medium
          case 2: cellsToRemove = 47; break; // Hard
          case 3: cellsToRemove = 53; break; // Painful
          default: cellsToRemove = 42;
      }
      cellsToRemove = min(cellsToRemove, 60);

      List<List<SudokuCellData>> puzzleBoardData = List.generate( 9,
         (r) => List.generate(9, (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true))
      );
      List<List<int?>> currentPuzzleState = List.generate(9, (r) => List.from(solvedBoard[r]));

      int removedCount = 0;
      int attempts = 0;
      final int maxTotalAttempts = 81 * 2;

      List<int> cellIndices = List.generate(81, (i) => i)..shuffle(_random);

      for (int index in cellIndices) {
          if (removedCount >= cellsToRemove || attempts >= maxTotalAttempts) break;
          attempts++;

          int r = index ~/ 9;
          int c = index % 9;

          if (currentPuzzleState[r][c] == null) continue;

          int? tempValue = currentPuzzleState[r][c];
          currentPuzzleState[r][c] = null;

          int solutionCount = _countSolutions(currentPuzzleState);

          if (solutionCount == 1) {
              removedCount++;
          } else {
              currentPuzzleState[r][c] = tempValue;
          }
      }

      if (kDebugMode) print("Puzzle Generation: Target removals: $cellsToRemove, Actual removals: $removedCount, Attempts: $attempts");

      for (int r = 0; r < 9; r++) {
         for (int c = 0; c < 9; c++) {
            if (currentPuzzleState[r][c] != null) {
               puzzleBoardData[r][c] = SudokuCellData(value: currentPuzzleState[r][c], isFixed: true);
            } else {
               puzzleBoardData[r][c] = SudokuCellData(value: null, isFixed: false);
            }
         }
      }

      return puzzleBoardData;
  }


  // --- _countSolutions (unchanged) ---
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

    if (!foundEmpty) {
      return 1;
    }

    int count = 0;
    for (int num = 0; num < 9; num++) {
      if (_isValidPlacementInternal(board, row!, col!, num)) {
        board[row][col] = num;
        count += _countSolutions(board);
        board[row][col] = null;
        if (count > 1) {
          return count;
        }
      }
    }
    return count;
  }


  // --- _isValidPlacementInternal (unchanged) ---
  bool _isValidPlacementInternal(List<List<int?>> board, int row, int col, int num) {
     for(int c=0;c<9;c++){ if(board[row][c]==num) return false; }
     for(int r=0;r<9;r++){ if(board[r][col]==num) return false; }
     int startRow=(row~/3)*3; int startCol=(col~/3)*3;
     for(int r=0;r<3;r++){ for(int c=0;c<3;c++){ if(board[startRow+r][startCol+c]==num) return false; } }
     return true;
  }

  // --- isValidPlacementForCell (unchanged) ---
  bool isValidPlacementForCell(int row, int col, int num) {
      List<List<int?>> tempBoard = List.generate(9, (r) => List.generate(9, (c) => _board[r][c].value));
      tempBoard[row][col] = null;
      return _isValidPlacementInternal(tempBoard, row, col, num);
  }


  // --- updateBoardErrors (unchanged) ---
  void updateBoardErrors(bool showErrors) {
     bool errorStateChanged = false;
     for(int r=0; r<9; r++){
       for(int c=0; c<9; c++){
         SudokuCellData cell = _board[r][c];
         int? cellValue = cell.value;
         bool previousError = cell.hasError;

         if(cellValue == null || cell.isFixed){
           cell.hasError = false;
         } else {
           cell.hasError = !isValidPlacementForCell(r, c, cellValue);
         }

         if(previousError != cell.hasError) {
           errorStateChanged = true;
         }
       }
     }
     if (showErrors && errorStateChanged) {
        notifyListeners();
     } else if (!showErrors && errorStateChanged) {
        notifyListeners();
     }
  }

  // --- _isBoardStateValid (unchanged) ---
  bool _isBoardStateValid(List<List<SudokuCellData>> boardData) {
     List<List<int?>> boardValues = List.generate(9, (r) => List.generate(9, (c) {
        if (boardData[r][c].value == null) return -1;
        return boardData[r][c].value;
     }));

     for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
           int? currentValue = boardValues[r][c];
           if (currentValue == -1 || currentValue == null) return false;
           boardValues[r][c] = null;
           if (!_isValidPlacementInternal(boardValues, r, c, currentValue)) {
              return false;
           }
           boardValues[r][c] = currentValue;
        }
     }
     return true;
  }

   // --- _isBoardCompleteAndCorrect (unchanged) ---
   bool _isBoardCompleteAndCorrect() {
       for(int r=0; r<9; r++){
          for(int c=0; c<9; c++){
             if(_board[r][c].value == null) return false;
          }
       }
       return _isBoardStateValid(_board);
   }


   // --- provideHint (unchanged) ---
    bool provideHint({required bool showErrors}) {
    if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
      final cell = _board[_selectedRow!][_selectedCol!];
      if (!cell.isFixed && cell.value == null) {
        int? solutionValue = _solutionBoard[_selectedRow!][_selectedCol!];
        if (solutionValue != null) {
          _saveStateToHistory(); cell.value = solutionValue; cell.candidates.clear(); cell.isHint = true;
          updateBoardErrors(showErrors);
          if (_isBoardCompleteAndCorrect()) { _isCompleted = true; stopTimer(); if (kDebugMode) print("Game Completed via Hint!");
          } else { _isCompleted = false; }
           notifyListeners(); return true;
        } } } return false; }

  // --- Cell Interaction (unchanged) ---
  void selectCell(int row, int col) { if(_selectedRow==row&&_selectedCol==col){_selectedRow=null;_selectedCol=null;}else{_selectedRow=row;_selectedCol=col;} notifyListeners(); }

  void placeValue(int colorIndex, {required bool showErrors}) {
      if(_selectedRow!=null&&_selectedCol!=null&&!_isCompleted){final cell=_board[_selectedRow!][_selectedCol!];
      if(!cell.isFixed){_saveStateToHistory();if(_isEditingCandidates){if(cell.candidates.contains(colorIndex)){cell.candidates.remove(colorIndex);}else{cell.candidates.add(colorIndex);}if(cell.value!=null)cell.value=null;}
      else{if(cell.value==colorIndex){cell.value=null;}else{cell.value=colorIndex;}cell.candidates.clear();}
      updateBoardErrors(showErrors);
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