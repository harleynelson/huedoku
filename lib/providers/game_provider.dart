// File: lib/providers/game_provider.dart
// Location: Entire File (Updated logging in loadPuzzleFromString)

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';
import 'package:huedoku/constants.dart'; // Keep this import

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
  final int _maxHistory = kMaxHistory;

  // --- Hint tracking ---
  int _hintsUsed = 0;

  // --- Puzzle String for sharing ---
  String? _currentPuzzleString;

  bool _runIntroNumberAnimation = false;

  // --- Fields for loaded game info ---
  Duration? _timeToBeat;
  int? _initialHintsFromCode;


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
  int? get currentPuzzleDifficulty => _currentPuzzleDifficulty;
  int? get initialDifficultySelection => _initialDifficultySelection;
  bool get runIntroNumberAnimation => _runIntroNumberAnimation;
  int get hintsUsed => _hintsUsed;
  String? get currentPuzzleString => _currentPuzzleString;
  Duration? get timeToBeat => _timeToBeat;
  int? get initialHintsFromCode => _initialHintsFromCode;


  void loadNewPuzzle({int difficulty = 1}) {
      _initialDifficultySelection = difficulty;
      int actualDifficulty;
      if (difficulty == -1) { actualDifficulty = _random.nextInt(4); }
      else { actualDifficulty = difficulty.clamp(0, 3); }
      _currentPuzzleDifficulty = actualDifficulty;

      if (kDebugMode) { print("Loading new puzzle. Initial selection: $difficulty -> Actual difficulty: $actualDifficulty (${difficultyLabels[actualDifficulty]})"); }

      _solutionBoard = List.generate(kGridSize, (_) => List.generate(kGridSize, (_) => null));
      if (!_generateSolvedBoard(_solutionBoard)) {
         if (kDebugMode) print("Error: Failed to generate a solved Sudoku board.");
         _isPuzzleLoaded = false;
         resetGame();
         notifyListeners();
         return;
      }

      var puzzleResult = _createUniquePuzzleFromSolvedBoard(_solutionBoard, actualDifficulty);
      if (puzzleResult == null) {
         if (kDebugMode) print("Error: Failed to create a unique puzzle. Retrying might be needed or fallback.");
         _isPuzzleLoaded = false;
          resetGame();
         notifyListeners();
         return;
      }
      _board = puzzleResult;
      _isPuzzleLoaded = true;

      _isCompleted = false;
      _isPaused = false;
      _selectedRow = null;
      _selectedCol = null;
      _isEditingCandidates = false;
      _history.clear();
      _hintsUsed = 0;
      _timeToBeat = null;
      _initialHintsFromCode = null;

      _generateAndStorePuzzleString(); // Generates string with Hints: 0 for new game

      resetTimer();
      startTimer();
      _runIntroNumberAnimation = false;

      notifyListeners();
  }

  // Generates the initial puzzle state string (DxHxB)
  void _generateAndStorePuzzleString() {
    if (!_isPuzzleLoaded || _board.isEmpty) {
      if (kDebugMode) print("Debug: Exiting _generateAndStorePuzzleString early (puzzle not loaded or board empty). Setting string to null.");
      _currentPuzzleString = null;
      return;
    }

    StringBuffer sb = StringBuffer();
    String difficultyChar = 'M';
    if (_currentPuzzleDifficulty != null && difficultyLabels.containsKey(_currentPuzzleDifficulty)) {
        String label = difficultyLabels[_currentPuzzleDifficulty]!;
        if (label.isNotEmpty) difficultyChar = label[0].toUpperCase();
    } else if (_currentPuzzleDifficulty == -1) {
        difficultyChar = 'R';
    }

    int hintsToStore = _initialHintsFromCode ?? _hintsUsed;

    // Format: Difficulty'x'Hints'x'BoardString (Use 'x' as separator)
    sb.write('$difficultyChar${'x'}$hintsToStore${'x'}'); // Use 'x'

    try {
      for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
          final cell = _board[r][c];
          if (cell.isFixed && cell.value != null) sb.write('${cell.value! + 1}');
          else sb.write('0');
        }
      }
      _currentPuzzleString = sb.toString();
      if (kDebugMode) print('Debug: Generated Puzzle String (DxHxB): $_currentPuzzleString');
    } catch (e) {
        if (kDebugMode) print("Error during puzzle string generation loop: $e");
        _currentPuzzleString = null;
    }
  }

  // Loads a puzzle from a string (DxHxB or DxHxTxB)
  Future<bool> loadPuzzleFromString(String puzzleString) async {
    if (kDebugMode) print("Attempting to load puzzle from string: $puzzleString");

    // Use 'x' as the separator
    final parts = puzzleString.split('x'); // Use 'x'
    // Check for minimum parts (DxHxB) or maximum (DxHxTxB)
    if (parts.length < 3 || parts.length > 4) {
       // Update error message format
       if (kDebugMode) print("Error: Invalid puzzle string format (Expected DxHxB or DxHxTxB). String: '$puzzleString'");
       resetGame(); notifyListeners(); return false;
    }

    // --- Extract Parts ---
    String diffChar = parts[0].toUpperCase();
    String hintsString = parts[1];
    String? timeString;
    String boardString;

    if (parts.length == 4) { timeString = parts[2]; boardString = parts[3]; }
    else { boardString = parts[2]; }

    // --- Validate Difficulty Character ---
    int? difficulty;
    difficultyLabels.forEach((key, label) { if (label.isNotEmpty && label[0].toUpperCase() == diffChar) difficulty = key; });
    if (diffChar == 'R') difficulty = -1;
    if (difficulty == null) { if (kDebugMode) print("Error: Invalid difficulty character '$diffChar'."); resetGame(); notifyListeners(); return false; }

    // --- Validate Hints Number ---
    int? initialHints = int.tryParse(hintsString);
    if (initialHints == null || initialHints < 0) { if (kDebugMode) print("Error: Invalid hints value '$hintsString'."); resetGame(); notifyListeners(); return false; }

    // --- Validate Time (if present) ---
    Duration? timeToBeatValue;
    if (timeString != null) {
        int? timeInSeconds = int.tryParse(timeString);
        if (timeInSeconds == null || timeInSeconds < 0) { if (kDebugMode) print("Error: Invalid time value '$timeString'."); resetGame(); notifyListeners(); return false; }
        timeToBeatValue = Duration(seconds: timeInSeconds);
    }

    // --- Validate Board String Length ---
    if (boardString.length != kGridSize * kGridSize) { if (kDebugMode) print("Error: Incorrect board string length."); resetGame(); notifyListeners(); return false; }

    // --- Create initial board from string ---
    List<List<SudokuCellData>> initialBoard = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) => SudokuCellData(value: null, isFixed: false)));
    List<List<int?>> boardForSolving = List.generate(kGridSize, (_) => List.generate(kGridSize, (_) => null));
    try {
      for (int i = 0; i < boardString.length; i++) {
         int r = i ~/ kGridSize; int c = i % kGridSize; String char = boardString[i]; int? value; bool isFixed = false;
         if (char != '0') {
           value = int.tryParse(char);
           if (value != null && value >= 1 && value <= kGridSize) { value = value - 1; isFixed = true; boardForSolving[r][c] = value; }
           else { throw FormatException("Invalid char '$char'"); }
         }
         initialBoard[r][c] = SudokuCellData(value: value, isFixed: isFixed);
      }
    } catch (e) { if (kDebugMode) print("Error parsing board string part: $e"); resetGame(); notifyListeners(); return false; }

    // --- Solve the puzzle string to get the solution ---
    List<List<int?>> boardToSolveClone = List.generate(kGridSize, (r) => List.from(boardForSolving[r]));
    if (!_solveBoard(boardToSolveClone)) {
       if (kDebugMode) print("Warning: Could not find a unique solution for the shared puzzle string. Hints might not work correctly.");
       _solutionBoard = List.generate(kGridSize, (_) => List.generate(kGridSize, (_) => null));
    } else {
       _solutionBoard = List.generate(kGridSize, (r) => List<int?>.from(boardToSolveClone[r]), growable: false);
       if (kDebugMode) print("Successfully solved the base puzzle for solution storage.");
    }

    // --- Set up game state ---
    _board = initialBoard;
    _currentPuzzleDifficulty = difficulty;
    _initialDifficultySelection = difficulty;
    _isPuzzleLoaded = true;
    _isCompleted = false;
    _isPaused = false;
    _selectedRow = null;
    _selectedCol = null;
    _isEditingCandidates = false;
    _history.clear();
    _hintsUsed = 0; // Start hint counter at 0 for the user playing
    _initialHintsFromCode = initialHints; // Store hints from code for display
    _currentPuzzleString = puzzleString; // Store the original loaded string
    _timeToBeat = timeToBeatValue;

    resetTimer();
    startTimer();
    _runIntroNumberAnimation = false;

    notifyListeners();

    // --- Log Message (Reflects 'x' potentially in format) ---
    if (kDebugMode) {
      // Format note not needed in log, just log the values found
      String loadedInfo = "Successfully loaded puzzle. Difficulty: ${difficultyLabels[difficulty]}, Hints (from code): $initialHints";
      if (_timeToBeat != null) {
        loadedInfo += ", Time to Beat: ${_timeToBeat!.inSeconds}s";
      } else {
        loadedInfo += ", Time to Beat: (Not provided)";
      }
      print(loadedInfo);
    }

    return true;
  }


  // Solver function
  bool _solveBoard(List<List<int?>> board) {
    int? row, col; bool foundEmpty = false;
    for (row = 0; row! < kGridSize; row++) { for (col = 0; col! < kGridSize; col++) { if (board[row][col] == null) { foundEmpty = true; break; } } if (foundEmpty) break; }
    if (!foundEmpty) return true;
    List<int> nums = List.generate(kGridSize, (i) => i);
    for (int n in nums) { if (_isValidPlacementInternal(board, row!, col!, n)) { board[row][col] = n; if (_solveBoard(board)) return true; board[row][col] = null; } }
    return false;
  }

  // Intro animation control
  void triggerIntroNumberAnimation() { if (!_runIntroNumberAnimation) { _runIntroNumberAnimation = true; notifyListeners(); } }
  void resetIntroNumberAnimation() { if (_runIntroNumberAnimation) { _runIntroNumberAnimation = false; } }

  // Generates the initial solved board
  bool _generateSolvedBoard(List<List<int?>> board) {
    int? row, col; bool foundEmpty=false;
    for(row=0; row!<kGridSize; row++){for(col=0; col!<kGridSize; col++){if(board[row][col]==null){foundEmpty=true; break;}}if(foundEmpty)break;}
    if(!foundEmpty)return true;
    List<int> nums=List.generate(kGridSize,(i)=>i)..shuffle(_random);
    for(int n in nums){ if(_isValidPlacementInternal(board,row!,col!,n)){ board[row][col]=n; if(_generateSolvedBoard(board)) return true; board[row][col]=null; } }
    return false;
  }

  // Creates the puzzle by removing cells
  List<List<SudokuCellData>>? _createUniquePuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int actualDifficulty) {
    int cellsToRemove;
    switch (actualDifficulty) { case 0: cellsToRemove = kDifficultyEasyCellsToRemove; break; case 1: cellsToRemove = kDifficultyMediumCellsToRemove; break; case 2: cellsToRemove = kDifficultyHardCellsToRemove; break; case 3: cellsToRemove = kDifficultyPainfulCellsToRemove; break; default: cellsToRemove = kDifficultyMediumCellsToRemove; }
    cellsToRemove = min(cellsToRemove, 60);
    List<List<int?>> currentPuzzleState = List.generate(kGridSize, (r) => List.from(solvedBoard[r]));
    List<List<SudokuCellData>> puzzleBoardData = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true)));
    int removedCount = 0; int attempts = 0; final int maxTotalAttempts = kGridSize * kGridSize * 3; List<int> cellIndices = List.generate(kGridSize * kGridSize, (i) => i)..shuffle(_random);
    for (int index in cellIndices) {
        if (removedCount >= cellsToRemove || attempts >= maxTotalAttempts) break; attempts++; int r = index ~/ kGridSize; int c = index % kGridSize; if (currentPuzzleState[r][c] == null) continue; int? tempValue = currentPuzzleState[r][c]; currentPuzzleState[r][c] = null; List<List<int?>> boardToCheck = List.generate(kGridSize, (row) => List.from(currentPuzzleState[row])); int solutionCount = _countSolutions(boardToCheck);
        if (solutionCount == 1) removedCount++; else currentPuzzleState[r][c] = tempValue;
    }
    if (kDebugMode) print("Puzzle Generation: Target removals: $cellsToRemove, Actual removals: $removedCount, Attempts: $attempts");
    if (removedCount < cellsToRemove * 0.8 && cellsToRemove > 10) { if (kDebugMode) print("Warning: Fewer cells removed ($removedCount) than targeted ($cellsToRemove). Puzzle might be easier."); }
    for (int r = 0; r < kGridSize; r++) { for (int c = 0; c < kGridSize; c++) { if (currentPuzzleState[r][c] != null) puzzleBoardData[r][c] = SudokuCellData(value: currentPuzzleState[r][c], isFixed: true); else puzzleBoardData[r][c] = SudokuCellData(value: null, isFixed: false); } }
    return puzzleBoardData;
  }

  // Counts solutions for uniqueness check
  int _countSolutions(List<List<int?>> board) {
    int? row, col; bool foundEmpty = false;
    for (row = 0; row! < kGridSize; row++) { for (col = 0; col! < kGridSize; col++) { if (board[row][col] == null) { foundEmpty = true; break; } } if (foundEmpty) break; }
    if (!foundEmpty) return 1; int count = 0;
    for (int num = 0; num < kGridSize; num++) { if (_isValidPlacementInternal(board, row!, col!, num)) { board[row][col] = num; count += _countSolutions(board); board[row][col] = null; if (count > 1) return count; } }
    return count;
  }

  // Checks internal validity
  bool _isValidPlacementInternal(List<List<int?>> board, int row, int col, int num) {
     for(int c=0; c<kGridSize; c++){ if(board[row][c] == num) return false; }
     for(int r=0; r<kGridSize; r++){ if(board[r][col] == num) return false; }
     int startRow=(row~/kBoxSize)*kBoxSize; int startCol=(col~/kBoxSize)*kBoxSize;
     for(int r=0; r<kBoxSize; r++){ for(int c=0; c<kBoxSize; c++){ if(board[startRow+r][startCol+c] == num) return false; } }
     return true;
  }

  // Checks validity excluding the cell itself
  bool isValidPlacementForCell(int row, int col, int num) {
    List<List<int?>> tempBoard = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) => _board[r][c].value));
    tempBoard[row][col] = null; return _isValidPlacementInternal(tempBoard, row, col, num);
  }

  // Updates error flags on the board
  void updateBoardErrors(bool showErrors) {
     bool errorStateChanged = false;
     for(int r=0; r<kGridSize; r++){ for(int c=0; c<kGridSize; c++){ SudokuCellData cell = _board[r][c]; int? cellValue = cell.value; bool previousError = cell.hasError; if(cellValue == null || cell.isFixed){ cell.hasError = false; } else { cell.hasError = !isValidPlacementForCell(r, c, cellValue); } if(previousError != cell.hasError) { errorStateChanged = true; } } }
     if (errorStateChanged) { notifyListeners(); }
  }

  // Checks if the current board state is valid
  bool _isBoardStateValid(List<List<SudokuCellData>> boardData) {
     List<List<int?>> boardValues = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) => boardData[r][c].value));
     for (int r = 0; r < kGridSize; r++) { for (int c = 0; c < kGridSize; c++) { int? currentValue = boardValues[r][c]; if (currentValue != null) { boardValues[r][c] = null; if (!_isValidPlacementInternal(boardValues, r, c, currentValue)) return false; boardValues[r][c] = currentValue; } } }
     return true;
  }

   // Checks if the board is full and correct
   bool _isBoardCompleteAndCorrect() {
       for(int r=0; r<kGridSize; r++){ for(int c=0; c<kGridSize; c++){ if(_board[r][c].value == null) return false; } }
       return _isBoardStateValid(_board);
   }

   // Provides a hint (Removed puzzle string regeneration)
    bool provideHint({required bool showErrors}) {
      if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
        final cell = _board[_selectedRow!][_selectedCol!];
        if (!cell.isFixed && cell.value == null) {
          if (_solutionBoard.isEmpty || _selectedRow! >= _solutionBoard.length || _selectedCol! >= _solutionBoard[_selectedRow!].length) { if (kDebugMode) print("Error: Solution board not available for hint."); return false; }
          int? solutionValue = _solutionBoard[_selectedRow!][_selectedCol!];
          if (solutionValue != null) {
            _saveStateToHistory(); cell.value = solutionValue; cell.candidates.clear(); cell.isHint = true; _hintsUsed++;
            // Puzzle string is NOT regenerated here
            updateBoardErrors(showErrors);
            if (_isBoardCompleteAndCorrect()) { _isCompleted = true; stopTimer(); if (kDebugMode) print("Game Completed via Hint!"); } else { _isCompleted = false; }
            notifyListeners(); return true;
          } else { if (kDebugMode) print("Error: Solution value not found for hint."); }
        }
      }
      return false;
    }

  // --- Cell Interaction ---
  void selectCell(int row, int col) { if (_selectedRow == row && _selectedCol == col) { _selectedRow = null; _selectedCol = null; } else { _selectedRow = row; _selectedCol = col; } notifyListeners(); }
  void placeValue(int colorIndex, {required bool showErrors}) { if(_selectedRow != null && _selectedCol != null && !_isCompleted){ final cell = _board[_selectedRow!][_selectedCol!]; if (!cell.isFixed) { _saveStateToHistory(); if (_isEditingCandidates) { if (cell.value != null) { cell.value = null; cell.isHint = false; } if (cell.candidates.contains(colorIndex)) cell.candidates.remove(colorIndex); else cell.candidates.add(colorIndex); } else { cell.candidates.clear(); if (cell.value == colorIndex) { cell.value = null; cell.isHint = false; } else { cell.value = colorIndex; cell.isHint = false; } } updateBoardErrors(showErrors); if (_isBoardCompleteAndCorrect()) { _isCompleted = true; stopTimer(); if (kDebugMode) print("Game Completed!"); } else { _isCompleted = false; } notifyListeners(); } } }
  void toggleEditMode() { _isEditingCandidates=!_isEditingCandidates; notifyListeners(); }
  void eraseSelectedCell({required bool showErrors}) { if(_selectedRow!=null && _selectedCol!=null && !_isCompleted){ final cell=_board[_selectedRow!][_selectedCol!]; if (!cell.isFixed) { if (cell.value != null || cell.candidates.isNotEmpty) { _saveStateToHistory(); cell.value = null; cell.candidates.clear(); cell.isHint = false; updateBoardErrors(showErrors); notifyListeners(); } } } }

  // --- Back/Undo ---
  void _saveStateToHistory() { List<List<SudokuCellData>> boardCopy = List.generate(kGridSize, (r)=>List.generate(kGridSize,(c)=>_board[r][c].clone())); _history.add(boardCopy); if(_history.length > _maxHistory) _history.removeAt(0); }
  void performUndo({required bool showErrors}) {
      if(_history.isNotEmpty){
        // Restore previous board state
        _board = _history.removeLast();

        updateBoardErrors(showErrors); // Update errors for the restored state
        _isCompleted = _isBoardCompleteAndCorrect(); // Re-check completion status

        if(_isCompleted){
          stopTimer(); // Stop timer if undo resulted in completion
        } else if (!_isPaused && (_timer == null || !_timer!.isActive)) {
          // Restart timer if game was running and isn't completed/paused now
          startTimer();
        }
        notifyListeners(); // Notify UI about the restored board state
      } else {
        // Original else block remains
        if(kDebugMode) print("Undo history is empty.");
        // Optional: Show a snackbar to the user?
      }
  }
  // --- Timer Control ---
   void startTimer() { if (_timer != null && _timer!.isActive || _isCompleted) return; _timer = Timer.periodic(kTimerUpdateInterval, (timer) { if (!_isPaused && !_isCompleted) { _elapsedTime += kTimerUpdateInterval; notifyListeners(); } else { timer.cancel(); _timer = null; } }); }
   void pauseTimer(){ if (!_isPaused) { _isPaused = true; _timer?.cancel(); _timer = null; notifyListeners(); } }
   void resumeTimer(){ if (_isPaused && !_isCompleted) { _isPaused = false; startTimer(); notifyListeners(); } }
   void stopTimer(){ _timer?.cancel(); _timer = null; }
   void resetTimer(){ stopTimer(); _elapsedTime=Duration.zero; notifyListeners(); }
   void pauseGame(){ pauseTimer(); }
   void resumeGame(){ resumeTimer(); }

  // --- Palette Dimming Helpers ---
  bool isColorGloballyComplete(int colorIndex) { if (!_isPuzzleLoaded || _solutionBoard.isEmpty || _board.isEmpty) return false; int solutionCount = 0; int boardCorrectCount = 0; for (int r = 0; r < kGridSize; r++) { for (int c = 0; c < kGridSize; c++) { if (r < _solutionBoard.length && c < _solutionBoard[r].length && _solutionBoard[r][c] == colorIndex) solutionCount++; if (_board[r][c].value == colorIndex && !_board[r][c].hasError) boardCorrectCount++; } } return (solutionCount > 0 && solutionCount == boardCorrectCount) || (solutionCount == kGridSize && boardCorrectCount == kGridSize) ; }
  bool isColorUsedInSelectionContext(int colorIndex, int row, int col) { if (!_isPuzzleLoaded || _board.isEmpty) return false; for (int c = 0; c < kGridSize; c++) { if (_board[row][c].value == colorIndex) return true; } for (int r = 0; r < kGridSize; r++) { if (_board[r][col].value == colorIndex) return true; } int startRow = (row ~/ kBoxSize) * kBoxSize; int startCol = (col ~/ kBoxSize) * kBoxSize; for (int r = 0; r < kBoxSize; r++) { for (int c = 0; c < kBoxSize; c++) { if (_board[startRow + r][startCol + c].value == colorIndex) return true; } } return false; }

  // Resets the game state completely
  void resetGame() {
    _board = []; _solutionBoard = []; _isPuzzleLoaded = false; _isEditingCandidates = false; _selectedRow = null; _selectedCol = null; _currentPuzzleDifficulty = null; _initialDifficultySelection = null;
    resetTimer(); _isPaused = false; _isCompleted = false; _history.clear(); _hintsUsed = 0; _currentPuzzleString = null; _runIntroNumberAnimation = false;
    _timeToBeat = null; _initialHintsFromCode = null;
    if (kDebugMode) print("GameProvider state reset.");
  }


  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}