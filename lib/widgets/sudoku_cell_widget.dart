// File: lib/widgets/sudoku_cell_widget.dart
// Location: lib/widgets/sudoku_cell_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/models/sudoku_cell_data.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

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

class _SudokuCellWidgetState extends State<SudokuCellWidget>
    with TickerProviderStateMixin {

  // Placement Animation (Unchanged)
  late AnimationController _placementController;
  late Animation<double> _placementScaleAnimation;
  bool _isInitiallyFixedWithvalue = false;
  Timer? _placementStartTimer;

  // Number Fade Animation
  late AnimationController _numberFadeController;
  late Animation<double> _numberFadeAnimation;
  bool _introAnimationTriggered = false;

  @override
  void initState() {
    super.initState();

    // --- Initial Placement Animation Setup (Unchanged) ---
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.isPuzzleLoaded &&
        widget.row < gameProvider.board.length &&
        widget.col < gameProvider.board[widget.row].length) {
      final cellData = gameProvider.board[widget.row][widget.col];
      _isInitiallyFixedWithvalue = cellData.isFixed && cellData.value != null;
    } else {
      _isInitiallyFixedWithvalue = false;
    }
    _placementController = AnimationController( duration: const Duration(milliseconds: 500), vsync: this, value: _isInitiallyFixedWithvalue ? 0.0 : 1.0, );
    _placementScaleAnimation = CurvedAnimation( parent: _placementController, curve: Curves.easeOutBack, );
    if (_isInitiallyFixedWithvalue) {
      final int delayMillis = (widget.row + widget.col) * 100;
      _placementStartTimer = Timer(Duration(milliseconds: delayMillis), () { if (mounted) _placementController.forward(); });
    }
    // --- End Initial Placement Setup ---

    // --- Number Fade Animation Setup ---
    // *** Slow down animation ***
    _numberFadeController = AnimationController(
      duration: const Duration(milliseconds: 900), // Slower fade in
      reverseDuration: const Duration(milliseconds: 700), // Slower fade out
      vsync: this,
    );
    _numberFadeAnimation = CurvedAnimation(
      parent: _numberFadeController,
      curve: Curves.easeInOut,
    );
    // --- End Number Fade Setup ---
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // --- Trigger Number Fade Animation (Logic Unchanged) ---
    final gameProvider = Provider.of<GameProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (gameProvider.runIntroNumberAnimation &&
        settingsProvider.cellOverlay == CellOverlay.none &&
        !_introAnimationTriggered &&
        mounted) {

      _introAnimationTriggered = true; // Mark as triggered for this load

      final cellData = gameProvider.board[widget.row][widget.col];
      if(cellData.value != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted && !_numberFadeController.isAnimating && _numberFadeController.status == AnimationStatus.dismissed) {
                final int fadeDelayMillis = (widget.row + widget.col) * 50; // Keep stagger
                Timer(Duration(milliseconds: fadeDelayMillis), () {
                    if (mounted) {
                         if (_numberFadeController.status == AnimationStatus.dismissed) {
                            _numberFadeController.forward().whenComplete(() {
                               if (mounted) _numberFadeController.reverse();
                            });
                         }
                    }
                });
             }
          });
      }
    } else if (!gameProvider.runIntroNumberAnimation && _introAnimationTriggered) {
       _introAnimationTriggered = false;
       if(mounted && _numberFadeController.isAnimating) {
          _numberFadeController.stop();
          _numberFadeController.value = 0.0;
       } else if (mounted && _numberFadeController.value != 0.0) {
           _numberFadeController.value = 0.0;
       }
    }
    // --- End Trigger Logic ---
  }


  @override
  void dispose() {
    // dispose remains unchanged
    _placementStartTimer?.cancel();
    _placementController.dispose();
    _numberFadeController.dispose();
    super.dispose();
  }

 // --- Helper: Build Candidates Widget (Unchanged) ---
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

  // --- Helper: Build Overlay Widget (Unchanged from previous step) ---
  Widget _buildOverlayWidget(
      BuildContext context,
      CellOverlay currentSetting,
      int value,
      TextStyle style,
      Color overlayColor,
      Size size,
      bool isIntroSequenceTriggered,
      Animation<double> fadeAnimation
     ) {
      Widget overlayContent;
      CellOverlay typeToRender = currentSetting;

      Widget baseWidget;
      switch(typeToRender) {
        case CellOverlay.numbers: baseWidget = Center(child: FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) )); break;
        case CellOverlay.patterns: baseWidget = CustomPaint( size: size, painter: PatternPainter( patternIndex: value, color: overlayColor, ), ); break;
        case CellOverlay.none: default: baseWidget = const SizedBox.shrink(); break;
      }

      if (isIntroSequenceTriggered) {
          Widget numberForFade = Center(child: FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) ));
          overlayContent = FadeTransition( opacity: fadeAnimation, child: numberForFade, );
      } else {
         overlayContent = baseWidget;
      }
      return overlayContent;
 }


  @override
    Widget build(BuildContext context) {
      // --- Build Method (Unchanged from previous step) ---
      return Consumer2<GameProvider, SettingsProvider>(
        builder: (context, gameProvider, settingsProvider, child) {
          if (!gameProvider.isPuzzleLoaded || widget.row >= gameProvider.board.length || widget.col >= gameProvider.board[widget.row].length) { return Container( margin: const EdgeInsets.all(1.0), color: Colors.grey[300] ); }
          final SudokuCellData cellData = gameProvider.board[widget.row][widget.col];
          final bool isSelected = gameProvider.selectedRow == widget.row && gameProvider.selectedCol == widget.col;
          final Color? cellColorValue = cellData.getColor(settingsProvider.selectedPalette.colors);
          final currentTheme = Theme.of(context);
          Color tileBackgroundColor = Colors.transparent; Color borderColor = Colors.transparent; double borderWidth = 0.0; double elevation = 0.0; Color hintOverlayColor = Colors.transparent;
          if (cellData.isHint) { hintOverlayColor = currentTheme.colorScheme.tertiaryContainer?.withOpacity(0.2) ?? currentTheme.focusColor.withOpacity(0.15); }
          bool highlightPeer = false;
           if (settingsProvider.highlightPeers && gameProvider.selectedRow != null && !(isSelected)) { if (gameProvider.selectedRow == widget.row || gameProvider.selectedCol == widget.col || (gameProvider.selectedRow! ~/ 3 == widget.row ~/ 3 && gameProvider.selectedCol! ~/ 3 == widget.col ~/ 3)) { highlightPeer = true; tileBackgroundColor = currentTheme.focusColor.withOpacity(0.05); } }
          if (isSelected) { borderColor = currentTheme.colorScheme.primary.withOpacity(0.9); borderWidth = 3.0; elevation = 3.0; }
          else if (cellData.isFixed && cellColorValue == null) { tileBackgroundColor = currentTheme.colorScheme.onSurface.withOpacity(0.08); }
          final Color baseFillColor = cellColorValue != null ? cellColorValue.withOpacity(0.92) : tileBackgroundColor;
          final Color mainFillColor = cellData.isHint ? Color.alphaBlend(hintOverlayColor, baseFillColor) : baseFillColor;
          final Color effectiveBgForOverlay = cellColorValue ?? tileBackgroundColor;
          final Color overlayColor = ThemeData.estimateBrightnessForColor(effectiveBgForOverlay) == Brightness.dark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9);
          TextStyle overlayStyle = TextStyle( fontSize: 18, fontWeight: cellData.isFixed ? FontWeight.bold : FontWeight.normal, color: overlayColor, shadows: [ Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.3), offset: const Offset(0.5, 1.0)), ], );
           const double cellCornerRadius = 6.0;
           BoxDecoration tileDecoration = BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius), border: Border.all(color: borderColor, width: borderWidth), );

          return ScaleTransition( scale: _placementScaleAnimation,
             child: InkWell( onTap: () { if (!gameProvider.isCompleted) { gameProvider.selectCell(widget.row, widget.col); } }, splashColor: overlayColor.withOpacity(0.2), highlightColor: overlayColor.withOpacity(0.1), customBorder: RoundedRectangleBorder( borderRadius: BorderRadius.circular(cellCornerRadius), ),
               child: AnimatedContainer( duration: const Duration(milliseconds: 150), margin: const EdgeInsets.all(1.0), decoration: tileDecoration.copyWith(color: mainFillColor), clipBehavior: Clip.antiAlias,
                 child: Material( elevation: elevation, color: Colors.transparent, borderRadius: BorderRadius.circular(cellCornerRadius),
                    child: Stack( alignment: Alignment.center, children: [
                         if(cellData.isHint && cellColorValue != null) Container( decoration: BoxDecoration( color: cellColorValue.withOpacity(0.92), borderRadius: BorderRadius.circular(cellCornerRadius), ), ),
                         if (cellData.value == null && cellData.candidates.isNotEmpty) _buildCandidatesWidget(context, cellData.candidates, settingsProvider.selectedPalette.colors, effectiveBgForOverlay),
                         if (cellData.value != null) LayoutBuilder( builder: (context, constraints) { final size = Size(constraints.maxWidth, constraints.maxHeight); if (size.width <= 0 || size.height <= 0) { return const SizedBox.shrink();} return _buildOverlayWidget( context, settingsProvider.cellOverlay, cellData.value!, overlayStyle, overlayColor, size, _introAnimationTriggered, _numberFadeAnimation ); } ),
                         if (cellData.hasError && settingsProvider.showErrors) Positioned.fill( child: IgnorePointer( child: Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius - 1.0), border: Border.all(color: currentTheme.colorScheme.error.withOpacity(0.9), width: 2.5) ), ), ), )
                      ], ), ), ), ), );
        },
      );
    }
}