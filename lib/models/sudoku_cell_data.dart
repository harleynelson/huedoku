// File: lib/models/sudoku_cell_data.dart
// Location: ./lib/models/sudoku_cell_data.dart

import 'package:flutter/material.dart';

// Represents the state of a single cell in the Sudoku grid
class SudokuCellData {
  int? value; // The index (0-8) of the color in the palette, null if empty
  final bool isFixed; // Was this cell part of the initial puzzle?
  Set<int> candidates; // Potential color indices (like pencil marks)
  bool hasError; // Does this cell violate Sudoku rules?
  // --- New field ---
  bool isHint; // Was this cell's value revealed by a hint?

  SudokuCellData({
    this.value,
    this.isFixed = false,
    Set<int>? candidates,
    this.hasError = false,
    this.isHint = false, // Default to false
  }) : candidates = candidates ?? {}; // Initialize with empty set if null

  // Helper to get the actual color from a palette
  Color? getColor(List<Color> palette) {
    if (value != null && value! >= 0 && value! < palette.length) {
      return palette[value!];
    }
    return null; // Return null if cell is empty or value is invalid
  }

  // Clone method updated to include isHint
  SudokuCellData clone() {
    return SudokuCellData(
      value: value,
      isFixed: isFixed,
      candidates: Set<int>.from(candidates), // Create a copy of the set
      hasError: hasError,
      isHint: isHint, // Copy hint status
    );
  }
}