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
          return const Center(child: Text("Loading puzzle...")); // Or a progress indicator
        }

        // Determine border thickness for subgrids
        BorderSide thickBorder = BorderSide(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600]! : Colors.black54,
          width: 1.5,
        );
        BorderSide thinBorder = BorderSide(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.black26,
          width: 0.5,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500]! : Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8), // Optional: rounded corners for the whole grid
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero, // Remove default padding
            physics: const NeverScrollableScrollPhysics(), // Grid shouldn't scroll independently
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9, // 9 cells horizontally
            ),
            itemCount: 81, // 9x9 grid
            itemBuilder: (context, index) {
              int row = index ~/ 9;
              int col = index % 9;

              // Determine borders for the 3x3 subgrids
              Border cellBorder = Border(
                top: row % 3 == 0 ? thickBorder : thinBorder,
                left: col % 3 == 0 ? thickBorder : thinBorder,
                right: col == 8 ? thickBorder : thinBorder, // Thick on outer edges
                bottom: row == 8 ? thickBorder : thinBorder, // Thick on outer edges
              );

              // Special handling for internal thick borders
              if (row % 3 == 2 && row != 8) { // bottom edge of a subgrid row (not the last row)
                 cellBorder = Border(
                    top: thinBorder, left: cellBorder.left, right: cellBorder.right,
                    bottom: thickBorder);
              }
               if (col % 3 == 2 && col != 8) { // right edge of a subgrid col (not the last col)
                 cellBorder = Border(
                   top: cellBorder.top, bottom: cellBorder.bottom, left: thinBorder,
                   right: thickBorder);
              }


              return Container(
                decoration: BoxDecoration(border: cellBorder),
                child: SudokuCellWidget(row: row, col: col),
              );
            },
          ),
        );
      },
    );
  }
}