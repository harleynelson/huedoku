// File: lib/widgets/sudoku_grid_widget.dart
// Location: lib/widgets/sudoku_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/widgets/sudoku_cell_widget.dart';
import 'package:provider/provider.dart';

class SudokuGridWidget extends StatelessWidget {
  const SudokuGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use context.watch as a simple way to rebuild grid if puzzleLoaded changes
    // For more complex state, select might be needed, but this is likely fine.
    final bool isPuzzleLoaded = context.watch<GameProvider>().isPuzzleLoaded;

    if (!isPuzzleLoaded) {
      // Use const for efficiency
      return const Center(child: CircularProgressIndicator());
    }

    final currentTheme = Theme.of(context);
    final Color lineColor = currentTheme.colorScheme.onSurface;

    final BorderSide thickBorder = BorderSide( color: lineColor.withOpacity(0.25), width: 1.0, );
    final BorderSide thinBorder = BorderSide( color: lineColor.withOpacity(0.12), width: 0.6, );
    const BorderSide noBorder = BorderSide.none; // Make const

    final Color outerBorderColor = lineColor.withOpacity(0.35);
    final double outerBorderWidth = 1.5;
    const double gridCornerRadius = 8.0; // Make const

    return Container(
      // Use const EdgeInsets
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        border: Border.all(color: outerBorderColor, width: outerBorderWidth),
        // Use const BorderRadius
        borderRadius: const BorderRadius.all(Radius.circular(gridCornerRadius)),
      ),
      // --- Wrap GridView in RepaintBoundary ---
      child: RepaintBoundary(
        child: ClipRRect(
          // Use const BorderRadius, subtract padding
          borderRadius: const BorderRadius.all(Radius.circular(gridCornerRadius - 2.0)),
          child: GridView.builder(
            // Use const EdgeInsets
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              int row = index ~/ 9;
              int col = index % 9;

              // Border logic remains the same
              final BorderSide topSide = (row == 0) ? noBorder : (row % 3 == 0) ? thickBorder : thinBorder;
              final BorderSide leftSide = (col == 0) ? noBorder : (col % 3 == 0) ? thickBorder : thinBorder;
              final BorderSide rightSide = (col == 8) ? noBorder : ((col + 1) % 3 == 0) ? thickBorder : thinBorder;
              final BorderSide bottomSide = (row == 8) ? noBorder : ((row + 1) % 3 == 0) ? thickBorder : thinBorder;
              final Border cellBorder = Border( top: topSide, left: leftSide, right: rightSide, bottom: bottomSide, );

              // Add const keyword if SudokuCellWidget constructor allows (it should)
              // Pass row/col directly, no need for complex state here
              return Container(
                decoration: BoxDecoration(border: cellBorder),
                // --- Key optimization: Use key for cell state persistence ---
                // Using ValueKey helps Flutter identify which cell is which during rebuilds,
                // especially important when wrapping with RepaintBoundary.
                child: SudokuCellWidget(key: ValueKey('cell_$row-$col'), row: row, col: col),
              );
            },
          ),
        ),
      ),
      // --- End RepaintBoundary ---
    );
  }
}