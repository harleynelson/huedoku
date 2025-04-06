// File: lib/widgets/sudoku_cell_widget.dart
// Location: ./lib/widgets/sudoku_cell_widget.dart

import 'package:flutter/material.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Import Timer
import 'dart:math'; // Import min

// --- Convert to StatefulWidget ---
class SudokuCellWidget extends StatefulWidget {
  final int row;
  final int col;

  const SudokuCellWidget({
    super.key,
    required this.row,
    required this.col,
  });

  @override
  State<SudokuCellWidget> createState() => _SudokuCellWidgetState();
}

// --- Add State Class with TickerProvider ---
class _SudokuCellWidgetState extends State<SudokuCellWidget>
    with SingleTickerProviderStateMixin { // Add Mixin

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isInitiallyFixedWithvalue = false;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();

    // Check initial fixed state ONCE
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.isPuzzleLoaded &&
        widget.row < gameProvider.board.length &&
        widget.col < gameProvider.board[widget.row].length) {
      final cellData = gameProvider.board[widget.row][widget.col];
      _isInitiallyFixedWithvalue = cellData.isFixed && cellData.value != null;
    } else {
      _isInitiallyFixedWithvalue = false; // Ensure it's false if board not ready
    }


    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Animation duration
      vsync: this,
      value: _isInitiallyFixedWithvalue ? 0.0 : 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    // If it's a fixed cell, schedule the animation to start
    if (_isInitiallyFixedWithvalue) {
      // --- UPDATED Delay Calculation ---
      // Stagger delay based on sum of row + col for diagonal wave effect
      // Adjusted multiplier (e.g., 100ms) because max sum is 16 (vs 80)
      final int delayMillis = (widget.row + widget.col) * 100; // Changed calculation and multiplier
      // --- End Update ---

      _startTimer = Timer(Duration(milliseconds: delayMillis), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel(); // Cancel timer if widget is disposed before it fires
    _controller.dispose();
    super.dispose();
  }

 // Helper methods (_buildCandidatesWidget, _buildOverlayWidget) remain the same
 // ... (Keep these methods as they were) ...
  Widget _buildCandidatesWidget(BuildContext context, Set<int> candidates, List<Color> palette, Color tileBgColor) {
     final bool isDarkBg = ThemeData.estimateBrightnessForColor(tileBgColor) == Brightness.dark;
     final Color dotBorderColor = isDarkBg ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3);
     int numCandidates = candidates.length;
     int crossAxisCount = (numCandidates > 4) ? 3 : ((numCandidates > 1) ? 2 : 1);
     if (numCandidates == 0) crossAxisCount = 1;
     List<int> sortedCandidates = candidates.toList()..sort();
    return Padding( padding: const EdgeInsets.all(1.5),
       child: GridView.count( crossAxisCount: crossAxisCount, mainAxisSpacing: 1, crossAxisSpacing: 1, padding: const EdgeInsets.all(1.0), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
         children: sortedCandidates.map((index) {
           double defaultSize = 7.0; double scaleFactor = 0.014;
            try { if(context.mounted) { final screenMin = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height); double sizeMultiplier = (crossAxisCount == 3) ? 0.9 : ((crossAxisCount == 2) ? 1.0 : 1.1); defaultSize = max(4.0, min(8.0, screenMin * scaleFactor * sizeMultiplier)); }
            } catch(e) { print("Error getting MediaQuery in _buildCandidatesWidget: $e"); }
           return Center( child: Container( width: defaultSize, height: defaultSize, constraints: const BoxConstraints(minWidth: 4, minHeight: 4, maxWidth: 8, maxHeight: 8),
               decoration: BoxDecoration( color: palette[index].withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: dotBorderColor, width: 0.5) ), ), ); }).toList(), ), ); }

  Widget _buildOverlayWidget(BuildContext context, CellOverlay overlayType, int value, TextStyle style, Color overlayColor, Size size) {
      Widget overlayContent;
      switch(overlayType) {
        case CellOverlay.numbers: overlayContent = FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) ); overlayContent = Center(child: overlayContent); break;
        case CellOverlay.patterns: overlayContent = CustomPaint( size: size, painter: PatternPainter( patternIndex: value, color: overlayColor, ), ); break;
        case CellOverlay.none: default: overlayContent = const SizedBox.shrink(); break;
      } return overlayContent; }


  @override
    Widget build(BuildContext context) {
      // Use Consumer widgets to get specific providers and rebuild efficiently
      return Consumer2<GameProvider, SettingsProvider>(
        // Use widget.row and widget.col to access properties from StatefulWidget
        builder: (context, gameProvider, settingsProvider, child) {
          // Defensive check if board isn't ready or indices are out of bounds
          if (!gameProvider.isPuzzleLoaded ||
              widget.row >= gameProvider.board.length ||
              widget.col >= gameProvider.board[widget.row].length) {
             return Container( margin: const EdgeInsets.all(1.0), color: Colors.grey[300] ); // Placeholder
          }

          final SudokuCellData cellData = gameProvider.board[widget.row][widget.col];
          final bool isSelected = gameProvider.selectedRow == widget.row && gameProvider.selectedCol == widget.col;
          final Color? cellColorValue = cellData.getColor(settingsProvider.selectedPalette.colors);
          final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final currentTheme = Theme.of(context);

          // --- Styling logic (remains the same) ---
          Color tileBackgroundColor = Colors.transparent;
          Color borderColor = Colors.transparent;
          double borderWidth = 0.0;
          double elevation = 0.0;
          Color hintOverlayColor = Colors.transparent;
          if (cellData.isHint) { hintOverlayColor = currentTheme.colorScheme.tertiaryContainer?.withOpacity(0.2) ?? currentTheme.focusColor.withOpacity(0.15); }
          bool highlightPeer = false;
           if (settingsProvider.highlightPeers && gameProvider.selectedRow != null && !(isSelected)) {
              if (gameProvider.selectedRow == widget.row || gameProvider.selectedCol == widget.col ||
                 (gameProvider.selectedRow! ~/ 3 == widget.row ~/ 3 && gameProvider.selectedCol! ~/ 3 == widget.col ~/ 3)) {
                    highlightPeer = true; tileBackgroundColor = currentTheme.focusColor.withOpacity(0.05); } }
          if (isSelected) { borderColor = currentTheme.colorScheme.primary.withOpacity(0.9); borderWidth = 3.0; elevation = 3.0;
          } else if (cellData.isFixed && cellColorValue == null) { tileBackgroundColor = currentTheme.colorScheme.onSurface.withOpacity(0.08); }
          final Color baseFillColor = cellColorValue != null ? cellColorValue.withOpacity(0.92) : tileBackgroundColor;
          final Color mainFillColor = cellData.isHint ? Color.alphaBlend(hintOverlayColor, baseFillColor) : baseFillColor; // Use alphaBlend
          final Color effectiveBgForOverlay = cellColorValue ?? tileBackgroundColor;
          final Color overlayColor = ThemeData.estimateBrightnessForColor(effectiveBgForOverlay) == Brightness.dark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9);
          TextStyle overlayStyle = TextStyle( fontSize: 18, fontWeight: cellData.isFixed ? FontWeight.bold : FontWeight.normal, color: overlayColor,
             shadows: [ Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.3), offset: const Offset(0.5, 1.0)), ], );
           const double cellCornerRadius = 6.0;
           BoxDecoration tileDecoration = BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius), border: Border.all(color: borderColor, width: borderWidth), );
          // --- End Styling Logic ---

          // --- Wrap content with ScaleTransition ---
          return ScaleTransition(
             scale: _scaleAnimation,
             child: InkWell(
               // Use widget.row/col here
               onTap: () { if (!gameProvider.isCompleted) { gameProvider.selectCell(widget.row, widget.col); } },
               splashColor: overlayColor.withOpacity(0.2), highlightColor: overlayColor.withOpacity(0.1),
               customBorder: RoundedRectangleBorder( borderRadius: BorderRadius.circular(cellCornerRadius), ),
               child: AnimatedContainer(
                 duration: const Duration(milliseconds: 150), margin: const EdgeInsets.all(1.0),
                 decoration: tileDecoration.copyWith(color: mainFillColor), clipBehavior: Clip.antiAlias,
                 child: Material(
                    elevation: elevation, color: Colors.transparent, borderRadius: BorderRadius.circular(cellCornerRadius),
                    child: Stack( // Stack directly inside Material/AnimatedContainer
                      alignment: Alignment.center,
                      children: [
                         // Hint overlay logic (unchanged)
                         if(cellData.isHint && cellColorValue != null) Container( decoration: BoxDecoration( color: cellColorValue.withOpacity(0.92), borderRadius: BorderRadius.circular(cellCornerRadius), ), ),
                         // Candidate display (unchanged)
                         if (cellData.value == null && cellData.candidates.isNotEmpty)
                           _buildCandidatesWidget(context, cellData.candidates, settingsProvider.selectedPalette.colors, effectiveBgForOverlay),
                         // Overlay (Numbers or Patterns) (unchanged)
                         if (cellData.value != null && settingsProvider.cellOverlay != CellOverlay.none)
                            LayoutBuilder( builder: (context, constraints) { final size = Size(constraints.maxWidth, constraints.maxHeight); if (size.width <= 0 || size.height <= 0) { return const SizedBox.shrink();}
                              return _buildOverlayWidget( context, settingsProvider.cellOverlay, cellData.value!, overlayStyle, overlayColor, size, ); } ),
                         // Error Indicator (unchanged)
                          if (cellData.hasError && settingsProvider.showErrors) Positioned.fill( child: IgnorePointer( child: Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius - 1.0), border: Border.all(color: currentTheme.colorScheme.error.withOpacity(0.9), width: 2.5) ), ), ), )
                      ], ), ), ), ),
           ); // --- End ScaleTransition Wrap ---
        },
      );
    }

} // End of _SudokuCellWidgetState