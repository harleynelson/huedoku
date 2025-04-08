// File: lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
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
import 'package:huedoku/color_puns.dart';
import 'package:web/web.dart' as web;


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
  if (!mounted) return;

  setState(() { _completionDialogShown = true; });
  _confettiController.play();

  final gameProvider = Provider.of<GameProvider>(context, listen: false);
  // No need for settingsProvider here unless used later
  // final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  final ThemeData dialogTheme = Theme.of(context);
  final TextTheme dialogTextTheme = dialogTheme.textTheme;
  final bool isDark = dialogTheme.brightness == Brightness.dark;
  final String difficultyLabel = difficultyLabels[gameProvider.currentPuzzleDifficulty ?? 1] ?? 'Medium';
  final int hints = gameProvider.hintsUsed;
  final String? puzzleCode = gameProvider.currentPuzzleString;

  // --- Get a random pun ---
  final String completionTitle = getRandomColorPun();

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
              child: Container(
                constraints: const BoxConstraints(maxWidth: kHomeMaxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // --- Title and Info ---
                    Icon( Icons.emoji_events_outlined, color: dialogTheme.colorScheme.primary, size: 40.0, ),
                    const SizedBox(height: kSmallSpacing),
                    // --- Use the random pun here ---
                    Text(
                      completionTitle, // Use the randomly selected pun
                      style: GoogleFonts.nunito(
                        textStyle: dialogTextTheme.headlineSmall,
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center, // Center align title
                    ),
                    // --- End Title Change ---
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

                    // --- Action Buttons (Remain the same) ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon( /* ... Brag Button ... */
                          icon: Icon(kIsWeb ? Icons.copy_outlined : Icons.share_outlined),
                          label: Text(kIsWeb ? 'Brag about it' : 'Brag about it', style: GoogleFonts.nunito()),
                          style: ElevatedButton.styleFrom( /* ... Style ... */
                           padding: const EdgeInsets.symmetric(vertical: kMediumPadding),
                           backgroundColor: dialogTheme.colorScheme.secondaryContainer,
                           foregroundColor: dialogTheme.colorScheme.onSecondaryContainer,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)),
                          ),
                          onPressed: () { /* ... Brag logic ... */
                              final String timeStr = _formatDuration(finalTime);
                              String shareText = "I solved a $difficultyLabel Rainboku puzzle in $timeStr with $hints hint${hints == 1 ? '' : 's'}! ($completionTitle) 🌈"; // Include pun
                              if (puzzleCode != null) {
                                 const String baseDomain = "https://your-app-domain.com"; // Replace
                                 final String encodedCode = Uri.encodeQueryComponent(puzzleCode);
                                 final String fullUrl = "$baseDomain/#/play?code=$encodedCode";
                                 shareText += "\n\nThink you can beat me? Try the same puzzle! #Rainboku\n$fullUrl";
                              } else { shareText += " #Rainboku"; }
                              if (kIsWeb) { Clipboard.setData(ClipboardData(text: shareText)); if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar( SnackBar( content: const Text('Brag text with link copied to clipboard!'), duration: kSnackbarDuration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), ), ); }
                              } else { Share.share(shareText); }
                          },
                        ),
                        const SizedBox(height: kSmallSpacing),
                        if (puzzleCode != null) ElevatedButton.icon( /* ... Copy Code Only Button ... */
                              icon: const Icon(Icons.copy_all_outlined),
                              label: Text('Copy Puzzle Code', style: GoogleFonts.nunito()),
                              style: ElevatedButton.styleFrom( /* ... Style ... */
                                padding: const EdgeInsets.symmetric(vertical: kMediumPadding),
                                backgroundColor: dialogTheme.colorScheme.tertiaryContainer,
                                foregroundColor: dialogTheme.colorScheme.onTertiaryContainer,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)),
                              ),
                              onPressed: () { /* ... Clipboard logic ... */
                                 Clipboard.setData(ClipboardData(text: puzzleCode)); if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar( SnackBar( content: const Text('Puzzle code copied to clipboard!'), duration: kSnackbarDuration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), ), ); }
                              },
                            ),
                        if (puzzleCode != null) const SizedBox(height: kLargeSpacing),
                        ElevatedButton.icon( /* ... New Game Button ... */
                          icon: const Icon(Icons.refresh),
                          label: Text('New Game', style: GoogleFonts.nunito()),
                          style: ElevatedButton.styleFrom( /* ... Style ... */
                            padding: const EdgeInsets.symmetric(vertical: kLargePadding),
                            backgroundColor: dialogTheme.colorScheme.primaryContainer,
                            foregroundColor: dialogTheme.colorScheme.onPrimaryContainer,
                            textStyle: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)),
                          ),
                          onPressed: () { /* ... New Game Logic ... */
                               final int initialDifficulty = gameProvider.initialDifficultySelection ?? 1;
                               final settings = Provider.of<SettingsProvider>(context, listen: false); // Need settings here
                               if (initialDifficulty == -1) { settings.selectRandomPalette(); }
                               Navigator.of(dialogContext).pop();
                               if (mounted) { setState(() { _completionDialogShown = false; }); }
                               gameProvider.loadNewPuzzle(difficulty: initialDifficulty);
                               _regenerateBokehParticles();
                               _startIntroAnimationSequenceIfNeeded();
                           },
                        ),
                        const SizedBox(height: kSmallSpacing),
                        TextButton( /* ... Close Button ... */
                          child: Text('Close', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge?.copyWith(color: dialogTheme.colorScheme.onSurface.withOpacity(0.7)))),
                          onPressed: () { Navigator.of(dialogContext).pop(); },
                        ),
                      ],
                    ),
                  ],
                ),
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
    // Access providers and theme data
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    // Define a fallback gradient in case the theme extension is null
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );
    // Get colors for the title (handle potential palette size issues)
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 8 ? retroColors.sublist(0, 8) : List.generate(8, (i) => retroColors.isNotEmpty ? retroColors[i % retroColors.length] : currentTheme.colorScheme.primary);
    // Get base title style, providing a default if not defined in theme
    final TextStyle? baseTitleStyle = currentTheme.appBarTheme.titleTextStyle ?? GoogleFonts.nunito(fontSize: kLargeFontSize, fontWeight: FontWeight.bold);

    // Check completion status using selector for efficiency
    final bool isCompleted = context.select((GameProvider gp) => gp.isCompleted);

    // Schedule the completion dialog check after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Show dialog ONLY if mounted, game is completed AND the dialog hasn't been shown yet for this completion
       if (mounted && isCompleted && !_completionDialogShown) {
          final finalTime = Provider.of<GameProvider>(context, listen: false).elapsedTime;
          _showCompletionDialog(context, finalTime);
       }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
         backgroundColor: currentTheme.brightness == Brightness.dark ? Colors.black.withOpacity(kLowMediumOpacity) : Colors.white.withOpacity(kLowOpacity),
         elevation: 0,
         foregroundColor: currentTheme.colorScheme.onSurface,
         title: RichText( /* ... Title remains the same ... */
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
         // --- CORRECTED Back button logic ---
         leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Home',
            onPressed: () {
              print("[DEBUG] Back Button Pressed"); // Keep debug logs
              final router = GoRouter.of(context);
              final game = Provider.of<GameProvider>(context, listen: false);

              if (router.canPop()) {
                 // --- Scenario 1: Normal Navigation History Exists ---
                 print("[DEBUG] router.canPop() is TRUE - using context.pop()");
                 game.pauseGame(); // Pause game state
                 // Ensure pop happens after potential state update settles
                 Future.delayed(Duration.zero, () {
                   // Check if context is still valid after delay before popping
                   if (context.mounted) {
                     print("[DEBUG] Executing context.pop() after delay");
                     context.pop();
                   }
                 });

              } else {
                 // --- Scenario 2: No Navigation History (Likely URL Load) ---
                 print("[DEBUG] router.canPop() is FALSE - checking kIsWeb");
                 if (kIsWeb) {
                    // --- Sub-Scenario 2a: Web + URL Load -> Temporary Fix (Delayed) ---
                    print("[DEBUG] kIsWeb is TRUE - attempting delayed web reload");
                    final homeUrl = '/rainboku/#/'; // Adjust if needed
                    print("[DEBUG] Scheduling window.location.href set to: $homeUrl");
                    // Use Future.delayed to push execution slightly later
                    Future.delayed(Duration.zero, () {
                      print("[DEBUG] Executing window.location.href = homeUrl");
                      try {
                         web.window.location.href = homeUrl;
                         // Note: No print after this will execute if reload is successful
                      } catch (e) {
                         // This might not be reachable if href works, but good practice
                         print("[DEBUG] ERROR setting window.location.href: $e");
                      }
                    });
                    // No game pause needed as page reloads

                 } else {
                    // --- Sub-Scenario 2b: Non-Web + URL Load (Delayed) ---
                    print("[DEBUG] kIsWeb is FALSE - using delayed context.go('/')");
                    game.pauseGame(); // Pause game state
                    // Use Future.delayed before navigation
                    Future.delayed(Duration.zero, () {
                      // Check if context is still valid after delay
                      if (context.mounted) {
                        print("[DEBUG] Executing context.go('/') after delay");
                        context.go('/');
                      }
                    });
                 }
              }
            },
         ),
         // --- END CORRECTED Back button logic ---
         actions: [ /* ... Actions remain the same ... */
             // Pause/Resume Button
             Selector<GameProvider, Tuple2<bool, bool>>(
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
            // Settings Button
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () { _showSettingsSheet(context); },
            ),
         ],
       ),
      body: Stack( // Use Stack for background, particles, and main content
        children: [
            // Background Gradient Layer
            Container( decoration: BoxDecoration( gradient: backgroundGradient ?? defaultFallbackGradient ) ),
            // Bokeh Particle Layer (if initialized)
            if (_particlesInitialized)
               CustomPaint(
                 painter: BokehPainter(particles: _particles ),
                 size: MediaQuery.of(context).size, // Cover entire screen
               ),
             // Confetti Overlay Layer
             Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
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
            // Main Game Content Area Layer
            SafeArea( // Ensures content isn't obscured by notches, status bars, etc.
              minimum: const EdgeInsets.only(top: kDefaultPadding, right: kDefaultPadding), // Use constant for minimum safe padding
              child: Stack( // Use Stack again to overlay the difficulty chip
                children: [
                  Padding( // Padding for the main Column content
                    padding: const EdgeInsets.only(left: kMediumPadding, right: kMediumPadding, bottom: kMediumPadding, top: 0), // Use constants
                    child: Column( // Main vertical layout
                      children: <Widget>[
                          // Timer or Placeholder Area
                          Padding(
                             padding: const EdgeInsets.symmetric(vertical: kMediumSpacing), // Use constant
                             child: Consumer<SettingsProvider>( // Listen to settings for timer visibility
                               builder: (context, settings, child) {
                                 return settings.timerEnabled ? Center(child: TimerWidget()) : const SizedBox(height: 50); // Show timer or reserve space
                               },
                             ),
                          ),
                          const SizedBox(height: kMediumSpacing), // Use constant

                          // Sudoku Grid Area (takes remaining space)
                          Expanded(
                             child: Center( // Center the grid within the expanded space
                                child: AspectRatio( // Ensure the grid is square
                                  aspectRatio: 1.0,
                                  child: SudokuGridWidget() // The main interactive grid
                                )
                             )
                          ),
                          const SizedBox(height: kLargeSpacing), // Use constant

                          // Controls Area (Palette/Buttons or New Game button)
                          Stack( // Stack to switch between controls and New Game button
                             alignment: Alignment.center,
                             children: [
                               // Palette and Game Controls (Visible when game is NOT completed)
                               Visibility(
                                 visible: !gameProvider.isCompleted,
                                 maintainState: true, // Keep state when hidden
                                 maintainAnimation: true, // Keep animation state when hidden
                                 maintainSize: true, // Keep occupying space when hidden
                                 child: Column(
                                    mainAxisSize: MainAxisSize.min, // Shrink-wrap vertically
                                    children: [
                                       const PaletteSelectorWidget(), // Color/input palette
                                       const SizedBox(height: kLargeSpacing), // Use constant
                                       GameControls(key: _gameControlsKey), // Game action buttons
                                    ],
                                 ),
                               ),

                               // --- REVERTED Visibility for New Game Button ---
                               Visibility(
                                 // Visible simply if the game is completed.
                                 visible: gameProvider.isCompleted,
                                 child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: kExtraLargeSpacing), // Use constant for padding
                                    child: Center(
                                       child: ElevatedButton.icon(
                                          icon: const Icon(Icons.refresh),
                                          label: Text('New Game', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)), // Use constant
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: currentTheme.colorScheme.primaryContainer,
                                            foregroundColor: currentTheme.colorScheme.onPrimaryContainer,
                                            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), // Use constant
                                            textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600), // Use constant
                                            elevation: kHighElevation, // Use constant
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), // Use constant
                                          ),
                                          onPressed: () {
                                             // Logic to start a new game
                                             final game = Provider.of<GameProvider>(context, listen: false);
                                             final settings = Provider.of<SettingsProvider>(context, listen: false);
                                             final int initialDifficulty = game.initialDifficultySelection ?? 1; // Default difficulty
                                             if (initialDifficulty == -1) { settings.selectRandomPalette(); } // Handle random difficulty selection
                                             // Reset dialog shown flag BEFORE loading the new puzzle
                                             if (mounted) { setState(() { _completionDialogShown = false; }); }
                                             game.loadNewPuzzle(difficulty: initialDifficulty); // Load it
                                             _regenerateBokehParticles(); // Update background
                                             _startIntroAnimationSequenceIfNeeded(); // Trigger intro animation if applicable
                                           },
                                        ),
                                    ),
                                 ),
                               ),
                                // --- End REVERTED Visibility ---
                             ],
                           ),
                          const SizedBox(height: kMediumSpacing), // Bottom padding inside SafeArea
                      ],
                    ),
                  ),
                  // Difficulty Chip (Overlayed in top-right corner)
                  Align(
                     alignment: Alignment.topRight,
                     child: Padding(
                       padding: const EdgeInsets.only(top: 4.0, right: 4.0), // Fine-tune position
                       child: Consumer<GameProvider>( // Listen only to GameProvider for difficulty
                         builder: (context, game, child) {
                            final difficultyLevel = game.currentPuzzleDifficulty;
                            final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : ''; // Get label from map
                            if (difficultyText.isEmpty) return const SizedBox.shrink(); // Render nothing if no text

                            // Display the difficulty in a small Chip
                            return Chip(
                                label: Text(
                                   difficultyText,
                                   style: GoogleFonts.nunito(
                                      textStyle: currentTheme.textTheme.labelSmall, // Use small label style
                                      color: currentTheme.colorScheme.onSecondaryContainer, // Ensure contrast
                                      fontWeight: FontWeight.w600,
                                   )
                                ),
                                backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(kMediumHighOpacity), // Use constant opacity
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0), // Compact padding
                                visualDensity: VisualDensity.compact, // Reduce chip size
                                side: BorderSide.none, // No border
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
  }}

// Helper class Tuple2 (Unchanged)
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
  @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2;
  @override int get hashCode => Object.hash(item1, item2);
}