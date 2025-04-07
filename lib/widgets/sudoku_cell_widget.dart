// File: lib/widgets/sudoku_cell_widget.dart
// Location: lib/widgets/sudoku_cell_widget.dart

// Imports remain the same
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

class SudokuCellWidget extends StatefulWidget {
  const SudokuCellWidget({
    super.key,
    required this.row,
    required this.col,
  });

  final int row;
  final int col;

  @override
  State<SudokuCellWidget> createState() => _SudokuCellWidgetState();
}

class _SudokuCellWidgetState extends State<SudokuCellWidget>
    with TickerProviderStateMixin {

  // --- State variables ---
  late AnimationController _placementController;
  late Animation<double> _placementScaleAnimation;
  bool _isInitiallyFixedWithvalue = false;
  Timer? _placementStartTimer;

  late AnimationController _numberFadeController;
  late Animation<double> _numberFadeAnimation;
  bool _introAnimationTriggered = false;
  // --- REMOVE _isDoingIntroNumberFadeNow ---
  // bool _isDoingIntroNumberFadeNow = false;

  @override
  void initState() {
    super.initState();

    // Placement Animation Setup (Unchanged)
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.isPuzzleLoaded && widget.row < gameProvider.board.length && widget.col < gameProvider.board[widget.row].length) {
        final cellData = gameProvider.board[widget.row][widget.col];
        _isInitiallyFixedWithvalue = cellData.isFixed && cellData.value != null;
    } else { _isInitiallyFixedWithvalue = false; }
    _placementController = AnimationController( duration: const Duration(milliseconds: 500), vsync: this, value: _isInitiallyFixedWithvalue ? 0.0 : 1.0, );
    _placementScaleAnimation = CurvedAnimation( parent: _placementController, curve: Curves.easeOutBack, );
    if (_isInitiallyFixedWithvalue) {
        final int delayMillis = (widget.row + widget.col) * 100;
        _placementStartTimer = Timer(Duration(milliseconds: delayMillis), () { if (mounted) _placementController.forward(); });
    }

    // Number Fade Animation Setup (Keep slower animation)
    _numberFadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _numberFadeAnimation = CurvedAnimation(
      parent: _numberFadeController,
      curve: Curves.easeInOut,
    );

    // --- REMOVE Status Listener ---
  }

  @override
  void didChangeDependencies() {
    // didChangeDependencies remains unchanged (keeps postFrameCallback trigger)
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    if (gameProvider.runIntroNumberAnimation && settingsProvider.cellOverlay == CellOverlay.none && !_introAnimationTriggered && mounted) {
      _introAnimationTriggered = true;
      final cellData = gameProvider.board[widget.row][widget.col];
      if(cellData.value != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted && !_numberFadeController.isAnimating && _numberFadeController.status == AnimationStatus.dismissed) {
                final int fadeDelayMillis = (widget.row + widget.col) * 50;
                Timer(Duration(milliseconds: fadeDelayMillis), () {
                    if (mounted) { if (_numberFadeController.status == AnimationStatus.dismissed) { _numberFadeController.forward().whenComplete(() { if (mounted) _numberFadeController.reverse(); }); } }
                });
             }
          });
      }
    } else if (!gameProvider.runIntroNumberAnimation && _introAnimationTriggered) {
       _introAnimationTriggered = false;
       if(mounted && _numberFadeController.isAnimating) { _numberFadeController.stop(); _numberFadeController.value = 0.0; }
       else if (mounted && _numberFadeController.value != 0.0) { _numberFadeController.value = 0.0; }
    }
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
     final bool isDarkBg = ThemeData.estimateBrightnessForColor(tileBgColor) == Brightness.dark; final Color dotBorderColor = isDarkBg ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3); int numCandidates = candidates.length; int crossAxisCount = (numCandidates > 4) ? 3 : ((numCandidates > 1) ? 2 : 1); if (numCandidates == 0) crossAxisCount = 1; List<int> sortedCandidates = candidates.toList()..sort();
     return Padding( padding: const EdgeInsets.all(1.5), child: GridView.count( crossAxisCount: crossAxisCount, mainAxisSpacing: 1, crossAxisSpacing: 1, padding: const EdgeInsets.all(1.0), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: sortedCandidates.map((index) { double defaultSize = 7.0; double scaleFactor = 0.014; try { if(context.mounted) { final screenMin = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height); double sizeMultiplier = (crossAxisCount == 3) ? 0.9 : ((crossAxisCount == 2) ? 1.0 : 1.1); defaultSize = max(4.0, min(8.0, screenMin * scaleFactor * sizeMultiplier)); } } catch(e) { print("Error getting MediaQuery in _buildCandidatesWidget: $e"); } return Center( child: Container( width: defaultSize, height: defaultSize, constraints: const BoxConstraints(minWidth: 4, minHeight: 4, maxWidth: 8, maxHeight: 8), decoration: BoxDecoration( color: palette[index].withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: dotBorderColor, width: 0.5) ), ), ); }).toList(), ), );
 }

  // --- Helper: Build Overlay Widget (REVISED LOGIC) ---
  Widget _buildOverlayWidget(
      BuildContext context,
      CellOverlay currentSetting,      // The actual setting from provider
      int value,
      TextStyle style,
      Color overlayColor,
      Size size,
      bool isIntroSequenceTriggered, // Use the trigger flag for this load
      // Pass the animation itself, not just the active status
      Animation<double> fadeAnimation
     ) {
      Widget overlayContent;

      // Determine the base widget based on the current setting
      Widget baseWidget;
      switch(currentSetting) {
        case CellOverlay.numbers: baseWidget = Center(child: FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) )); break;
        case CellOverlay.patterns: baseWidget = CustomPaint( size: size, painter: PatternPainter( patternIndex: value, color: overlayColor, ), ); break;
        case CellOverlay.none: default: baseWidget = const SizedBox.shrink(); break;
      }

      // Should we display the fading intro number right now?
      // Check if intro was triggered AND the animation value is > 0 (meaning it's not fully dismissed)
      bool showIntroFade = isIntroSequenceTriggered && fadeAnimation.value > 0.0;

      if (showIntroFade) {
          // If showing intro fade, ALWAYS display the number wrapped in FadeTransition
          Widget numberForFade = Center(child: FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) ));
          overlayContent = FadeTransition(
             opacity: fadeAnimation, // Animation value handles visibility (0->1->0)
             child: numberForFade,
          );
      } else {
         // Otherwise (intro wasn't triggered OR animation is fully dismissed), show the base widget
         overlayContent = baseWidget;
      }
      return overlayContent;
 }


  @override
    Widget build(BuildContext context) {
      // --- Build Method (Keep optimizations, pass fadeAnimation to helper) ---
      final gameProvider = context.read<GameProvider>();
      final cellData = context.select((GameProvider gp) => (gp.isPuzzleLoaded && widget.row < gp.board.length && widget.col < gp.board[widget.row].length) ? gp.board[widget.row][widget.col] : null );
      final isSelected = context.select((GameProvider gp) => gp.selectedRow == widget.row && gp.selectedCol == widget.col);
      final isCompleted = context.select((GameProvider gp) => gp.isCompleted);
      final selectedPalette = context.select((SettingsProvider sp) => sp.selectedPalette);
      final cellOverlay = context.select((SettingsProvider sp) => sp.cellOverlay); // Listen to setting
      final highlightPeers = context.select((SettingsProvider sp) => sp.highlightPeers);
      final showErrors = context.select((SettingsProvider sp) => sp.showErrors);

      if (cellData == null) { return Container( margin: const EdgeInsets.all(1.0), color: Colors.grey[300] ); }

      final Color? cellColorValue = cellData.getColor(selectedPalette.colors);
      final currentTheme = Theme.of(context);
      Color tileBackgroundColor = Colors.transparent; Color borderColor = Colors.transparent; double borderWidth = 0.0; double elevation = 0.0; Color hintOverlayColor = Colors.transparent;
      if (cellData.isHint) { hintOverlayColor = currentTheme.colorScheme.tertiaryContainer?.withOpacity(0.2) ?? currentTheme.focusColor.withOpacity(0.15); }
      bool shouldHighlightPeer = false;
       if (highlightPeers && gameProvider.selectedRow != null && !(isSelected)) { if (gameProvider.selectedRow == widget.row || gameProvider.selectedCol == widget.col || (gameProvider.selectedRow! ~/ 3 == widget.row ~/ 3 && gameProvider.selectedCol! ~/ 3 == widget.col ~/ 3)) { shouldHighlightPeer = true; tileBackgroundColor = currentTheme.focusColor.withOpacity(0.05); } }
      if (isSelected) { borderColor = currentTheme.colorScheme.primary.withOpacity(0.9); borderWidth = 3.0; elevation = 3.0; }
      else if (cellData.isFixed && cellColorValue == null) { tileBackgroundColor = currentTheme.colorScheme.onSurface.withOpacity(0.08); }
      final Color baseFillColor = cellColorValue != null ? cellColorValue.withOpacity(0.92) : tileBackgroundColor;
      final Color mainFillColor = cellData.isHint ? Color.alphaBlend(hintOverlayColor, baseFillColor) : baseFillColor;
      final Color effectiveBgForOverlay = cellColorValue ?? tileBackgroundColor;
      final Color overlayColor = ThemeData.estimateBrightnessForColor(effectiveBgForOverlay) == Brightness.dark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9);
      TextStyle overlayStyle = TextStyle( fontSize: 18, fontWeight: cellData.isFixed ? FontWeight.bold : FontWeight.normal, color: overlayColor, shadows: [ Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(0.3), offset: const Offset(0.5, 1.0)), ], );
      const double cellCornerRadius = 6.0;
      final customInkWellBorder = RoundedRectangleBorder( borderRadius: BorderRadius.circular(cellCornerRadius), );
      BoxDecoration tileDecoration = BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius), border: Border.all(color: borderColor, width: borderWidth), );

      // Keep RepaintBoundary wrappers
      return RepaintBoundary(
        child: ScaleTransition(
           scale: _placementScaleAnimation,
           child: InkWell(
             onTap: isCompleted ? null : () => gameProvider.selectCell(widget.row, widget.col),
             splashColor: overlayColor.withOpacity(0.2), highlightColor: overlayColor.withOpacity(0.1),
             customBorder: customInkWellBorder,
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 150),
               margin: const EdgeInsets.all(1.0),
               decoration: tileDecoration.copyWith(color: mainFillColor),
               clipBehavior: Clip.antiAlias,
               child: Material(
                  elevation: elevation, color: Colors.transparent, borderRadius: BorderRadius.circular(cellCornerRadius),
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                         if(cellData.isHint && cellColorValue != null) Container( decoration: BoxDecoration( color: cellColorValue.withOpacity(0.92), borderRadius: BorderRadius.circular(cellCornerRadius), ), ),
                         if (cellData.value == null && cellData.candidates.isNotEmpty) _buildCandidatesWidget(context, cellData.candidates, selectedPalette.colors, effectiveBgForOverlay),
                         if (cellData.value != null)
                            // Use an AnimatedBuilder to listen directly to the fade animation value
                            // This ensures rebuilds happen *only* when the opacity changes during the intro fade
                            AnimatedBuilder(
                              animation: _numberFadeAnimation, // Listen to the animation value
                              builder: (context, child) {
                                 // Determine size within builder if needed, or pass from LayoutBuilder if preferred
                                 return LayoutBuilder( // Keep LayoutBuilder for size constraints
                                     builder: (context, constraints) {
                                         final size = Size(constraints.maxWidth, constraints.maxHeight);
                                         if (size.width <= 0 || size.height <= 0) { return const SizedBox.shrink();}
                                         // Pass animation itself (_numberFadeAnimation)
                                         return _buildOverlayWidget( context, cellOverlay, cellData.value!, overlayStyle, overlayColor, size, _introAnimationTriggered, _numberFadeAnimation );
                                     }
                                 );
                              }
                            ),
                         if (cellData.hasError && showErrors) Positioned.fill( child: IgnorePointer( child: Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius - 1.0), border: Border.all(color: currentTheme.colorScheme.error.withOpacity(0.9), width: 2.5) ), ), ), )
                      ],
                    ),
                  ),
                ),
             ),
           ),
         ),
      );
    }
}