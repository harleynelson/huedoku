// File: lib/widgets/sudoku_grid_widget.dart
// Location: ./lib/widgets/sudoku_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/widgets/sudoku_cell_widget.dart';
import 'package:provider/provider.dart';

class SudokuGridWidget extends StatelessWidget {
  const SudokuGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to react to changes in the game board
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (!gameProvider.isPuzzleLoaded) {
          return const Center(child: CircularProgressIndicator()); // Show progress indicator while loading
        }

        // Get current theme for line colors
        final currentTheme = Theme.of(context);
        final Color lineColor = currentTheme.colorScheme.onSurface; // Base color from theme

        // --- Define Subtle Border Styles ---
        // Further reduced thick border width to minimize perceived differences
        final BorderSide thickBorder = BorderSide(
          color: lineColor.withOpacity(0.25),
          width: 1.0, // Reduced width to 1.0
        );
        final BorderSide thinBorder = BorderSide(
          color: lineColor.withOpacity(0.12),
          width: 0.6,
        );
        const BorderSide noBorder = BorderSide.none;

        // --- Outer Grid Border ---
        final Color outerBorderColor = lineColor.withOpacity(0.35);
        final double outerBorderWidth = 1.5;
        final double gridCornerRadius = 8.0;

        return Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            border: Border.all(color: outerBorderColor, width: outerBorderWidth),
            borderRadius: BorderRadius.circular(gridCornerRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(gridCornerRadius - 2.0),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                int row = index ~/ 9;
                int col = index % 9;

                // --- Corrected Border Logic ---
                final BorderSide topSide = (row == 0)
                    ? noBorder
                    : (row % 3 == 0) ? thickBorder : thinBorder;

                final BorderSide leftSide = (col == 0)
                    ? noBorder
                    : (col % 3 == 0) ? thickBorder : thinBorder;

                final BorderSide rightSide = (col == 8)
                    ? noBorder
                    // Apply thick border condition to the *left* edge of the *next* column (col+1)
                    : ((col + 1) % 3 == 0) ? thickBorder : thinBorder;

                final BorderSide bottomSide = (row == 8)
                    ? noBorder
                    // Apply thick border condition to the *top* edge of the *next* row (row+1)
                    : ((row + 1) % 3 == 0) ? thickBorder : thinBorder;

                // Construct the Border object
                final Border cellBorder = Border(
                  top: topSide,
                  left: leftSide,
                  right: rightSide,
                  bottom: bottomSide,
                );

                return Container(
                  decoration: BoxDecoration(border: cellBorder),
                  child: SudokuCellWidget(row: row, col: col),
                );
              },
            ),
          ),
        );
      },
    );
  }
}