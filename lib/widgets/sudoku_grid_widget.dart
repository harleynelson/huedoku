// File: lib/widgets/sudoku_grid_widget.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/widgets/sudoku_cell_widget.dart';
import 'package:provider/provider.dart';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

class SudokuGridWidget extends StatelessWidget {
  const SudokuGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isPuzzleLoaded = context.watch<GameProvider>().isPuzzleLoaded;

    if (!isPuzzleLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentTheme = Theme.of(context);
    final Color lineColor = currentTheme.colorScheme.onSurface;

    // --- UPDATED: Use constants for borders/opacities ---
    final BorderSide thickBorder = BorderSide( color: lineColor.withOpacity(0.25), width: kThickGridBorderWidth, ); // Keep specific opacity or make constant
    final BorderSide thinBorder = BorderSide( color: lineColor.withOpacity(0.12), width: kThinGridBorderWidth, ); // Keep specific opacity or make constant
    const BorderSide noBorder = BorderSide.none;

    // --- UPDATED: Use constants for border/radius ---
    final Color outerBorderColor = lineColor.withOpacity(0.35); // Keep specific opacity or make constant
    const double outerBorderWidth = kOuterGridBorderWidth;
    const double gridCornerRadius = kGridCornerRadius;

    return Container(
      // --- UPDATED: Use constant for padding ---
      padding: const EdgeInsets.all(kGridPadding),
      decoration: BoxDecoration(
        border: Border.all(color: outerBorderColor, width: outerBorderWidth),
        borderRadius: const BorderRadius.all(Radius.circular(gridCornerRadius)),
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          // --- UPDATED: Use constant for radius/padding ---
          borderRadius: const BorderRadius.all(Radius.circular(gridCornerRadius - kGridPadding)),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            // --- UPDATED: Use constant for grid size ---
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kGridSize,
            ),
            itemCount: kGridSize * kGridSize, // Use constant
            itemBuilder: (context, index) {
              // --- UPDATED: Use constants for grid/box size ---
              int row = index ~/ kGridSize;
              int col = index % kGridSize;

              final BorderSide topSide = (row == 0) ? noBorder : (row % kBoxSize == 0) ? thickBorder : thinBorder;
              final BorderSide leftSide = (col == 0) ? noBorder : (col % kBoxSize == 0) ? thickBorder : thinBorder;
              final BorderSide rightSide = (col == kGridSize - 1) ? noBorder : ((col + 1) % kBoxSize == 0) ? thickBorder : thinBorder;
              final BorderSide bottomSide = (row == kGridSize - 1) ? noBorder : ((row + 1) % kBoxSize == 0) ? thickBorder : thinBorder;
              final Border cellBorder = Border( top: topSide, left: leftSide, right: rightSide, bottom: bottomSide, );

              return Container(
                decoration: BoxDecoration(border: cellBorder),
                child: SudokuCellWidget(key: ValueKey('cell_$row-$col'), row: row, col: col),
              );
            },
          ),
        ),
      ),
    );
  }
}