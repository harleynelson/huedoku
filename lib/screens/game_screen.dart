// File: lib/screens/game_screen.dart

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
import 'package:huedoku/constants.dart';
// --- Import for Clipboard ---
import 'package:flutter/services.dart';
// --- Import for Sharing ---
import 'package:share_plus/share_plus.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _completionDialogShown = false; // Tracks if dialog is shown *for the current completion*
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
     _confettiController = ConfettiController(duration: kConfettiDuration);
     WidgetsBinding.instance.addPostFrameCallback((_) {
        _startIntroAnimationSequenceIfNeeded();
     });
  }

  @override void didChangeDependencies() {
     super.didChangeDependencies();
     _updateBokehIfNeeded();

     // --- Reset dialog shown flag if puzzle is no longer completed ---
     // This handles cases where the user might undo back from a completed state
     final gameProvider = Provider.of<GameProvider>(context, listen: false);
     if (!gameProvider.isCompleted && _completionDialogShown) {
        if (mounted) {
           setState(() {
              _completionDialogShown = false;
           });
        }
     }
  }

  @override void dispose() {
    _confettiController.dispose();
    _introAnimationTimer?.cancel();
    super.dispose();
  }

  // --- startIntroAnimationSequenceIfNeeded, _regenerateBokehParticles, _updateBokehIfNeeded, _formatDuration, _showSettingsSheet remain the same ---
  void _startIntroAnimationSequenceIfNeeded() {
    if (!mounted) return;
    _introAnimationTimer?.cancel();

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (gameProvider.isPuzzleLoaded && settingsProvider.cellOverlay == CellOverlay.none) {
      _introAnimationTimer = Timer(kIntroSequenceDelay, () {
        if (!mounted) return;
        gameProvider.triggerIntroNumberAnimation();

        _introAnimationTimer = Timer(kIntroHighlightDelay, () {
          if (!mounted) return;
          _gameControlsKey.currentState?.triggerHighlight();
        });
      });
    } else {
       gameProvider.resetIntroNumberAnimation();
    }
  }

  void _regenerateBokehParticles() {
      if (!mounted) return;
      final mediaQueryData = MediaQuery.of(context);
      if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) _regenerateBokehParticles();
          });
          return;
      }

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final currentSize = mediaQueryData.size;
      final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
      final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
      final currentPalette = settings.selectedPalette;
      final newParticles = createBokehParticles(currentSize, currentThemeIsDark, kBokehParticleCount, currentPalette);

      if (mounted) {
        setState(() {
           _particles = newParticles;
           _particlesInitialized = true;
           _lastScreenSize = currentSize;
           _lastThemeIsDark = currentThemeIsDark;
           _lastPaletteUsed = currentPalette;
        });
      }
  }

  void _updateBokehIfNeeded() {
      if (!mounted) return;
      final mediaQueryData = MediaQuery.of(context);
       if (mediaQueryData.size.isEmpty || mediaQueryData.size.width <= 0 || mediaQueryData.size.height <= 0) {
           SchedulerBinding.instance.addPostFrameCallback((_) {
               if (mounted) _updateBokehIfNeeded();
           });
           return;
       }

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final currentSize = mediaQueryData.size;
      final currentThemeData = appThemes[settings.selectedThemeKey] ?? appThemes[lightThemeKey]!;
      final currentThemeIsDark = currentThemeData.brightness == Brightness.dark;
      final currentPalette = settings.selectedPalette;
      bool needsUpdate = !_particlesInitialized ||
                         currentThemeIsDark != _lastThemeIsDark ||
                         currentPalette != _lastPaletteUsed ||
                         currentSize != _lastScreenSize;

      if (needsUpdate) {
          if(!_particlesInitialized) { _lastScreenSize = currentSize; }
          _regenerateBokehParticles();
      } else if (_lastScreenSize == null && _particlesInitialized) {
          _lastScreenSize = currentSize;
      }
      _lastPaletteUsed = currentPalette;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
       return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
       return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void _showSettingsSheet(BuildContext context) {
      showModalBottomSheet( /* ... same as before ... */
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(kLargeRadius)), ),
          constraints: BoxConstraints( maxHeight: MediaQuery.of(context).size.height * 0.80, ),
          builder: (BuildContext sheetContext) {
              final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
              final glassColor = (isDark ? Colors.black : Colors.white).withOpacity(kMediumOpacity);
              final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(kLowOpacity);
              return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(kLargeRadius)),
                  child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                          decoration: BoxDecoration(
                              color: glassColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(kLargeRadius)),
                              border: Border(top: BorderSide(color: glassBorder, width: 0.5)),
                          ),
                          child: Padding(
                             padding: const EdgeInsets.only(top: kDefaultPadding),
                             child: SettingsContent(),
                          )
                      ),
                  ),
              );
          },
       );
  }

  // --- UPDATED Completion Dialog ---
  void _showCompletionDialog(BuildContext context, Duration finalTime) {
    if (!mounted) return; // Check if mounted before proceeding

    // --- SET FLAG FIRST ---
    // We set this immediately to prevent build triggering it again right away
    setState(() { _completionDialogShown = true; });
    _confettiController.play();

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final ThemeData dialogTheme = Theme.of(context);
    final TextTheme dialogTextTheme = dialogTheme.textTheme;
    final bool isDark = dialogTheme.brightness == Brightness.dark;
    final String difficultyLabel = difficultyLabels[gameProvider.currentPuzzleDifficulty ?? 1] ?? 'Medium';
    final int hints = gameProvider.hintsUsed;
    final String? puzzleCode = gameProvider.currentPuzzleString; // Get the code

    if (kDebugMode) {
      print("Debug: Puzzle Code in Dialog = $puzzleCode");
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kLargeRadius)),
          elevation: kHighElevation,
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kLargeRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                padding: const EdgeInsets.all(kExtraLargePadding),
                decoration: BoxDecoration(
                  color: dialogTheme.colorScheme.surface.withOpacity(isDark ? kHighOpacity : kVeryHighOpacity),
                  borderRadius: BorderRadius.circular(kLargeRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // --- Title and Info ---
                    Icon( Icons.emoji_events_outlined, color: dialogTheme.colorScheme.primary, size: 40.0, ),
                    const SizedBox(height: kSmallSpacing),
                    Text( 'Puzzle Solved!', style: GoogleFonts.nunito( textStyle: dialogTextTheme.headlineSmall, fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),
                    const SizedBox(height: kMediumSpacing),
                    Text( 'Difficulty: $difficultyLabel', style: GoogleFonts.nunito( textStyle: dialogTextTheme.bodyMedium), textAlign: TextAlign.center, ),
                    const SizedBox(height: kSmallSpacing),
                    Text( 'Hints Used: $hints', style: GoogleFonts.nunito( textStyle: dialogTextTheme.bodyMedium), textAlign: TextAlign.center, ),
                    const SizedBox(height: kSmallSpacing),
                    Text( 'Your Time:', style: GoogleFonts.nunito( textStyle: dialogTextTheme.bodyMedium), textAlign: TextAlign.center, ),
                    const SizedBox(height: kSmallSpacing),
                    Text( _formatDuration(finalTime),
                      style: GoogleFonts.nunito(
                        fontSize: dialogTextTheme.headlineMedium!.fontSize,
                        fontWeight: FontWeight.bold,
                        color: dialogTheme.colorScheme.primary,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: kExtraLargeSpacing),

                    // --- Action Buttons ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                         ElevatedButton.icon(
                           icon: const Icon(Icons.share_outlined),
                           // --- Updated Brag Text to INCLUDE puzzle code ---
                           label: Text('Brag about it', style: GoogleFonts.nunito()),
                           style: ElevatedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: kMediumPadding),
                             backgroundColor: dialogTheme.colorScheme.secondaryContainer,
                             foregroundColor: dialogTheme.colorScheme.onSecondaryContainer,
                           ),
                           onPressed: () {
                              final String timeStr = _formatDuration(finalTime);
                              // --- Construct share text WITH puzzle code ---
                              String shareText = "I solved a $difficultyLabel Rainboku puzzle in $timeStr with $hints hint${hints == 1 ? '' : 's'}! 🌈";
                              if (puzzleCode != null) {
                                 shareText += "\n\nThink you can beat me? Try the same puzzle! #RainbokuChallenge\n\nCode: $puzzleCode ";
                              } else {
                                 shareText += " #Rainboku";
                              }
                              Share.share(shareText);
                           },
                         ),
                         const SizedBox(height: kSmallSpacing),
                         // --- Button to copy JUST the code ---
                         if (puzzleCode != null)
                           ElevatedButton.icon(
                              icon: const Icon(Icons.copy_all_outlined),
                              label: Text('Copy Puzzle Code', style: GoogleFonts.nunito()),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: kMediumPadding),
                                backgroundColor: dialogTheme.colorScheme.tertiaryContainer,
                                foregroundColor: dialogTheme.colorScheme.onTertiaryContainer,
                              ),
                              onPressed: () {
                                 Clipboard.setData(ClipboardData(text: puzzleCode));
                                 if (dialogContext.mounted) {
                                     ScaffoldMessenger.of(dialogContext).showSnackBar(
                                         SnackBar(
                                             content: const Text('Puzzle code copied to clipboard!'),
                                             duration: kSnackbarDuration,
                                             behavior: SnackBarBehavior.floating,
                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)),
                                         ),
                                     );
                                 }
                              },
                           ),
                         if (puzzleCode != null) const SizedBox(height: kSmallSpacing),
                         // --- New Game Button ---
                         TextButton(
                           child: Text('New Game', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge)),
                           onPressed: () {
                                final int initialDifficulty = gameProvider.initialDifficultySelection ?? 1;
                                if (initialDifficulty == -1) { settingsProvider.selectRandomPalette(); }
                                Navigator.of(dialogContext).pop(); // Close dialog FIRST
                                // --- Reset flag BEFORE loading new puzzle ---
                                if (mounted) { setState(() { _completionDialogShown = false; }); }
                                gameProvider.loadNewPuzzle(difficulty: initialDifficulty);
                                _regenerateBokehParticles();
                                _startIntroAnimationSequenceIfNeeded();
                            },
                         ),
                         // --- Close Button ---
                         TextButton(
                           child: Text('Close', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge?.copyWith(color: dialogTheme.colorScheme.onSurface.withOpacity(0.7)))),
                           onPressed: () {
                                // --- Only pop, DO NOT reset the _completionDialogShown flag here ---
                                // This prevents it from immediately reopening if the build method runs again
                                // while isCompleted is still true. The flag will be reset by starting a
                                // new game or potentially by didChangeDependencies if state changes.
                                Navigator.of(dialogContext).pop();
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
    // ... (provider setup, theme, gradients, colors - same as before) ...
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 8 ? retroColors.sublist(0, 8) : List.generate(8, (i) => retroColors.isNotEmpty ? retroColors[i % retroColors.length] : currentTheme.colorScheme.primary);
    final TextStyle? baseTitleStyle = currentTheme.appBarTheme.titleTextStyle ?? GoogleFonts.nunito(fontSize: kLargeFontSize, fontWeight: FontWeight.bold);

    final bool isCompleted = context.select((GameProvider gp) => gp.isCompleted);

    // --- UPDATED Dialog Trigger Logic ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Show dialog ONLY if game is completed AND the dialog hasn't been shown for this completion yet
       if (mounted && isCompleted && !_completionDialogShown) {
          final finalTime = Provider.of<GameProvider>(context, listen: false).elapsedTime;
          _showCompletionDialog(context, finalTime);
       }
    });

    return Scaffold(
      // ... (Scaffold setup, AppBar, Stack with Background, Particles, Confetti - same as before) ...
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar( /* ... AppBar contents ... */
         backgroundColor: currentTheme.brightness == Brightness.dark ? Colors.black.withOpacity(kLowMediumOpacity) : Colors.white.withOpacity(kLowOpacity),
         elevation: 0,
         foregroundColor: currentTheme.colorScheme.onSurface,
         title: RichText( /* ... Title RichText ... */
           text: TextSpan(
             style: baseTitleStyle,
             children: <TextSpan>[
               TextSpan(text: 'R', style: TextStyle(color: titleColors[1 % titleColors.length])),
               TextSpan(text: 'a', style: TextStyle(color: titleColors[2 % titleColors.length])),
               TextSpan(text: 'i', style: TextStyle(color: titleColors[0 % titleColors.length])),
               TextSpan(text: 'n', style: TextStyle(color: titleColors[3 % titleColors.length])),
               TextSpan(text: 'b', style: TextStyle(color: titleColors[4 % titleColors.length])),
               TextSpan(text: 'o', style: TextStyle(color: titleColors[5 % titleColors.length])),
               TextSpan(text: 'k', style: TextStyle(color: titleColors[6 % titleColors.length])),
               TextSpan(text: 'u', style: TextStyle(color: titleColors[7 % titleColors.length])),
             ],
           ),
         ),
         leading: IconButton( /* ... Back Button ... */
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Home',
            onPressed: () {
              gameProvider.pauseGame();
              Navigator.pop(context);
            },
         ),
         actions: [ /* ... Pause/Resume and Settings Buttons ... */
             Selector<GameProvider, Tuple2<bool, bool>>( /* ... Pause/Resume Logic ... */
                selector: (_, game) => Tuple2(game.isPaused, game.isCompleted),
                builder: (context, data, child) {
                   final isPaused = data.item1;
                   final isCompleted = data.item2;
                   return IconButton(
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null),
                      tooltip: isCompleted ? 'Game Over' : (isPaused ? 'Resume' : 'Pause'),
                      onPressed: isCompleted ? null : () {
                         final game = Provider.of<GameProvider>(context, listen: false);
                         if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); }
                      },
                   );
                }
             ),
            IconButton( icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () { _showSettingsSheet(context); }, ),
         ],
       ),
      body: Stack(
        children: [
            Container( decoration: BoxDecoration( gradient: backgroundGradient ?? defaultFallbackGradient ) ),
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles ), size: MediaQuery.of(context).size, ),
             Align( alignment: Alignment.topCenter, child: ConfettiWidget( /* ... Confetti Setup ... */
                   confettiController: _confettiController,
                   blastDirectionality: BlastDirectionality.explosive,
                   shouldLoop: false,
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
            SafeArea(
              minimum: const EdgeInsets.only(top: kDefaultPadding, right: kDefaultPadding),
              child: Stack( // Stack for Difficulty Chip
                children: [
                  Padding( // Main Column Padding
                    padding: const EdgeInsets.only(left: kMediumPadding, right: kMediumPadding, bottom: kMediumPadding, top: 0),
                    child: Column( // Main Layout Column
                      children: <Widget>[
                          Padding( /* ... Timer Widget/SizedBox ... */
                             padding: const EdgeInsets.symmetric(vertical: kMediumSpacing),
                             child: Consumer<SettingsProvider>(
                               builder: (context, settings, child) {
                                 return settings.timerEnabled ? Center(child: TimerWidget()) : const SizedBox(height: 50);
                               },
                             ),
                          ),
                          const SizedBox(height: kMediumSpacing),
                          Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ), // Grid
                          const SizedBox(height: kLargeSpacing),
                          Stack( /* ... Palette/Controls vs New Game Button ... */
                             alignment: Alignment.center,
                             children: [
                               Visibility( /* ... Palette and Controls ... */
                                 visible: !gameProvider.isCompleted,
                                 maintainState: true, maintainAnimation: true, maintainSize: true,
                                 child: Column( mainAxisSize: MainAxisSize.min, children: [ const PaletteSelectorWidget(), const SizedBox(height: kLargeSpacing), GameControls(key: _gameControlsKey), ], ),
                               ),
                               Visibility( /* ... New Game Button ... */
                                 visible: gameProvider.isCompleted,
                                 child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: kExtraLargeSpacing),
                                    child: Center( child: ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: Text('New Game', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)),
                                      style: ElevatedButton.styleFrom( /* ... Button Style ... */
                                        backgroundColor: currentTheme.colorScheme.primaryContainer,
                                        foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst),
                                        textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600),
                                        elevation: kHighElevation,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)),
                                      ),
                                      onPressed: () { /* ... New Game Logic ... */
                                         final game = Provider.of<GameProvider>(context, listen: false);
                                         final settings = Provider.of<SettingsProvider>(context, listen: false);
                                         final int initialDifficulty = game.initialDifficultySelection ?? 1;
                                         if (initialDifficulty == -1) { settings.selectRandomPalette(); }
                                         // --- Reset flag before loading ---
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
                          const SizedBox(height: kMediumSpacing),
                      ],
                    ),
                  ),
                  Align( /* ... Difficulty Chip ... */
                     alignment: Alignment.topRight,
                     child: Padding(
                       padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                       child: Consumer<GameProvider>( builder: (context, game, child) {
                          final difficultyLevel = game.currentPuzzleDifficulty;
                          final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : '';
                          if (difficultyText.isEmpty) return const SizedBox.shrink();
                          return Chip( /* ... Chip Style ... */
                              label: Text( difficultyText, style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.labelSmall, color: currentTheme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, ) ),
                              backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(kMediumHighOpacity),
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                          );
                        }
                       ),
                     ),
                  ),
                ],
              ),
            ),
         ],
       ),
    );
  }
}

// Helper class Tuple2 (Unchanged)
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
  @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2;
  @override int get hashCode => Object.hash(item1, item2);
}