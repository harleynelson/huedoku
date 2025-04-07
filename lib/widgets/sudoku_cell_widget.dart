// File: lib/widgets/sudoku_cell_widget.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/pattern_painter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';

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

  late AnimationController _placementController;
  late Animation<double> _placementScaleAnimation;
  bool _isInitiallyFixedWithvalue = false;
  Timer? _placementStartTimer;

  late AnimationController _numberFadeController;
  late Animation<double> _numberFadeAnimation;
  bool _introAnimationTriggered = false;

  @override
  void initState() {
    super.initState();

    // Placement Animation Setup (Uses constants)
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.isPuzzleLoaded && widget.row < gameProvider.board.length && widget.col < gameProvider.board[widget.row].length) {
        final cellData = gameProvider.board[widget.row][widget.col];
        _isInitiallyFixedWithvalue = cellData.isFixed && cellData.value != null;
    } else { _isInitiallyFixedWithvalue = false; }
    // --- UPDATED: Use constant for duration ---
    _placementController = AnimationController( duration: kMediumAnimationDuration, vsync: this, value: _isInitiallyFixedWithvalue ? 0.0 : 1.0, );
    _placementScaleAnimation = CurvedAnimation( parent: _placementController, curve: Curves.easeOutBack, );
    if (_isInitiallyFixedWithvalue) {
        // --- UPDATED: Use constant for delay multiplier ---
        final int delayMillis = (widget.row + widget.col) * kIntroPlacementDelayMultiplier;
        _placementStartTimer = Timer(Duration(milliseconds: delayMillis), () { if (mounted) _placementController.forward(); });
    }

    // Number Fade Animation Setup (Uses constants)
    _numberFadeController = AnimationController(
      // --- UPDATED: Use constants for durations ---
      duration: kNumberFadeDuration,
      reverseDuration: kNumberFadeReverseDuration,
      vsync: this,
    );
    _numberFadeAnimation = CurvedAnimation(
      parent: _numberFadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    if (gameProvider.runIntroNumberAnimation && settingsProvider.cellOverlay == CellOverlay.none && !_introAnimationTriggered && mounted) {
      _introAnimationTriggered = true;
      final cellData = gameProvider.board[widget.row][widget.col];
      if(cellData.value != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted && !_numberFadeController.isAnimating && _numberFadeController.status == AnimationStatus.dismissed) {
                // --- UPDATED: Use constant for delay multiplier ---
                final int fadeDelayMillis = (widget.row + widget.col) * kIntroFadeDelayMultiplier;
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
    _placementStartTimer?.cancel();
    _placementController.dispose();
    _numberFadeController.dispose();
    super.dispose();
  }

 // --- Helper: Build Candidates Widget (Uses constants) ---
  Widget _buildCandidatesWidget(BuildContext context, Set<int> candidates, List<Color> palette, Color tileBgColor) {
     // --- UPDATED: Use constant for opacity ---
     final bool isDarkBg = ThemeData.estimateBrightnessForColor(tileBgColor) == Brightness.dark; final Color dotBorderColor = isDarkBg ? Colors.white.withOpacity(kMediumOpacity) : Colors.black.withOpacity(kMediumOpacity);
     int numCandidates = candidates.length;
     int crossAxisCount = (numCandidates > 4) ? 3 : ((numCandidates > 1) ? 2 : 1); // Keep logic
     if (numCandidates == 0) crossAxisCount = 1;
     List<int> sortedCandidates = candidates.toList()..sort();

     // --- UPDATED: Use constants for padding/spacing ---
     return Padding( padding: const EdgeInsets.all(kCandidatePadding),
       child: GridView.count(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: kCandidateGridSpacing,
         crossAxisSpacing: kCandidateGridSpacing,
         padding: const EdgeInsets.all(kCandidateGridSpacing),
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         children: sortedCandidates.map((index) {
             double defaultSize = 7.0; // Keep default or make constant
             double scaleFactor = 0.014; // Keep specific factor or make constant
             try { if(context.mounted) { final screenMin = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height); double sizeMultiplier = (crossAxisCount == 3) ? 0.9 : ((crossAxisCount == 2) ? 1.0 : 1.1); // Keep logic
                // --- UPDATED: Use constants for size clamp ---
                defaultSize = max(kCandidateDotMinSize, min(kCandidateDotMaxSize, screenMin * scaleFactor * sizeMultiplier)); }
             } catch(e) { print("Error getting MediaQuery in _buildCandidatesWidget: $e"); }
             return Center( child: Container(
                 width: defaultSize,
                 height: defaultSize,
                 // --- UPDATED: Use constants for size constraints ---
                 constraints: const BoxConstraints(minWidth: kCandidateDotMinSize, minHeight: kCandidateDotMinSize, maxWidth: kCandidateDotMaxSize, maxHeight: kCandidateDotMaxSize),
                 decoration: BoxDecoration(
                   // --- UPDATED: Use constants for opacity/border ---
                   color: palette[index].withOpacity(kVeryHighOpacity),
                   shape: BoxShape.circle,
                   border: Border.all(color: dotBorderColor, width: kCandidateDotBorderWidth)
                 ),
               ),
             );
           }).toList(),
       ),
     );
 }

  // --- Helper: Build Overlay Widget (Uses constants) ---
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
      Widget baseWidget;
      switch(currentSetting) {
        // --- UPDATED: Use constant for font size ---
        case CellOverlay.numbers: baseWidget = Center(child: FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) )); break;
        // --- UPDATED: Use constant for pattern multiplier ---
        case CellOverlay.patterns: baseWidget = CustomPaint( size: size, painter: PatternPainter( patternIndex: value, color: overlayColor, strokeWidthMultiplier: kPatternStrokeMultiplier ), ); break;
        case CellOverlay.none: default: baseWidget = const SizedBox.shrink(); break;
      }

      bool showIntroFade = isIntroSequenceTriggered && fadeAnimation.value > 0.0;

      if (showIntroFade) {
          // --- UPDATED: Use constant for font size ---
          Widget numberForFade = Center(child: FittedBox( fit: BoxFit.scaleDown, child: Text('${value + 1}', style: style) ));
          overlayContent = FadeTransition(
             opacity: fadeAnimation,
             child: numberForFade,
          );
      } else {
         overlayContent = baseWidget;
      }
      return overlayContent;
 }


  @override
    Widget build(BuildContext context) {
      final gameProvider = context.read<GameProvider>();
      final cellData = context.select((GameProvider gp) => (gp.isPuzzleLoaded && widget.row < gp.board.length && widget.col < gp.board[widget.row].length) ? gp.board[widget.row][widget.col] : null );
      final isSelected = context.select((GameProvider gp) => gp.selectedRow == widget.row && gp.selectedCol == widget.col);
      final isCompleted = context.select((GameProvider gp) => gp.isCompleted);
      final selectedPalette = context.select((SettingsProvider sp) => sp.selectedPalette);
      final cellOverlay = context.select((SettingsProvider sp) => sp.cellOverlay);
      final highlightPeers = context.select((SettingsProvider sp) => sp.highlightPeers);
      final showErrors = context.select((SettingsProvider sp) => sp.showErrors);

      if (cellData == null) { return Container( margin: const EdgeInsets.all(kDefaultBorderWidth), color: Colors.grey[300] ); } // Use constant

      final Color? cellColorValue = cellData.getColor(selectedPalette.colors);
      final currentTheme = Theme.of(context);
      Color tileBackgroundColor = Colors.transparent; Color borderColor = Colors.transparent; double borderWidth = 0.0; double elevation = 0.0; Color hintOverlayColor = Colors.transparent;
      // --- UPDATED: Use constants for opacity ---
      if (cellData.isHint) { hintOverlayColor = currentTheme.colorScheme.tertiaryContainer?.withOpacity(kLowMediumOpacity) ?? currentTheme.focusColor.withOpacity(kMediumLowOpacity); }
      bool shouldHighlightPeer = false;
       if (highlightPeers && gameProvider.selectedRow != null && !(isSelected)) {
          // --- UPDATED: Use constant for box size ---
          if (gameProvider.selectedRow == widget.row || gameProvider.selectedCol == widget.col || (gameProvider.selectedRow! ~/ kBoxSize == widget.row ~/ kBoxSize && gameProvider.selectedCol! ~/ kBoxSize == widget.col ~/ kBoxSize)) {
            shouldHighlightPeer = true;
            // --- UPDATED: Use constant for opacity ---
            tileBackgroundColor = currentTheme.focusColor.withOpacity(0.05); // Keep specific or make constant
          }
       }
      if (isSelected) {
          // --- UPDATED: Use constants for border/elevation ---
          borderColor = currentTheme.colorScheme.primary.withOpacity(kVeryHighOpacity);
          borderWidth = kSelectedCellBorderWidth;
          elevation = kHighElevation;
      }
      // --- UPDATED: Use constant for opacity ---
      else if (cellData.isFixed && cellColorValue == null) { tileBackgroundColor = currentTheme.colorScheme.onSurface.withOpacity(0.08); } // Keep specific or make constant
      // --- UPDATED: Use constant for opacity ---
      final Color baseFillColor = cellColorValue != null ? cellColorValue.withOpacity(0.92) : tileBackgroundColor; // Keep specific or make constant
      final Color mainFillColor = cellData.isHint ? Color.alphaBlend(hintOverlayColor, baseFillColor) : baseFillColor;
      final Color effectiveBgForOverlay = cellColorValue ?? tileBackgroundColor;
      // --- UPDATED: Use constant for opacity ---
      final Color overlayColor = ThemeData.estimateBrightnessForColor(effectiveBgForOverlay) == Brightness.dark ? Colors.white.withOpacity(kVeryHighOpacity) : Colors.black.withOpacity(kVeryHighOpacity);
      // --- UPDATED: Use constants for font/shadow ---
      TextStyle overlayStyle = TextStyle( fontSize: kDefaultFontSize, fontWeight: cellData.isFixed ? FontWeight.bold : FontWeight.normal, color: overlayColor, shadows: [ Shadow(blurRadius: 1.5, color: Colors.black.withOpacity(kMediumOpacity), offset: const Offset(0.5, 1.0)), ], ); // Keep specific or make constants
      // --- UPDATED: Use constant for radius ---
      const double cellCornerRadius = kCellCornerRadius;
      final customInkWellBorder = RoundedRectangleBorder( borderRadius: BorderRadius.circular(cellCornerRadius), );
      BoxDecoration tileDecoration = BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius), border: Border.all(color: borderColor, width: borderWidth), );

      return RepaintBoundary(
        child: ScaleTransition(
           scale: _placementScaleAnimation,
           child: InkWell(
             onTap: isCompleted ? null : () => gameProvider.selectCell(widget.row, widget.col),
             // --- UPDATED: Use constants for opacity ---
             splashColor: overlayColor.withOpacity(kLowMediumOpacity), highlightColor: overlayColor.withOpacity(kLowOpacity),
             customBorder: customInkWellBorder,
             child: AnimatedContainer(
               // --- UPDATED: Use constants for duration/margin ---
               duration: kShortAnimationDuration,
               margin: const EdgeInsets.all(kDefaultBorderWidth),
               decoration: tileDecoration.copyWith(color: mainFillColor),
               clipBehavior: Clip.antiAlias,
               child: Material(
                  elevation: elevation, color: Colors.transparent, borderRadius: BorderRadius.circular(cellCornerRadius),
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                         // --- UPDATED: Use constant for opacity ---
                         if(cellData.isHint && cellColorValue != null) Container( decoration: BoxDecoration( color: cellColorValue.withOpacity(0.92), borderRadius: BorderRadius.circular(cellCornerRadius), ), ), // Keep specific or make constant
                         if (cellData.value == null && cellData.candidates.isNotEmpty) _buildCandidatesWidget(context, cellData.candidates, selectedPalette.colors, effectiveBgForOverlay),
                         if (cellData.value != null)
                            AnimatedBuilder(
                              animation: _numberFadeAnimation,
                              builder: (context, child) {
                                 return LayoutBuilder(
                                     builder: (context, constraints) {
                                         final size = Size(constraints.maxWidth, constraints.maxHeight);
                                         if (size.width <= 0 || size.height <= 0) { return const SizedBox.shrink();}
                                         return _buildOverlayWidget( context, cellOverlay, cellData.value!, overlayStyle, overlayColor, size, _introAnimationTriggered, _numberFadeAnimation );
                                     }
                                 );
                              }
                            ),
                         // --- UPDATED: Use constants for error border ---
                         if (cellData.hasError && showErrors) Positioned.fill( child: IgnorePointer( child: Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(cellCornerRadius - 1.0), border: Border.all(color: currentTheme.colorScheme.error.withOpacity(kVeryHighOpacity), width: kErrorCellBorderWidth) ), ), ), )
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