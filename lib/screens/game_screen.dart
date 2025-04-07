// File: lib/screens/game_screen.dart
// Location: Entire File
// (More than 2 methods/areas affected by constant changes)

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huedoku/models/color_palette.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:huedoku/providers/settings_provider.dart';
import 'package:huedoku/widgets/bokeh_painter.dart';
import 'package:huedoku/widgets/game_controls.dart';
import 'package:huedoku/widgets/palette_selector_widget.dart';
import 'package:huedoku/widgets/settings_content.dart';
import 'package:huedoku/widgets/sudoku_grid_widget.dart';
import 'package:huedoku/widgets/timer_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:huedoku/themes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
// --- UPDATED: Import constants ---
import 'package:huedoku/constants.dart';
import 'package:share_plus/share_plus.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _completionDialogShown = false;
  List<BokehParticle> _particles = [];
  bool _particlesInitialized = false;
  Size? _lastScreenSize;
  bool? _lastThemeIsDark;
  ColorPalette? _lastPaletteUsed;
  late ConfettiController _confettiController;
  final GlobalKey<GameControlsState> _gameControlsKey = GlobalKey<GameControlsState>();
  Timer? _introAnimationTimer;

  @override void initState() {
     super.initState();
     // --- UPDATED: Use constant for confetti duration ---
     _confettiController = ConfettiController(duration: kConfettiDuration);
     WidgetsBinding.instance.addPostFrameCallback((_) {
        _startIntroAnimationSequenceIfNeeded();
     });
  }

  @override void didChangeDependencies() {
     super.didChangeDependencies();
     _updateBokehIfNeeded();
  }

  @override void dispose() {
    _confettiController.dispose();
    _introAnimationTimer?.cancel();
    super.dispose();
  }

  // --- Updated Intro Animation Sequence (Uses constants) ---
  void _startIntroAnimationSequenceIfNeeded() {
    if (!mounted) return;
    _introAnimationTimer?.cancel();

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (gameProvider.isPuzzleLoaded && settingsProvider.cellOverlay == CellOverlay.none) {
      // --- UPDATED: Use constants for delays ---
      _introAnimationTimer = Timer(kIntroSequenceDelay, () {
        if (!mounted) return;
        gameProvider.triggerIntroNumberAnimation();

        _introAnimationTimer = Timer(kIntroHighlightDelay, () {
          if (!mounted) return;
          _gameControlsKey.currentState?.triggerHighlight();
          // Optional: reset provider flag
          // gameProvider.resetIntroNumberAnimation();
        });
      });
    }
  }

  // --- Methods (regenerateBokeh, updateBokeh, formatDuration, dialogs - Uses constants) ---
  void _regenerateBokehParticles() {
      if (!mounted) return;
      final mediaQueryData = MediaQuery.of(context);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
          SchedulerBinding.instance.addPostFrameCallback((_) => _regenerateBokehParticles());
          return;
      }
      final currentSize = mediaQueryData.size;
      final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
      final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
      final currentPalette = settings.selectedPalette;
      // --- UPDATED: Use constant for particle count ---
      final newParticles = createBokehParticles(currentSize, currentThemeIsDark, kBokehParticleCount, currentPalette);
      setState(() { _particles = newParticles; _particlesInitialized = true; _lastScreenSize = currentSize; _lastThemeIsDark = currentThemeIsDark; _lastPaletteUsed = currentPalette; });
  }

  void _updateBokehIfNeeded() {
      if (!mounted) return;
      final mediaQueryData = MediaQuery.of(context);
      if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
          SchedulerBinding.instance.addPostFrameCallback((_) => _updateBokehIfNeeded());
          return;
      }
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final currentSize = mediaQueryData.size;
      final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
      final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
      final currentPalette = settings.selectedPalette;
      bool needsUpdate = !_particlesInitialized || currentThemeIsDark != _lastThemeIsDark;
      if (needsUpdate) {
          if(!_particlesInitialized) { _lastScreenSize = currentSize; }
          _regenerateBokehParticles();
      } else if (_lastScreenSize == null && _particlesInitialized) {
          _lastScreenSize = currentSize;
      }
      _lastPaletteUsed = currentPalette;
  }

  String _formatDuration(Duration duration) { String twoDigits(int n) => n.toString().padLeft(2, '0'); String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60)); String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60)); if (duration.inHours > 0) { return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds"; } else { return "$twoDigitMinutes:$twoDigitSeconds"; } }

  void _showSettingsSheet(BuildContext context) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          // --- UPDATED: Use constant for radius ---
          shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(kLargeRadius)), ),
          // --- UPDATED: Use constant factor for height ---
          constraints: BoxConstraints( maxHeight: MediaQuery.of(context).size.height * 0.80, ), // Keep factor or make constant
          builder: (BuildContext sheetContext) {
              final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
              // --- UPDATED: Use constant opacity ---
              final glassColor = (isDark ? Colors.black : Colors.white).withOpacity(kMediumOpacity);
              final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(kLowOpacity);
              return ClipRRect(
                  // --- UPDATED: Use constant for radius ---
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(kLargeRadius)),
                  child: BackdropFilter(
                      // --- UPDATED: Use constant for blur ---
                      filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Keep specific or make constant
                      child: Container(
                          decoration: BoxDecoration(
                              color: glassColor,
                              // --- UPDATED: Use constant for radius ---
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(kLargeRadius)),
                              // --- UPDATED: Use constant for border width ---
                              border: Border(top: BorderSide(color: glassBorder, width: 0.5)), // Keep specific or make constant
                          ),
                          // --- UPDATED: Use constant for padding ---
                          child: Padding( padding: const EdgeInsets.only(top: kDefaultPadding), child: SettingsContent(), )
                      ),
                  ),
              );
          },
      );
  }

  void _showCompletionDialog(BuildContext context, Duration finalTime) {
  if (kDebugMode) { print("--- Completion Dialog: finalTime = $finalTime ---"); }
  if (mounted) { setState(() { _completionDialogShown = true; }); }
  _confettiController.play();

  // Access providers and theme outside the builder for clarity
  final gameProvider = Provider.of<GameProvider>(context, listen: false);
  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  final ThemeData dialogTheme = Theme.of(context);
  final TextTheme dialogTextTheme = dialogTheme.textTheme;
  final bool isDark = dialogTheme.brightness == Brightness.dark;
  final String difficultyLabel = difficultyLabels[gameProvider.currentPuzzleDifficulty ?? 1] ?? 'Medium';


  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // --- Custom Dialog Look ---
      return Dialog(
        // --- UPDATED: Use constant for radius ---
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kLargeRadius)), // Larger radius
        elevation: kHighElevation, // Add some elevation
        backgroundColor: Colors.transparent, // Make standard background transparent
        child: ClipRRect(
          // --- UPDATED: Use constant for radius ---
          borderRadius: BorderRadius.circular(kLargeRadius),
          child: BackdropFilter(
             // --- UPDATED: Use constant for blur ---
            filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Blur background
            child: Container(
               // --- UPDATED: Use constants for padding/opacity ---
              padding: const EdgeInsets.all(kExtraLargePadding),
              decoration: BoxDecoration(
                // --- UPDATED: Use constant for opacity ---
                color: dialogTheme.colorScheme.surface.withOpacity(isDark ? kHighOpacity : kVeryHighOpacity), // Use surface color with opacity
                borderRadius: BorderRadius.circular(kLargeRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // --- Enhanced Title ---
                  Icon(
                    Icons.emoji_events_outlined, // Trophy Icon
                    color: dialogTheme.colorScheme.primary,
                    size: 40.0, // Larger icon
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kSmallSpacing),
                  Text(
                    'Puzzle Solved!',
                    style: GoogleFonts.nunito(
                        textStyle: dialogTextTheme.headlineSmall, // Larger title
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kMediumSpacing),
                  Text(
                    'Difficulty: $difficultyLabel', // Show difficulty
                    style: GoogleFonts.nunito(
                        textStyle: dialogTextTheme.bodyMedium),
                     textAlign: TextAlign.center,
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kSmallSpacing), // Smaller space
                  Text(
                    'Your Time:',
                    style: GoogleFonts.nunito(
                        textStyle: dialogTextTheme.bodyMedium),
                    textAlign: TextAlign.center,
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kSmallSpacing), // Smaller space
                  Text(
                    _formatDuration(finalTime),
                    style: GoogleFonts.nunito(
                       // --- UPDATED: Use constant for font size multiplier ---
                      fontSize: dialogTextTheme.headlineMedium!.fontSize, // Larger time display
                      fontWeight: FontWeight.bold,
                      color: dialogTheme.colorScheme.primary, // Use primary color for time
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // --- UPDATED: Use constant for spacing ---
                  const SizedBox(height: kExtraLargeSpacing), // More space before buttons

                  // --- Action Buttons ---
                  Column( // Use Column for buttons
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons fill width
                    children: [
                       ElevatedButton.icon(
                         icon: const Icon(Icons.share_outlined),
                         label: Text('Brag to Friends!', style: GoogleFonts.nunito()),
                         style: ElevatedButton.styleFrom(
                           // --- UPDATED: Use constant for padding ---
                           padding: const EdgeInsets.symmetric(vertical: kMediumPadding),
                           backgroundColor: dialogTheme.colorScheme.secondaryContainer,
                           foregroundColor: dialogTheme.colorScheme.onSecondaryContainer,
                         ),
                         onPressed: () {
                            // --- Share Functionality ---
                            final String timeStr = _formatDuration(finalTime);
                            final String shareText = "I just solved a $difficultyLabel Rainboku puzzle in $timeStr! 🌈 Can you beat my time? #Rainboku #SudokuChallenge";
                            Share.share(shareText);
                         },
                       ),
                       // --- UPDATED: Use constant for spacing ---
                       const SizedBox(height: kSmallSpacing), // Space between buttons
                       TextButton(
                         child: Text('New Game', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                         onPressed: () {
                           final int initialDifficulty = gameProvider.initialDifficultySelection ?? 1;
                           if (initialDifficulty == -1) {
                             settingsProvider.selectRandomPalette();
                           }
                           if (mounted) {
                             setState(() { _completionDialogShown = false; });
                           }
                           Navigator.of(dialogContext).pop(); // Close the dialog first
                           gameProvider.loadNewPuzzle(difficulty: initialDifficulty);
                           _regenerateBokehParticles(); // Assuming this is still needed
                           _startIntroAnimationSequenceIfNeeded(); // Assuming this is still needed
                         },
                       ),
                       TextButton(
                         child: Text('Close', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge?.copyWith(color: dialogTheme.colorScheme.onSurface.withOpacity(0.7)))), // Slightly muted close
                         onPressed: () {
                           if (mounted) {
                             setState(() { _completionDialogShown = false; });
                           }
                           Navigator.of(dialogContext).pop();
                           // Optional: Decide if you want to pause the game or leave it completed
                           // gameProvider.pauseGame();
                         },
                       ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 8 ? retroColors.sublist(0, 8) : List.generate(8, (_) => currentTheme.appBarTheme.titleTextStyle?.color ?? currentTheme.colorScheme.primary);
    final TextStyle? baseTitleStyle = currentTheme.appBarTheme.titleTextStyle;

    final bool isCompleted = context.select((GameProvider gp) => gp.isCompleted);
    if (isCompleted && !_completionDialogShown) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && isCompleted && !_completionDialogShown) { final finalTime = Provider.of<GameProvider>(context, listen: false).elapsedTime; _showCompletionDialog(context, finalTime); } }); }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
         // --- UPDATED: Use constants for opacity/elevation ---
         backgroundColor: currentTheme.brightness == Brightness.dark ? Colors.black.withOpacity(kLowMediumOpacity) : Colors.white.withOpacity(kLowOpacity),
         elevation: 0, // kZeroElevation if defined
         foregroundColor: currentTheme.colorScheme.onSurface,
         title: RichText( text: TextSpan( style: baseTitleStyle, children: <TextSpan>[ TextSpan(text: 'R', style: TextStyle(color: titleColors[1])), TextSpan(text: 'a', style: TextStyle(color: titleColors[2])), TextSpan(text: 'i', style: TextStyle(color: titleColors[0])), TextSpan(text: 'n', style: TextStyle(color: titleColors[3])), TextSpan(text: 'b', style: TextStyle(color: titleColors[4])), TextSpan(text: 'o', style: TextStyle(color: titleColors[5])), TextSpan(text: 'k', style: TextStyle(color: titleColors[6])), TextSpan(text: 'u', style: TextStyle(color: titleColors[7])), ], ), ),
         leading: IconButton( icon: const Icon(Icons.arrow_back), onPressed: () { gameProvider.pauseGame(); Navigator.pop(context); }, ),
         actions: [
             Selector<GameProvider, Tuple2<bool, bool>>( selector: (_, game) => Tuple2(game.isPaused, game.isCompleted), builder: (context, data, child) { final isPaused = data.item1; final isCompleted = data.item2; return IconButton( icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null), tooltip: isPaused ? 'Resume' : 'Pause', onPressed: isCompleted ? null : () { final game = Provider.of<GameProvider>(context, listen: false); if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); } }, ); } ),
            IconButton( icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () { _showSettingsSheet(context); }, ),
         ],
       ),
      body: Stack( children: [
            Container( decoration: BoxDecoration( gradient: backgroundGradient ?? defaultFallbackGradient ) ),
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles ), size: MediaQuery.of(context).size, ),
             Align( alignment: Alignment.topCenter,
                child: ConfettiWidget(
                   confettiController: _confettiController,
                   blastDirectionality: BlastDirectionality.explosive,
                   shouldLoop: false,
                   // --- UPDATED: Use constants for confetti ---
                   numberOfParticles: kConfettiParticleCount,
                   gravity: kConfettiGravity,
                   emissionFrequency: kConfettiEmissionFrequency,
                   maxBlastForce: kConfettiMaxBlastForce,
                   minBlastForce: kConfettiMinBlastForce,
                   particleDrag: kConfettiParticleDrag,
                   colors: settingsProvider.selectedPalette.colors,
                   createParticlePath: (size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2)),
                ),
             ),
            // --- UPDATED: Use constants for padding ---
            SafeArea( minimum: const EdgeInsets.only(top: kDefaultPadding, right: kDefaultPadding),
              child: Stack( children: [
                  Padding( padding: const EdgeInsets.only(left: kMediumPadding, right: kMediumPadding, bottom: kMediumPadding, top: 0),
                    child: Column( children: <Widget>[
                          // --- UPDATED: Use constant for padding ---
                          Padding( padding: const EdgeInsets.symmetric(vertical: kMediumSpacing), child: Consumer<SettingsProvider>( builder: (context, settings, child) { return settings.timerEnabled ? Center(child: TimerWidget()) : const SizedBox(height: 50); }, ), ),
                          // --- UPDATED: Use constant for spacing ---
                          const SizedBox(height: kMediumSpacing),
                          Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ),
                          // --- UPDATED: Use constant for spacing ---
                          const SizedBox(height: kLargeSpacing),
                          Stack( alignment: Alignment.center, children: [
                              Visibility( visible: !gameProvider.isCompleted, maintainState: true, maintainAnimation: true, maintainSize: true, child: Column( mainAxisSize: MainAxisSize.min, children: [ const PaletteSelectorWidget(), const SizedBox(height: kLargeSpacing), GameControls(key: _gameControlsKey), ], ), ),
                              Visibility( visible: gameProvider.isCompleted,
                                child: Padding(
                                  // --- UPDATED: Use constant for padding ---
                                  padding: const EdgeInsets.symmetric(vertical: kExtraLargeSpacing),
                                  child: Center( child: ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      // --- UPDATED: Use constant for font size ---
                                      label: Text('New Game', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: currentTheme.colorScheme.primaryContainer,
                                        foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                                        // --- UPDATED: Use constants for padding/font/elevation/radius ---
                                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Keep 35 specific or make constant
                                        textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600),
                                        elevation: kHighElevation,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use medium radius?
                                      ),
                                      onPressed: () { /* ... New Game Logic ... */
                                         final game = Provider.of<GameProvider>(context, listen: false);
                                         final settings = Provider.of<SettingsProvider>(context, listen: false);
                                         final int initialDifficulty = game.initialDifficultySelection ?? 1;
                                         if (initialDifficulty == -1) { settings.selectRandomPalette(); }
                                         if (mounted) { setState(() { _completionDialogShown = false; }); }
                                         game.loadNewPuzzle(difficulty: initialDifficulty);
                                         _regenerateBokehParticles();
                                         _startIntroAnimationSequenceIfNeeded();
                                       },
                                    ),
                                  ),
                                ),
                              ),
                           ],
                          ),
                          // --- UPDATED: Use constant for spacing ---
                          const SizedBox(height: kMediumSpacing),
                      ], ), ),
                  Align( alignment: Alignment.topRight,
                     // --- UPDATED: Use constant for padding ---
                     child: Padding( padding: const EdgeInsets.only(top: 4.0, right: 4.0), // Keep specific or make constant
                       child: Consumer<GameProvider>( builder: (context, game, child) {
                          final difficultyLevel = game.currentPuzzleDifficulty;
                          final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : '';
                          if (difficultyText.isEmpty) return const SizedBox.shrink();
                          return Chip(
                              label: Text( difficultyText, style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.labelSmall, color: currentTheme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, ) ),
                              // --- UPDATED: Use constant for opacity ---
                              backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(kMediumHighOpacity),
                              // --- UPDATED: Use constant for padding ---
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0), // Keep specific or make constant
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                          );
                        }
                       ),
                     ),
                  ),
                ], ), ), ], ), );
  }
}

// Helper class Tuple2 (Unchanged)
class Tuple2<T1, T2> { final T1 item1; final T2 item2; Tuple2(this.item1, this.item2); @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2; @override int get hashCode => Object.hash(item1, item2); }