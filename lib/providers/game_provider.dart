// File: lib/providers/game_provider.dart
// Location: Entire File (Implementing puzzle code format changes)

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
  // --- Hint getter ---
  int get hintsUsed => _hintsUsed;
  // --- Puzzle String getter ---
  String? get currentPuzzleString => _currentPuzzleString;


  void loadNewPuzzle({int difficulty = 1}) {
      _initialDifficultySelection = difficulty;
      int actualDifficulty;
      if (difficulty == -1) { actualDifficulty = _random.nextInt(4); }
      else { actualDifficulty = difficulty.clamp(0, 3); }
      _currentPuzzleDifficulty = actualDifficulty;

      if (kDebugMode) { print("Loading new puzzle. Initial selection: $difficulty -> Actual difficulty: $actualDifficulty (${difficultyLabels[actualDifficulty]})"); }

      _solutionBoard = List.generate(kGridSize, (_) => List.generate(kGridSize, (_) => null));
      // Try to generate a solvable board first
      if (!_generateSolvedBoard(_solutionBoard)) {
         if (kDebugMode) print("Error: Failed to generate a solved Sudoku board.");
         _isPuzzleLoaded = false; // Ensure it's false on failure
         _currentPuzzleDifficulty = null;
         _initialDifficultySelection = null;
         _currentPuzzleString = null;
         _hintsUsed = 0; // Reset hints on failure
         notifyListeners();
         return;
      }

      // Then create the puzzle by removing cells
      var puzzleResult = _createUniquePuzzleFromSolvedBoard(_solutionBoard, actualDifficulty);
      if (puzzleResult == null) {
         if (kDebugMode) print("Error: Failed to create a unique puzzle. Retrying might be needed or fallback.");
         _isPuzzleLoaded = false; // Ensure it's false on failure
         _currentPuzzleDifficulty = null;
         _initialDifficultySelection = null;
         _currentPuzzleString = null;
         _hintsUsed = 0; // Reset hints on failure
         notifyListeners();
         return;
      }
      _board = puzzleResult;
      _isPuzzleLoaded = true;

      // Reset other game state variables
      _isCompleted = false;
      _isPaused = false;
      _selectedRow = null;
      _selectedCol = null;
      _isEditingCandidates = false;
      _history.clear();
      _hintsUsed = 0; // Reset hint counter for NEW game

      // Now generate and store the puzzle string AFTER resetting hints
      _generateAndStorePuzzleString();

      resetTimer();
      startTimer();
      _runIntroNumberAnimation = false;

      // Notify listeners about the new game state
      notifyListeners();
  }

  // Helper to generate and store the puzzle string
  // UPDATED: Format includes hints: DifficultyChar:HintsUsed:BoardString
  void _generateAndStorePuzzleString() {
    if (!_isPuzzleLoaded || _board.isEmpty) {
      if (kDebugMode) print("Debug: Exiting _generateAndStorePuzzleString early (puzzle not loaded or board empty). Setting string to null.");
      _currentPuzzleString = null;
      return;
    }

    StringBuffer sb = StringBuffer();
    String difficultyChar = 'M'; // Default to Medium
    if (_currentPuzzleDifficulty != null && difficultyLabels.containsKey(_currentPuzzleDifficulty)) {
        String label = difficultyLabels[_currentPuzzleDifficulty]!;
        if (label.isNotEmpty) {
          difficultyChar = label[0].toUpperCase(); // Ensure uppercase
        }
    } else if (_currentPuzzleDifficulty == -1) {
        difficultyChar = 'R'; // Explicitly handle Random
    }

    // Append Difficulty:Hints:
    sb.write('$difficultyChar:$_hintsUsed:');

    try {
      for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
          final cell = _board[r][c];
          // Fixed cells (original puzzle) contribute their number (1-9)
          if (cell.isFixed && cell.value != null) {
            sb.write('${cell.value! + 1}');
          }
          // Empty cells or user-filled cells contribute '0' to the base puzzle string
          else {
            sb.write('0');
          }
        }
      }
      _currentPuzzleString = sb.toString();
      if (kDebugMode) print('Debug: Generated Puzzle String (Diff:Hints:Board): $_currentPuzzleString');
    } catch (e) {
        if (kDebugMode) print("Error during puzzle string generation loop: $e");
        _currentPuzzleString = null; // Set to null on error
    }
  }

  // Method to load a puzzle from a string
  // UPDATED: Expects format DifficultyChar:HintsUsed:BoardString
  Future<bool> loadPuzzleFromString(String puzzleString) async {
    if (kDebugMode) print("Attempting to load puzzle from string: $puzzleString");
    // Basic format check: must have at least two colons and enough length
    final parts = puzzleString.split(':');
    if (parts.length < 3 || parts[0].isEmpty || parts[1].isEmpty || parts[2].isEmpty) {
       if (kDebugMode) print("Error: Invalid puzzle string format (Expected D:H:B). String: '$puzzleString'");
       return false;
    }

    String diffChar = parts[0].toUpperCase();
    String hintsString = parts[1];
    String boardString = parts[2];

    // Validate Difficulty Character
    int? difficulty;
    difficultyLabels.forEach((key, label) {
       if (label.isNotEmpty && label[0].toUpperCase() == diffChar) {
           difficulty = key;
       }
    });
    // Explicitly check for 'R' after the map iteration
    if (diffChar == 'R') difficulty = -1;

    if (difficulty == null) {
        if (kDebugMode) print("Error: Invalid difficulty character '$diffChar'.");
        return false;
    }

    // Validate Hints Number
    int? initialHintsUsed = int.tryParse(hintsString);
    if (initialHintsUsed == null || initialHintsUsed < 0) {
      if (kDebugMode) print("Error: Invalid hints value '$hintsString'. Must be a non-negative integer.");
      return false;
    }

    // Validate Board String Length
    if (boardString.length != kGridSize * kGridSize) {
        if (kDebugMode) print("Error: Incorrect board string length. Expected ${kGridSize * kGridSize}, got ${boardString.length}.");
        return false;
    }

    // 1. Create the initial board from the string
    List<List<SudokuCellData>> initialBoard = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) => SudokuCellData(value: null, isFixed: false)));
    List<List<int?>> boardForSolving = List.generate(kGridSize, (_) => List.generate(kGridSize, (_) => null));

    try {
      for (int i = 0; i < boardString.length; i++) {
         int r = i ~/ kGridSize;
         int c = i % kGridSize;
         String char = boardString[i];
         int? value;
         bool isFixed = false;

         if (char != '0') {
           value = int.tryParse(char);
           if (value != null && value >= 1 && value <= kGridSize) { // Use kGridSize
             value = value - 1; // Adjust to 0-based index
             isFixed = true;
             boardForSolving[r][c] = value; // Populate board for solver
           } else {
             throw FormatException("Invalid character '$char' (value ${value}) at index $i in board string.");
           }
         }
         // Create SudokuCellData with parsed value and fixed status
         initialBoard[r][c] = SudokuCellData(value: value, isFixed: isFixed);
      }
    } catch (e) {
       if (kDebugMode) print("Error parsing board string part: $e");
       return false;
    }

    // 2. Solve the puzzle string to get the solution
    List<List<int?>> boardToSolveClone = List.generate(kGridSize, (r) => List.from(boardForSolving[r]));

    if (!_solveBoard(boardToSolveClone)) {
       if (kDebugMode) print("Error: Could not find a unique solution for the shared puzzle string.");
       // It's possible the shared string represents an invalid/unsolvable puzzle.
       // We still load it, but the user might get stuck or hints won't work correctly.
       // For now, we proceed but clear the internal solution board.
       _solutionBoard = List.generate(kGridSize, (_) => List.generate(kGridSize, (_) => null));
    } else {
        // Store the found solution
       _solutionBoard = List.generate(kGridSize, (r) => List<int?>.from(boardToSolveClone[r]), growable: false);
       if (kDebugMode) print("Successfully solved the base puzzle for solution storage.");
    }

    // 3. Set up game state
    _board = initialBoard;
    _currentPuzzleDifficulty = difficulty;
    _initialDifficultySelection = difficulty; // Store the difficulty from the string
    _isPuzzleLoaded = true;
    _isCompleted = false; // Loaded game is not completed initially
    _isPaused = false;
    _selectedRow = null;
    _selectedCol = null;
    _isEditingCandidates = false;
    _history.clear(); // Clear history for a newly loaded game
    _hintsUsed = initialHintsUsed; // Set hints used from the loaded string
    _currentPuzzleString = puzzleString; // Store the original loaded string

    // Reset and start the timer for the loaded game
    resetTimer();
    startTimer();
    _runIntroNumberAnimation = false; // Don't run intro animation for loaded games

    notifyListeners();
    if (kDebugMode) print("Successfully loaded puzzle from string. Difficulty: ${difficultyLabels[difficulty]}, Hints Used (from string): $initialHintsUsed");
    return true;
  }


  // --- NEW: Dedicated solver function (reuses logic from _generateSolvedBoard) ---
  // Takes a partially filled board (null for empty) and fills it if a unique solution exists.
  // Returns true if a solution was found, false otherwise. Modifies board in place.
  bool _solveBoard(List<List<int?>> board) {
    int? row, col;
    bool foundEmpty = false;
    for (row = 0; row! < kGridSize; row++) {
      for (col = 0; col! < kGridSize; col++) {
        if (board[row][col] == null) {
          foundEmpty = true;
          break;
        }
      }
      if (foundEmpty) break;
    }

    // Base case: If no empty cell, board is solved (or was already full)
    if (!foundEmpty) return true;

    // Try numbers 0-8 (can shuffle for potential efficiency, but order doesn't affect correctness)
    List<int> nums = List.generate(kGridSize, (i) => i)..shuffle(_random); // Shuffle for generation
    for (int n in nums) { // Using 0..8 directly is fine
      if (_isValidPlacementInternal(board, row!, col!, n)) {
        board[row][col] = n; // Try placing number

        // Recurse: If this placement leads to a solution, return true
        if (_solveBoard(board)) {
          return true;
        }

        // Backtrack: If it didn't lead to a solution, reset cell
        board[row][col] = null;
      }
    }

    // If no number worked in this cell, return false (triggering backtracking)
    return false;
  }


  // --- Methods to control intro animation flag (Unchanged) ---
  void triggerIntroNumberAnimation() {
    if (!_runIntroNumberAnimation) {
      _runIntroNumberAnimation = true;
      notifyListeners();
    }
  }

  void resetIntroNumberAnimation() {
    if (_runIntroNumberAnimation) {
      _runIntroNumberAnimation = false;
      // No need to notify listeners typically, as this is usually called internally
      // or when the animation naturally ends. If external state depends on it, uncomment:
      // notifyListeners();
    }
  }

  // --- _generateSolvedBoard (Used for initial generation seeding) ---
  bool _generateSolvedBoard(List<List<int?>> board) {
    int? row, col; bool foundEmpty=false;
    // Find first empty cell (null)
    for(row=0; row!<kGridSize; row++){for(col=0; col!<kGridSize; col++){if(board[row][col]==null){foundEmpty=true; break;}}if(foundEmpty)break;}
    // Base case: If no empty cell, board is solved
    if(!foundEmpty)return true;
    // Try numbers 0-8 in shuffled order
    List<int> nums=List.generate(kGridSize,(i)=>i)..shuffle(_random);
    for(int n in nums){
      if(_isValidPlacementInternal(board,row!,col!,n)){ // Check if placement is valid
        board[row][col]=n; // Place number
        if(_generateSolvedBoard(board)) return true; // Recurse: If it leads to a solution, done!
        board[row][col]=null; // Backtrack: If not, reset cell and try next number
      }
    }
    // If no number worked for this cell, return false (triggers backtracking up the stack)
    return false;
  }

  // --- _createUniquePuzzleFromSolvedBoard ---
  List<List<SudokuCellData>>? _createUniquePuzzleFromSolvedBoard(List<List<int?>> solvedBoard, int actualDifficulty) {
      int cellsToRemove;
      switch (actualDifficulty) {
          case 0: cellsToRemove = kDifficultyEasyCellsToRemove; break;
          case 1: cellsToRemove = kDifficultyMediumCellsToRemove; break;
          case 2: cellsToRemove = kDifficultyHardCellsToRemove; break;
          case 3: cellsToRemove = kDifficultyPainfulCellsToRemove; break;
          default: cellsToRemove = kDifficultyMediumCellsToRemove;
      }
      cellsToRemove = min(cellsToRemove, 60); // Limit removals for stability

      // Start with a copy of the solved board state
      List<List<int?>> currentPuzzleState = List.generate(kGridSize, (r) => List.from(solvedBoard[r]));
      // Create the data structure for the final puzzle
      List<List<SudokuCellData>> puzzleBoardData = List.generate(kGridSize,
         (r) => List.generate(kGridSize, (c) => SudokuCellData(value: solvedBoard[r][c], isFixed: true))
      );


      int removedCount = 0;
      int attempts = 0;
      final int maxTotalAttempts = kGridSize * kGridSize * 3; // Increase attempts slightly?
      List<int> cellIndices = List.generate(kGridSize * kGridSize, (i) => i)..shuffle(_random);

      for (int index in cellIndices) {
          if (removedCount >= cellsToRemove || attempts >= maxTotalAttempts) break;
          attempts++;

          int r = index ~/ kGridSize;
          int c = index % kGridSize;

          if (currentPuzzleState[r][c] == null) continue; // Already removed

          int? tempValue = currentPuzzleState[r][c];
          currentPuzzleState[r][c] = null; // Try removing

          // Create a copy for the solver, as it modifies the board
          List<List<int?>> boardToCheck = List.generate(kGridSize, (row) => List.from(currentPuzzleState[row]));
          int solutionCount = _countSolutions(boardToCheck); // Check solutions on the copy

          if (solutionCount == 1) {
              removedCount++; // Keep removed if still unique
          } else {
              currentPuzzleState[r][c] = tempValue; // Put it back if not unique
          }
      }

      if (kDebugMode) print("Puzzle Generation: Target removals: $cellsToRemove, Actual removals: $removedCount, Attempts: $attempts");

      // If removedCount is significantly less than cellsToRemove, log a warning maybe?
      if (removedCount < cellsToRemove * 0.8 && cellsToRemove > 10) { // Arbitrary threshold
         if (kDebugMode) print("Warning: Fewer cells removed ($removedCount) than targeted ($cellsToRemove). Puzzle might be easier.");
      }

      // Final board construction based on remaining values in currentPuzzleState
      for (int r = 0; r < kGridSize; r++) {
         for (int c = 0; c < kGridSize; c++) {
            if (currentPuzzleState[r][c] != null) {
               puzzleBoardData[r][c] = SudokuCellData(value: currentPuzzleState[r][c], isFixed: true);
            } else {
               puzzleBoardData[r][c] = SudokuCellData(value: null, isFixed: false);
            }
         }
      }
      return puzzleBoardData; // Return the board with removed cells
  }


  // --- _countSolutions (Crucial for puzzle generation uniqueness check) ---
  int _countSolutions(List<List<int?>> board) {
    int? row, col;
    bool foundEmpty = false;
    // Find the first empty cell
    for (row = 0; row! < kGridSize; row++) {
      for (col = 0; col! < kGridSize; col++) {
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
    // Try placing numbers 0-8 in the empty cell
    for (int num = 0; num < kGridSize; num++) {
      if (_isValidPlacementInternal(board, row!, col!, num)) {
        board[row][col] = num; // Place number
        count += _countSolutions(board); // Recursively count solutions from here
        board[row][col] = null; // Backtrack: remove number

        // Optimization: If we already found more than one solution, stop early
        if (count > 1) {
          return count; // Return 2 (or more) to indicate non-uniqueness
        }
      }
    }
    return count; // Return the total count found (0, 1, or possibly more if optimization is removed)
  }


  // --- _isValidPlacementInternal (Checks row, col, box) ---
  bool _isValidPlacementInternal(List<List<int?>> board, int row, int col, int num) {
     // Check row
     for(int c=0; c<kGridSize; c++){ if(board[row][c] == num) return false; }
     // Check column
     for(int r=0; r<kGridSize; r++){ if(board[r][col] == num) return false; }
     // Check 3x3 box
     int startRow=(row~/kBoxSize)*kBoxSize;
     int startCol=(col~/kBoxSize)*kBoxSize;
     for(int r=0; r<kBoxSize; r++){
       for(int c=0; c<kBoxSize; c++){
         if(board[startRow+r][startCol+c] == num) return false;
       }
     }
     // If no conflicts, placement is valid
     return true;
  }

  // --- isValidPlacementForCell (Checks validity for UI feedback, excluding the cell itself) ---
  bool isValidPlacementForCell(int row, int col, int num) {
      List<List<int?>> tempBoard = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) => _board[r][c].value));
      tempBoard[row][col] = null; // Temporarily empty the cell to check against others
      return _isValidPlacementInternal(tempBoard, row, col, num);
  }


  // --- updateBoardErrors (Updates error state for all non-fixed cells) ---
  void updateBoardErrors(bool showErrors) {
     bool errorStateChanged = false;
     for(int r=0; r<kGridSize; r++){
       for(int c=0; c<kGridSize; c++){
         SudokuCellData cell = _board[r][c];
         int? cellValue = cell.value;
         bool previousError = cell.hasError;

         if(cellValue == null || cell.isFixed){
           cell.hasError = false; // Fixed cells or empty cells cannot have errors this way
         } else {
           // Check if the current value is valid considering other cells
           cell.hasError = !isValidPlacementForCell(r, c, cellValue);
         }

         if(previousError != cell.hasError) {
           errorStateChanged = true;
         }
       }
     }
     // Notify only if error state actually changed, respecting the showErrors flag
     if (errorStateChanged) {
        notifyListeners();
     }
     // Note: If showErrors is false, errors are calculated but not necessarily shown by the UI.
     // The notification here ensures the internal state is updated for logic that might depend on it.
  }

  // --- _isBoardStateValid (Checks if the entire board follows Sudoku rules) ---
  bool _isBoardStateValid(List<List<SudokuCellData>> boardData) {
     // Create a temporary board with just the values
     List<List<int?>> boardValues = List.generate(kGridSize, (r) => List.generate(kGridSize, (c) {
        // Use a placeholder like -1 for null to distinguish from valid 0 index if needed by validator
        // However, _isValidPlacementInternal handles null correctly for empty checks.
        return boardData[r][c].value;
     }));

     for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
           int? currentValue = boardValues[r][c];
           // If a cell has a value, temporarily remove it and check if it was valid
           if (currentValue != null) {
              boardValues[r][c] = null; // Temporarily remove
              if (!_isValidPlacementInternal(boardValues, r, c, currentValue)) {
                 return false; // Found an invalid placement
              }
              boardValues[r][c] = currentValue; // Put it back for subsequent checks
           }
        }
     }
     // If all cells with values are validly placed
     return true;
  }

   // --- _isBoardCompleteAndCorrect (Checks if board is full and valid) ---
   bool _isBoardCompleteAndCorrect() {
       // Check if all cells are filled
       for(int r=0; r<kGridSize; r++){
          for(int c=0; c<kGridSize; c++){
             if(_board[r][c].value == null) return false; // Found an empty cell
          }
       }
       // If all cells are filled, check if the state is valid
       return _isBoardStateValid(_board);
   }


   // --- provideHint (UPDATED to track hints and regenerate puzzle string) ---
    bool provideHint({required bool showErrors}) {
      if (_selectedRow != null && _selectedCol != null && !_isCompleted) {
        final cell = _board[_selectedRow!][_selectedCol!];
        // Can only provide hint for non-fixed, empty cells
        if (!cell.isFixed && cell.value == null) {
          // Get the correct value from the stored solution
          if (_solutionBoard.isEmpty || _selectedRow! >= _solutionBoard.length || _selectedCol! >= _solutionBoard[_selectedRow!].length) {
             if (kDebugMode) print("Error: Solution board not available or invalid dimensions for hint at [$_selectedRow, $_selectedCol]");
             return false; // Cannot provide hint if solution isn't valid
          }
          int? solutionValue = _solutionBoard[_selectedRow!][_selectedCol!];

          if (solutionValue != null) {
            _saveStateToHistory(); // Save state before applying hint
            cell.value = solutionValue;
            cell.candidates.clear(); // Clear candidates as value is now known
            cell.isHint = true; // Mark the cell as hinted
            _hintsUsed++; // <<< INCREMENT HINT COUNTER
            _generateAndStorePuzzleString(); // <<< REGENERATE STRING WITH NEW HINT COUNT
            updateBoardErrors(showErrors); // Update errors after placing hint

            // Check if the hint completed the puzzle
            if (_isBoardCompleteAndCorrect()) {
              _isCompleted = true;
              stopTimer();
              if (kDebugMode) print("Game Completed via Hint!");
            } else {
              _isCompleted = false; // Ensure completion status is correct
            }
             notifyListeners();
             return true; // Hint provided successfully
          } else {
             if (kDebugMode) print("Error: Solution value not found for hint at [$_selectedRow, $_selectedCol]");
          }
        }
      }
      return false; // Hint not provided
    }

  // --- Cell Interaction ---
  void selectCell(int row, int col) {
      if (_selectedRow == row && _selectedCol == col) {
        // Deselect if tapping the same cell
        _selectedRow = null;
        _selectedCol = null;
      } else {
        _selectedRow = row;
        _selectedCol = col;
      }
      notifyListeners();
  }

  void placeValue(int colorIndex, {required bool showErrors}) {
      if(_selectedRow != null && _selectedCol != null && !_isCompleted){
        final cell = _board[_selectedRow!][_selectedCol!];
        // Can only place values in non-fixed cells
        if (!cell.isFixed) {
           _saveStateToHistory(); // Save state before changing value/candidates

           if (_isEditingCandidates) {
              // --- Candidate Mode ---
              if (cell.value != null) {
                 // Clear main value if switching to candidates on a filled cell
                 cell.value = null;
                 cell.isHint = false; // Clearing value removes hint status
              }
              // Toggle candidate
              if (cell.candidates.contains(colorIndex)) {
                cell.candidates.remove(colorIndex);
              } else {
                // Optional: Limit number of candidates?
                cell.candidates.add(colorIndex);
              }
           } else {
              // --- Value Mode ---
              // Clear candidates when placing a main value
              cell.candidates.clear();
              // Toggle value: if same value is tapped, clear cell; otherwise, set value
              if (cell.value == colorIndex) {
                 cell.value = null;
                 cell.isHint = false; // Clearing value removes hint status
              } else {
                 cell.value = colorIndex;
                 cell.isHint = false; // User action overwrites hint status
              }
           }

           updateBoardErrors(showErrors); // Update errors after change

           // Check for completion
           if (_isBoardCompleteAndCorrect()) {
             _isCompleted = true;
             stopTimer();
             if (kDebugMode) print("Game Completed!");
           } else {
             _isCompleted = false; // Ensure completion status is correct
           }
           notifyListeners();
        }
      }
  }

  void toggleEditMode() {
      _isEditingCandidates=!_isEditingCandidates;
      notifyListeners();
  }

  void eraseSelectedCell({required bool showErrors}) {
      if(_selectedRow!=null && _selectedCol!=null && !_isCompleted){
        final cell=_board[_selectedRow!][_selectedCol!];
        // Can only erase non-fixed cells
        if (!cell.isFixed) {
           // Only save history if something actually changes
           if (cell.value != null || cell.candidates.isNotEmpty) {
             _saveStateToHistory();
             cell.value = null;
             cell.candidates.clear();
             cell.isHint = false; // Erasing removes hint status
             updateBoardErrors(showErrors); // Update errors after erasing
             notifyListeners();
           }
        }
      }
  }

  // --- Back/Undo ---
  void _saveStateToHistory() {
    // Create a deep copy of the board state
    List<List<SudokuCellData>> boardCopy = List.generate(kGridSize,
       (r)=>List.generate(kGridSize,(c)=>_board[r][c].clone()) // Use clone method
    );
    _history.add(boardCopy);
    // Limit history size
    if(_history.length > _maxHistory){
      _history.removeAt(0);
    }
  }

  void performUndo({required bool showErrors}) {
      if(_history.isNotEmpty){
        // --- Store hints *before* restoring board state ---
        final int previousHintsUsed = _hintsUsed;

        _board = _history.removeLast(); // Restore previous board state

        // --- Recalculate hints used from the restored board state ---
        int recalculatedHints = 0;
        for(int r=0; r<kGridSize; r++){
          for(int c=0; c<kGridSize; c++){
            if(_board[r][c].isHint) {
               recalculatedHints++;
            }
          }
        }
        _hintsUsed = recalculatedHints;

        // --- Regenerate puzzle string if hints changed ---
        if (_hintsUsed != previousHintsUsed) {
            _generateAndStorePuzzleString();
            if (kDebugMode) print("Undo changed hint count from $previousHintsUsed to $_hintsUsed. Regenerated puzzle string.");
        }

        updateBoardErrors(showErrors); // Update errors for the restored state
        _isCompleted = _isBoardCompleteAndCorrect(); // Re-check completion status

        if(_isCompleted){
          stopTimer(); // Stop timer if undo resulted in completion
        } else if (!_isPaused && (_timer == null || !_timer!.isActive)) {
          // Restart timer if game was running and isn't completed/paused now
          startTimer();
        }
        notifyListeners();
      } else {
        if(kDebugMode) print("Undo history is empty.");
        // Optional: Show a snackbar to the user?
      }
  }


  // --- Timer Control ---
   void startTimer() {
       if (_timer != null && _timer!.isActive) return; // Already running
       if (_isCompleted) return; // Don't start if already completed

       _timer = Timer.periodic(kTimerUpdateInterval, (timer) {
          if (!_isPaused && !_isCompleted) {
            _elapsedTime += kTimerUpdateInterval;
            notifyListeners(); // Notify TimerWidget to update display
          } else {
             // Stop the timer if paused or completed during the interval
             timer.cancel();
             _timer = null;
          }
       });
   }
   void pauseTimer(){
      if (!_isPaused) {
         _isPaused = true;
         _timer?.cancel(); // Stop the timer ticks
         _timer = null;
         notifyListeners(); // Notify UI about pause state change
      }
   }
   void resumeTimer(){
      if (_isPaused && !_isCompleted) {
         _isPaused = false;
         startTimer(); // Restart the timer
         notifyListeners(); // Notify UI about resume state change
      }
   }
   void stopTimer(){
      _timer?.cancel();
      _timer = null;
      // Optionally notify listeners if UI depends on timer being null/stopped explicitly
      // notifyListeners();
   }
   void resetTimer(){
      stopTimer();
      _elapsedTime=Duration.zero;
      notifyListeners(); // Notify UI about reset time
   }
   void pauseGame(){ // External action to pause
      pauseTimer();
      // Optionally add other pause logic (e.g., overlay)
   }
   void resumeGame(){ // External action to resume
      resumeTimer();
      // Optionally add other resume logic
   }

  // --- Palette Dimming Helpers ---
  bool isColorGloballyComplete(int colorIndex) {
     if (!_isPuzzleLoaded || _solutionBoard.isEmpty || _board.isEmpty) return false;
     int solutionCount = 0;
     int boardCorrectCount = 0;
     for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
           // Count occurrences in the definitive solution
           if (r < _solutionBoard.length && c < _solutionBoard[r].length && _solutionBoard[r][c] == colorIndex) {
              solutionCount++;
           }
           // Count occurrences in the current board that are correctly placed
           if (_board[r][c].value == colorIndex && !_board[r][c].hasError) {
              boardCorrectCount++;
           }
        }
     }
     // The color is complete if it appears kGridSize times (expected for Sudoku)
     // in the solution AND the user has placed all of them correctly on the board.
     // Use solutionCount > 0 check for safety if solution board failed loading
     return (solutionCount > 0 && solutionCount == boardCorrectCount) || (solutionCount == kGridSize && boardCorrectCount == kGridSize) ;
  }


  bool isColorUsedInSelectionContext(int colorIndex, int row, int col) {
      if (!_isPuzzleLoaded || _board.isEmpty) return false;
      // Check Row
      for (int c = 0; c < kGridSize; c++) { if (_board[row][c].value == colorIndex) return true; }
      // Check Column
      for (int r = 0; r < kGridSize; r++) { if (_board[r][col].value == colorIndex) return true; }
      // Check 3x3 Box
      int startRow = (row ~/ kBoxSize) * kBoxSize;
      int startCol = (col ~/ kBoxSize) * kBoxSize;
      for (int r = 0; r < kBoxSize; r++) {
         for (int c = 0; c < kBoxSize; c++) {
            if (_board[startRow + r][startCol + c].value == colorIndex) return true;
         }
      }
      // Color not found in the selection's row, column, or box
      return false;
  }

  @override
  void dispose() {
    stopTimer(); // Ensure timer is cancelled when provider is disposed
    super.dispose();
  }
}