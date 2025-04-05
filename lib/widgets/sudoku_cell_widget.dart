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

        // Determine background color and border for selection/peers/fixed
        Color tileBackgroundColor = Colors.transparent;
        Color borderColor = Colors.transparent;
        double borderWidth = 0.0;
        double elevation = 0.0;

         bool highlightPeer = false;
         // Use settingsProvider.highlightPeers directly
         if (settingsProvider.highlightPeers && gameProvider.selectedRow != null && !(isSelected)) {
            if (gameProvider.selectedRow == row || gameProvider.selectedCol == col ||
               (gameProvider.selectedRow! ~/ 3 == row ~/ 3 && gameProvider.selectedCol! ~/ 3 == col ~/ 3)) {
                  highlightPeer = true;
                  tileBackgroundColor = Theme.of(context).focusColor.withOpacity(0.2);
               }
         }

        if (isSelected) {
          // Use primary color variation for selection border
          borderColor = Theme.of(context).primaryColor.withOpacity(0.8);
          borderWidth = 2.5;
          elevation = 2.0; // Slightly raise selected cell
        } else if (cellData.isFixed) {
            // Subtle background for fixed cells
            tileBackgroundColor = (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!).withOpacity(0.7);
        }

        // If cell has a color value, use it as the main background
        final Color mainFillColor = cellColorValue ?? tileBackgroundColor;

        // Determine overlay color based on the brightness of the fill color
        final Color overlayColor = ThemeData.estimateBrightnessForColor(mainFillColor) == Brightness.dark
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.black.withOpacity(0.8);

        TextStyle overlayStyle = TextStyle(
          fontSize: 18, // Adjust as needed
          fontWeight: cellData.isFixed ? FontWeight.bold : FontWeight.normal,
          color: overlayColor,
           shadows: [ // Subtle shadow for better readability on varied backgrounds
            Shadow(blurRadius: 1.0, color: Colors.black.withOpacity(0.2), offset: const Offset(0.5, 0.5)),
          ],
        );

         // --- Define Tile Decoration ---
         BoxDecoration tileDecoration = BoxDecoration(
             color: mainFillColor,
             borderRadius: BorderRadius.circular(6.0), // Rounded corners
             border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: kElevationToShadow[elevation.toInt()] // Use standard elevation shadows
         );


        return GestureDetector(
          onTap: () {
             // Prevent interaction if game is completed
            if (!gameProvider.isCompleted) {
               gameProvider.selectCell(row, col);
            }
          },
          child: AnimatedContainer( // Animate background color and decoration changes
            duration: const Duration(milliseconds: 180),
             margin: const EdgeInsets.all(1.5), // Add margin to create space between tiles visually
             decoration: tileDecoration,
             clipBehavior: Clip.antiAlias, // Clip children (like painter) to rounded corners
             // --- REMOVED FittedBox ---
             child: Stack( // Stack directly inside AnimatedContainer
                alignment: Alignment.center,
                children: [
                  // 1. Main content area is now handled by the container's background color

                  // 2. Candidate display
                  if (cellData.value == null && cellData.candidates.isNotEmpty)
                    _buildCandidatesWidget(context, cellData.candidates, settingsProvider.selectedPalette.colors, tileBackgroundColor),

                  // 3. Overlay (Numbers or Patterns)
                  if (cellData.value != null && settingsProvider.cellOverlay != CellOverlay.none)
                     LayoutBuilder( // LayoutBuilder gets constraints directly from Stack (sized by AnimatedContainer)
                       builder: (context, constraints) {
                         final size = Size(constraints.maxWidth, constraints.maxHeight);

                         // Ensure size is valid before building overlay
                         if (size.width <= 0 || size.height <= 0) {
                           return const SizedBox.shrink(); // Return empty if no size
                         }

                         // Log only once per state change maybe? Removing for now.
                         // if(settingsProvider.cellOverlay == CellOverlay.patterns) {
                         //    print("Cell ($row, $col): Drawing PATTERN overlay. Value=${cellData.value}, Size=$size");
                         // }

                         return _buildOverlayWidget(
                           context,
                           settingsProvider.cellOverlay, // Use setting directly
                           cellData.value!,
                           overlayStyle,
                           overlayColor,
                           size, // Pass the calculated size
                         );
                       }
                     ),


                  // 4. Error Indicator
                  // --- Use settingsProvider.showErrors directly ---
                   if (cellData.hasError && settingsProvider.showErrors)
                     Positioned.fill( // Use Positioned.fill to draw border inside the rounded corners
                        child: Container(
                            margin: const EdgeInsets.all(0.5), // Slight inset for the error border
                           decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0), // Match parent rounding slightly reduced
                              border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2.0)
                           ),
                        ),
                    )
                ],
              ),
             // --- End REMOVED FittedBox ---
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
     // Adjust grid size based on number
     int crossAxisCount = (numCandidates > 6) ? 3 : ((numCandidates > 1) ? 2 : 1);
     // Ensure crossAxisCount is at least 1 if there are candidates
     if (numCandidates > 0 && crossAxisCount < 1) crossAxisCount = 1;


     List<int> sortedCandidates = candidates.toList()..sort();

    return Padding(
       padding: const EdgeInsets.all(1.0), // Padding for the whole candidate grid
       child: GridView.count(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: 0.5, // Spacing between candidate rows
         crossAxisSpacing: 0.5, // Spacing between candidate columns
         padding: const EdgeInsets.all(1.0), // Padding inside the cell for candidates
         shrinkWrap: true, // Take minimum space needed
         physics: const NeverScrollableScrollPhysics(),
         children: sortedCandidates.map((index) {
           // Try getting size constraints for better relative sizing
           double defaultSize = 8.0; // Default dot size
            double scaleFactor = 0.015; // Scale factor based on screen size
            try {
                // Use context safely
                if(context.mounted) {
                  final screenMin = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
                  defaultSize = max(6.0, min(10.0, screenMin * scaleFactor)); // Clamp size between 6 and 10
                }
            } catch(e) {
                print("Error getting MediaQuery in _buildCandidatesWidget: $e");
                // Ignore error if MediaQuery not available? Use default size.
            }

           return Center(
             child: Container(
               width: defaultSize,
               height: defaultSize,
               constraints: const BoxConstraints(minWidth: 6, minHeight: 6, maxWidth: 10, maxHeight: 10), // Min/Max sizes backup
               decoration: BoxDecoration(
                 color: palette[index], // Use passed palette
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