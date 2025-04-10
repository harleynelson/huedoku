// File: lib/screens/game_screen.dart
// Location: Entire File (Includes previous fixes for layout and ensures correct hint display in dialog)

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
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:huedoku/color_puns.dart';
import '../stub/web_interop_stub.dart'
    if (dart.library.html) 'package:web/web.dart'
    as web_interop;

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
     _confettiController = ConfettiController(duration: kConfettiDuration);
     WidgetsBinding.instance.addPostFrameCallback((_) {
        _startIntroAnimationSequenceIfNeeded();
     });
  }

  @override void didChangeDependencies() {
     super.didChangeDependencies();
     _updateBokehIfNeeded();
     final gameProvider = Provider.of<GameProvider>(context, listen: false);
     if (!gameProvider.isCompleted && _completionDialogShown) {
        if (mounted) { setState(() { _completionDialogShown = false; }); }
     }
  }

  @override void dispose() {
    _confettiController.dispose();
    _introAnimationTimer?.cancel();
    super.dispose();
  }

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

  // Updated to be static or moved outside if no instance state needed
  static String _formatDuration(Duration duration) {
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
      showModalBottomSheet(
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
                          child: const Padding(
                             padding: EdgeInsets.only(top: kDefaultPadding),
                             child: SettingsContent(),
                          )
                      ),
                  ),
              );
          },
       );
  }

  // Completion Dialog uses gameProvider.hintsUsed correctly
  void _showCompletionDialog(BuildContext context, Duration finalTime) {
    if (!mounted) return;

    setState(() { _completionDialogShown = true; });
    _confettiController.play();

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final ThemeData dialogTheme = Theme.of(context);
    final TextTheme dialogTextTheme = dialogTheme.textTheme;
    final bool isDark = dialogTheme.brightness == Brightness.dark;
    final String difficultyLabel = difficultyLabels[gameProvider.currentPuzzleDifficulty ?? 1] ?? 'Medium';
    final int hints = gameProvider.hintsUsed; // Hints used in this round
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
                      Icon( Icons.emoji_events_outlined, color: dialogTheme.colorScheme.primary, size: 40.0, ),
                      const SizedBox(height: kSmallSpacing),
                      Text( completionTitle, style: GoogleFonts.nunito( textStyle: dialogTextTheme.headlineSmall, fontWeight: FontWeight.bold ), textAlign: TextAlign.center, ),
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

                      // Action Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon( /* ... New Game Button ... */
                            icon: const Icon(Icons.refresh), label: Text('New Game', style: GoogleFonts.nunito()), style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: kLargePadding), backgroundColor: dialogTheme.colorScheme.primaryContainer, foregroundColor: dialogTheme.colorScheme.onPrimaryContainer, textStyle: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), ),
                            onPressed: () { final int initialDifficulty = gameProvider.initialDifficultySelection ?? 1; final settings = Provider.of<SettingsProvider>(context, listen: false); if (initialDifficulty == -1) { settings.selectRandomPalette(); } Navigator.of(dialogContext).pop(); if (mounted) { setState(() { _completionDialogShown = false; }); } gameProvider.loadNewPuzzle(difficulty: initialDifficulty); _regenerateBokehParticles(); _startIntroAnimationSequenceIfNeeded(); },
                          ),
                          const SizedBox(height: kLargeSpacing),
                          TextButton( child: Text('Challenge your friends', style: GoogleFonts.nunito(textStyle: dialogTextTheme.labelLarge?.copyWith(color: dialogTheme.colorScheme.onSurface.withOpacity(0.7)))), onPressed: () { }, ), // Placeholder

                          // --- UPDATED Share/Copy Web Link Button (Uses 'x') ---
                          ElevatedButton.icon(
                            icon: Icon(kIsWeb ? Icons.copy_outlined : Icons.share_outlined),
                            label: Text(kIsWeb ? 'Copy Web Link' : 'Send Web Link', style: GoogleFonts.nunito()),
                            style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: kMediumPadding), backgroundColor: dialogTheme.colorScheme.secondaryContainer, foregroundColor: dialogTheme.colorScheme.onSecondaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), ),
                            onPressed: () {
                                String? generatedCode;
                                final difficultyChar = gameProvider.currentPuzzleDifficulty != null && difficultyLabels.containsKey(gameProvider.currentPuzzleDifficulty)
                                                      ? (difficultyLabels[gameProvider.currentPuzzleDifficulty]![0].toUpperCase())
                                                      : (gameProvider.currentPuzzleDifficulty == -1 ? 'R' : 'M');
                                final timeInSeconds = finalTime.inSeconds;
                                final currentHintsUsed = hints;

                                StringBuffer boardSb = StringBuffer();
                                bool boardReconstructionOk = true;
                                try {
                                    if (gameProvider.board.isEmpty || gameProvider.board.length != kGridSize) throw Exception("Board not ready");
                                    for (int r = 0; r < kGridSize; r++) {
                                        if (gameProvider.board[r].length != kGridSize) throw Exception("Board row $r not ready");
                                        for (int c = 0; c < kGridSize; c++) {
                                            final cell = gameProvider.board[r][c];
                                            if (cell.isFixed && cell.value != null) { boardSb.write('${cell.value! + 1}'); }
                                            else { boardSb.write('0'); }
                                        }
                                    }
                                } catch(e) { boardReconstructionOk = false; if (kDebugMode) print("Error reconstructing board for sharing: $e"); }

                                if (boardReconstructionOk) {
                                   // Use 'x' as separator
                                   generatedCode = '$difficultyChar${'x'}$currentHintsUsed${'x'}$timeInSeconds${'x'}${boardSb.toString()}';
                                }

                                if (generatedCode != null) {
                                   // No need to encode 'x' for URL query parameter
                                   final String codeForUrl = generatedCode;
                                   final String fullUrl = "$baseDomain/#/play?code=$codeForUrl";
                                   if (kIsWeb) { Clipboard.setData(ClipboardData(text: fullUrl)); if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar( SnackBar( content: const Text('Web link copied to clipboard!'), duration: kSnackbarDuration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), ), ); } }
                                   else { Share.share(fullUrl); }
                                } else { if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar( SnackBar( content: const Text('Error generating share link.'), duration: kSnackbarDuration, backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), ), ); } }
                            },
                          ),
                          // --- END UPDATED Share/Copy Web Link Button ---

                          const SizedBox(height: kSmallSpacing),

                          // --- UPDATED Copy Puzzle Code Button (Uses 'x') ---
                          // Check if the *initial* board reconstruction works to enable button
                          if (true) // Simplified check, assumes board is always available here
                             ElevatedButton.icon(
                                icon: const Icon(Icons.copy_all_outlined),
                                label: Text('Copy Puzzle Code', style: GoogleFonts.nunito()),
                                style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: kMediumPadding), backgroundColor: dialogTheme.colorScheme.tertiaryContainer, foregroundColor: dialogTheme.colorScheme.onTertiaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), ),
                                onPressed: () {
                                  String? generatedCode;
                                  final difficultyChar = gameProvider.currentPuzzleDifficulty != null && difficultyLabels.containsKey(gameProvider.currentPuzzleDifficulty)
                                                        ? (difficultyLabels[gameProvider.currentPuzzleDifficulty]![0].toUpperCase())
                                                        : (gameProvider.currentPuzzleDifficulty == -1 ? 'R' : 'M');
                                  final timeInSeconds = finalTime.inSeconds;
                                  final currentHintsUsed = hints;

                                  StringBuffer boardSb = StringBuffer();
                                  bool boardReconstructionOk = true;
                                  try {
                                      if (gameProvider.board.isEmpty || gameProvider.board.length != kGridSize) throw Exception("Board not ready");
                                      for (int r = 0; r < kGridSize; r++) {
                                          if (gameProvider.board[r].length != kGridSize) throw Exception("Board row $r not ready");
                                          for (int c = 0; c < kGridSize; c++) {
                                              final cell = gameProvider.board[r][c];
                                              if (cell.isFixed && cell.value != null) { boardSb.write('${cell.value! + 1}'); }
                                              else { boardSb.write('0'); }
                                          }
                                      }
                                  } catch(e) { boardReconstructionOk = false; if (kDebugMode) print("Error reconstructing board for copying code: $e"); }

                                  if (boardReconstructionOk) {
                                     // Use 'x' as separator
                                     generatedCode = '$difficultyChar${'x'}$currentHintsUsed${'x'}$timeInSeconds${'x'}${boardSb.toString()}';
                                  }

                                   if (generatedCode != null) {
                                      Clipboard.setData(ClipboardData(text: generatedCode));
                                      // Update snackbar message slightly
                                      if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar( SnackBar( content: const Text('Puzzle code copied!'), duration: kSnackbarDuration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), ), ); }
                                   } else { if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar( SnackBar( content: const Text('Error generating puzzle code.'), duration: kSnackbarDuration, backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kSmallRadius)), ), ); } }
                                },
                              ),
                          // --- END UPDATED Copy Puzzle Code Button ---

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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final currentTheme = Theme.of(context);
    final Gradient? backgroundGradient = Theme.of(context).extension<AppGradients>()?.backgroundGradient;
    final defaultFallbackGradient = LinearGradient( colors: [ currentTheme.colorScheme.surface, currentTheme.colorScheme.background, ], begin: Alignment.topLeft, end: Alignment.bottomRight, );
    final List<Color> retroColors = ColorPalette.retro.colors;
    final List<Color> titleColors = retroColors.length >= 8 ? retroColors.sublist(0, 8) : List.generate(8, (i) => retroColors.isNotEmpty ? retroColors[i % retroColors.length] : currentTheme.colorScheme.primary);
    final TextStyle? baseTitleStyle = currentTheme.appBarTheme.titleTextStyle ?? GoogleFonts.nunito(fontSize: kLargeFontSize, fontWeight: FontWeight.bold);
    final bool isCompleted = context.select((GameProvider gp) => gp.isCompleted);
    final Duration? timeToBeat = context.select((GameProvider gp) => gp.timeToBeat);
    final int? initialHints = context.select((GameProvider gp) => gp.initialHintsFromCode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
         title: RichText( text: TextSpan( style: baseTitleStyle, children: <TextSpan>[ TextSpan(text: 'R', style: TextStyle(color: titleColors[1 % titleColors.length])), TextSpan(text: 'a', style: TextStyle(color: titleColors[2 % titleColors.length])), TextSpan(text: 'i', style: TextStyle(color: titleColors[0 % titleColors.length])), TextSpan(text: 'n', style: TextStyle(color: titleColors[3 % titleColors.length])), TextSpan(text: 'b', style: TextStyle(color: titleColors[4 % titleColors.length])), TextSpan(text: 'o', style: TextStyle(color: titleColors[5 % titleColors.length])), TextSpan(text: 'k', style: TextStyle(color: titleColors[6 % titleColors.length])), TextSpan(text: 'u', style: TextStyle(color: titleColors[7 % titleColors.length])), ], ), ),
         leading: IconButton( icon: const Icon(Icons.arrow_back), tooltip: 'Back to Home', onPressed: () { final router = GoRouter.of(context); final game = Provider.of<GameProvider>(context, listen: false); if (router.canPop()) { game.pauseGame(); Future.delayed(Duration.zero, () { if (context.mounted) context.pop(); }); } else { if (kIsWeb) { final homeUrl = '/#/'; Future.delayed(Duration.zero, () { try { web_interop.window.location.href = homeUrl; } catch (e) { print("[DEBUG] ERROR setting window.location.href: $e"); } }); } else { game.pauseGame(); Future.delayed(Duration.zero, () { if (context.mounted) context.go('/'); }); } } }, ),
         actions: [ Selector<GameProvider, Tuple2<bool, bool>>( selector: (_, game) => Tuple2(game.isPaused, game.isCompleted), builder: (context, data, child) { final isPaused = data.item1; final isCompleted = data.item2; return IconButton( icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isCompleted ? Colors.grey : null), tooltip: isCompleted ? 'Game Over' : (isPaused ? 'Resume' : 'Pause'), onPressed: isCompleted ? null : () { final game = Provider.of<GameProvider>(context, listen: false); if (game.isPaused) { game.resumeGame(); } else { game.pauseGame(); } }, ); } ), IconButton( icon: const Icon(Icons.settings_outlined), tooltip: 'Settings', onPressed: () { _showSettingsSheet(context); }, ), ],
       ),
      body: Stack(
        children: [
            Container( decoration: BoxDecoration( gradient: backgroundGradient ?? defaultFallbackGradient ) ),
            if (_particlesInitialized) CustomPaint( painter: BokehPainter(particles: _particles ), size: MediaQuery.of(context).size, ),
             Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, numberOfParticles: kConfettiParticleCount, gravity: kConfettiGravity, emissionFrequency: kConfettiEmissionFrequency, maxBlastForce: kConfettiMaxBlastForce, minBlastForce: kConfettiMinBlastForce, particleDrag: kConfettiParticleDrag, colors: settingsProvider.selectedPalette.colors, createParticlePath: (size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2)), ), ),
            SafeArea(
              minimum: const EdgeInsets.only(top: kDefaultPadding, right: kDefaultPadding),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: kMediumPadding, right: kMediumPadding, bottom: kMediumPadding, top: 0),
                    child: Column(
                      children: <Widget>[
                          Padding(
                             padding: const EdgeInsets.symmetric(vertical: kMediumSpacing / 2),
                             child: Consumer<SettingsProvider>(
                               builder: (context, settings, child) {
                                 final bool showTimer = settings.timerEnabled;
                                 final bool showChallengeInfo = timeToBeat != null || initialHints != null;

                                 return Container(
                                   constraints: const BoxConstraints(minHeight: 50),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     crossAxisAlignment: CrossAxisAlignment.center,
                                     children: [
                                       // Left side: Loaded Info (Formatted)
                                       Expanded(
                                         child: Column(
                                           mainAxisSize: MainAxisSize.min,
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             if (showChallengeInfo) Padding( padding: const EdgeInsets.only(left: kMediumPadding, bottom: 4), child: Text( 'To beat:', style: currentTheme.textTheme.bodySmall?.copyWith( fontWeight: FontWeight.bold, color: currentTheme.colorScheme.onSurface.withOpacity(0.8), ), ), ),
                                             if (timeToBeat != null) Padding( padding: const EdgeInsets.only(left: kMediumPadding + kDefaultPadding, bottom: 2), child: Text( 'Time: ${_formatDuration(timeToBeat)}', style: currentTheme.textTheme.bodySmall?.copyWith( color: currentTheme.colorScheme.onSurface.withOpacity(0.7), fontFeatures: const [ui.FontFeature.tabularFigures()], ), ), ),
                                             if (initialHints != null) Padding( padding: const EdgeInsets.only(left: kMediumPadding + kDefaultPadding), child: Text( 'Hints: $initialHints', style: currentTheme.textTheme.bodySmall?.copyWith( color: currentTheme.colorScheme.onSurface.withOpacity(0.7), ), ), ),
                                           ],
                                         ),
                                       ),

                                       // Center: Timer Widget
                                       if (showTimer) const Center(child: TimerWidget()) else const Spacer(),

                                       // Right side: Difficulty Chip
                                       Expanded( child: Align( alignment: Alignment.centerRight, child: Padding( padding: const EdgeInsets.only(right: kMediumPadding + kDefaultPadding), child: Consumer<GameProvider>( builder: (context, game, child) { final difficultyLevel = game.currentPuzzleDifficulty; final difficultyText = difficultyLevel != null ? difficultyLabels[difficultyLevel] ?? '?' : ''; if (difficultyText.isEmpty) return const SizedBox.shrink(); return Chip( label: Text( difficultyText, style: GoogleFonts.nunito( textStyle: currentTheme.textTheme.labelSmall, color: currentTheme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, ) ), backgroundColor: currentTheme.colorScheme.secondaryContainer.withOpacity(kMediumHighOpacity), padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0), visualDensity: VisualDensity.compact, side: BorderSide.none, ); } ), ), ), ),
                                     ],
                                   ),
                                 );
                               },
                             ),
                          ),
                          const SizedBox(height: kMediumSpacing),

                          // Sudoku Grid Area
                          Expanded( child: Center( child: AspectRatio( aspectRatio: 1.0, child: SudokuGridWidget() ) ) ),
                          const SizedBox(height: kLargeSpacing),

                          // Controls Area
                          Stack(
                             alignment: Alignment.center,
                             children: [
                               Visibility( visible: !gameProvider.isCompleted, maintainState: true, maintainAnimation: true, maintainSize: true, child: Column( mainAxisSize: MainAxisSize.min, children: [ const PaletteSelectorWidget(), const SizedBox(height: kLargeSpacing), GameControls(key: _gameControlsKey), ], ), ),
                               Visibility( visible: gameProvider.isCompleted, child: Padding( padding: const EdgeInsets.symmetric(vertical: kExtraLargeSpacing), child: Center( child: ElevatedButton.icon( icon: const Icon(Icons.refresh), label: Text('New Game', style: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst)), style: ElevatedButton.styleFrom( backgroundColor: currentTheme.colorScheme.primaryContainer, foregroundColor: currentTheme.colorScheme.onPrimaryContainer, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: kDefaultFontSizeConst), textStyle: GoogleFonts.nunito(fontSize: kDefaultFontSizeConst, fontWeight: FontWeight.w600), elevation: kHighElevation, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMediumRadius)), ), onPressed: () { final game = Provider.of<GameProvider>(context, listen: false); final settings = Provider.of<SettingsProvider>(context, listen: false); final int initialDifficulty = game.initialDifficultySelection ?? 1; if (initialDifficulty == -1) { settings.selectRandomPalette(); } if (mounted) { setState(() { _completionDialogShown = false; }); } game.loadNewPuzzle(difficulty: initialDifficulty); _regenerateBokehParticles(); _startIntroAnimationSequenceIfNeeded(); }, ), ), ), ),
                             ],
                           ),
                          const SizedBox(height: kMediumSpacing),
                      ],
                    ),
                  ),
                ],
              ),
            ),
         ],
       ),
    );
  }}

// Helper class Tuple2
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
  @override bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2;
  @override int get hashCode => Object.hash(item1, item2);
}