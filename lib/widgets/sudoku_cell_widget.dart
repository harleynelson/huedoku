// File: lib/widgets/sudoku_cell_widget.dart
// Location: ./lib/widgets/sudoku_cell_widget.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart'; // Import the painter
import 'package:provider/provider.dart';
import 'dart:math'; // Import for min function

class SudokuCellWidget extends StatelessWidget {
  final int row;
  final int col;

  const SudokuCellWidget({
    super.key,
    required this.row,
    required this.col,
  });

    // File: lib/widgets/sudoku_cell_widget.dart
  // Location: build method

  @override
    @override
    Widget build(BuildContext context) {
      // Use Consumer widgets to get specific providers and rebuild efficiently
      return Consumer2<GameProvider, SettingsProvider>(
        builder: (context, gameProvider, settingsProvider, child) {
          // --- Get data using providers ---
          final SudokuCellData cellData = gameProvider.board[row][col];
          final bool isSelected = gameProvider.selectedRow == row && gameProvider.selectedCol == col;
          // --- Get palette directly from SettingsProvider ---
          final Color? cellColorValue = cellData.getColor(settingsProvider.selectedPalette.colors);
          final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
           final currentTheme = Theme.of(context); // Get theme

          // Determine background color and border for selection/peers/fixed
          Color tileBackgroundColor = Colors.transparent; // Base background
          Color borderColor = Colors.transparent;
          double borderWidth = 0.0;
          double elevation = 0.0; // Keep track for potential shadow animation

          bool highlightPeer = false;
           // Use settingsProvider.highlightPeers directly
           if (settingsProvider.highlightPeers && gameProvider.selectedRow != null && !(isSelected)) {
              if (gameProvider.selectedRow == row || gameProvider.selectedCol == col ||
                 (gameProvider.selectedRow! ~/ 3 == row ~/ 3 && gameProvider.selectedCol! ~/ 3 == col ~/ 3)) {
                    highlightPeer = true;
                    // --- Set Highlight Peers Alpha to 0.3 ---
                    tileBackgroundColor = currentTheme.focusColor.withOpacity(0.1); // EXACTLY 0.1 opacity
                 }
           }

          if (isSelected) {
            // Use primary color variation for selection border
             borderColor = currentTheme.colorScheme.primary.withOpacity(0.9); // Use theme color
            borderWidth = 3.0; // Thicker border
            elevation = 3.0; // Slightly raise selected cell more
          } else if (cellData.isFixed && cellColorValue == null) { // Only apply fixed background if cell is empty
              // Subtle background for fixed cells (use theme color)
              tileBackgroundColor = currentTheme.colorScheme.onSurface.withOpacity(0.08);
          }

          // --- Apply Alpha Channel to Cell Color ---
          // If cell has a color value, use it with opacity, otherwise use the calculated tile background
          final Color mainFillColor = cellColorValue != null
                                      ? cellColorValue.withOpacity(0.92) // Apply 92% opacity to placed colors
                                      : tileBackgroundColor;


          // Determine overlay color based on the brightness of the fill color
          // If mainFillColor is transparent, base decision on theme background
          final Color effectiveBgForOverlay = mainFillColor == Colors.transparent
                                                ? currentTheme.scaffoldBackgroundColor
                                                : mainFillColor;
          final Color overlayColor = ThemeData.estimateBrightnessForColor(effectiveBgForOverlay) == Brightness.dark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black.withOpacity(0.9);

          TextStyle overlayStyle = TextStyle(
            fontSize: 18,
            fontWeight: cellData.isFixed ? FontWeight.bold : FontWeight.normal,
            color: overlayColor,
             shadows: [
              Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.3), offset: const Offset(0.5, 1.0)),
            ],
          );

           // --- Define Tile Decoration ---
           const double cellCornerRadius = 6.0;
           BoxDecoration tileDecoration = BoxDecoration(
               borderRadius: BorderRadius.circular(cellCornerRadius),
               border: Border.all(color: borderColor, width: borderWidth),
           );


          // Use InkWell instead of GestureDetector
          return InkWell(
            onTap: () {
              if (!gameProvider.isCompleted) {
                 gameProvider.selectCell(row, col);
              }
            },
            splashColor: overlayColor.withOpacity(0.2),
            highlightColor: overlayColor.withOpacity(0.1),
            customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cellCornerRadius),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
               margin: const EdgeInsets.all(1.0),
               decoration: tileDecoration.copyWith(color: mainFillColor), // Apply color here
               clipBehavior: Clip.antiAlias,
               child: Material(
                  elevation: elevation,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(cellCornerRadius),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Candidate display
                      if (cellData.value == null && cellData.candidates.isNotEmpty)
                        _buildCandidatesWidget(context, cellData.candidates, settingsProvider.selectedPalette.colors, mainFillColor),

                      // Overlay (Numbers or Patterns)
                      if (cellData.value != null && settingsProvider.cellOverlay != CellOverlay.none)
                         LayoutBuilder(
                           builder: (context, constraints) {
                             final size = Size(constraints.maxWidth, constraints.maxHeight);
                             if (size.width <= 0 || size.height <= 0) {
                               return const SizedBox.shrink();
                             }
                             return _buildOverlayWidget(
                               context,
                               settingsProvider.cellOverlay,
                               cellData.value!,
                               overlayStyle,
                               overlayColor,
                               size,
                             );
                           }
                         ),


                      // Error Indicator
                       if (cellData.hasError && settingsProvider.showErrors)
                         Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                               decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(cellCornerRadius - 1.0),
                                   border: Border.all(color: currentTheme.colorScheme.error.withOpacity(0.9), width: 2.5)
                               ),
                              ),
                            ),
                        )
                    ],
                  ),
               ),
            ),
          );
        },
      );
    }

  // Helper to build the candidates display
  Widget _buildCandidatesWidget(BuildContext context, Set<int> candidates, List<Color> palette, Color tileBgColor) {
     // Choose candidate dot color based on tile background brightness
     final bool isDarkBg = ThemeData.estimateBrightnessForColor(tileBgColor) == Brightness.dark;
     final Color dotBorderColor = isDarkBg ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3);
     int numCandidates = candidates.length;

     // --- Corrected Grid Size Logic ---
     // Use 3x3 grid if more than 4 candidates, 2x2 if 2-4, 1x1 if 1.
     int crossAxisCount = (numCandidates > 4) ? 3 : ((numCandidates > 1) ? 2 : 1);

     // Fallback safety check (shouldn't be needed with above logic)
     if (numCandidates == 0) crossAxisCount = 1; // Avoid division by zero if set is empty


     List<int> sortedCandidates = candidates.toList()..sort();

    return Padding(
       padding: const EdgeInsets.all(1.5), // Slightly more padding for candidate grid
       child: GridView.count(
         crossAxisCount: crossAxisCount, // Use the calculated count
         mainAxisSpacing: 1, // Spacing between candidate rows
         crossAxisSpacing: 1, // Spacing between candidate columns
         padding: const EdgeInsets.all(1.0), // Padding inside the cell for candidates
         shrinkWrap: true, // Take minimum space needed
         physics: const NeverScrollableScrollPhysics(),
         children: sortedCandidates.map((index) {
           // Try getting size constraints for better relative sizing
           double defaultSize = 7.0; // Slightly smaller default dot size
            double scaleFactor = 0.014; // Scale factor based on screen size
            try {
                // Use context safely
                if(context.mounted) {
                  final screenMin = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
                  // Adjust dot size based on grid density
                  double sizeMultiplier = (crossAxisCount == 3) ? 0.9 : ((crossAxisCount == 2) ? 1.0 : 1.1);
                  defaultSize = max(4.0, min(8.0, screenMin * scaleFactor * sizeMultiplier)); // Clamp size
                }
            } catch(e) {
                print("Error getting MediaQuery in _buildCandidatesWidget: $e");
                // Ignore error if MediaQuery not available? Use default size.
            }

           return Center(
             child: Container(
               width: defaultSize,
               height: defaultSize,
               constraints: const BoxConstraints(minWidth: 4, minHeight: 4, maxWidth: 8, maxHeight: 8), // Min/Max sizes backup
               decoration: BoxDecoration(
                  // Add subtle alpha to candidate dots too
                 color: palette[index].withOpacity(0.9),
                 shape: BoxShape.circle,
                 border: Border.all(color: dotBorderColor, width: 0.5)
               ),
             ),
           );
         }).toList(),
       ),
    );
 }

  // Helper to build the overlay (Number or Pattern)
  Widget _buildOverlayWidget(BuildContext context, CellOverlay overlayType, int value, TextStyle style, Color overlayColor, Size size) {
      Widget overlayContent;
      switch(overlayType) {
        case CellOverlay.numbers:
           // Keep FittedBox + Text for numbers to ensure text scales down if needed
           overlayContent = FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${value + 1}', style: style)
            );
           // Wrap numbers in Center just to be sure, though FittedBox might handle it
           overlayContent = Center(child: overlayContent);
           break;
        case CellOverlay.patterns:
           // Use CustomPaint directly, passing the size
           // Remove the wrapping Center and ClipRect
           overlayContent = CustomPaint(
                size: size, // Provide the available size from LayoutBuilder
                painter: PatternPainter(
                  patternIndex: value,
                  color: overlayColor,
                ),
              );
           break;
        case CellOverlay.none:
        default:
           overlayContent = const SizedBox.shrink();
           break;
      }
      // Return the content directly. No outer ClipRect/Center needed here for patterns.
      return overlayContent;
  }

} // End of SudokuCellWidget