// File: lib/widgets/timer_widget.dart
// Location: ./lib/widgets/timer_widget.dart

import 'dart:async';
import 'dart:math'; // For PI
import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui; // For font features

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _displayTimer;
  late Duration _displayTime; // Holds the time shown by this widget

  // Helper function to format duration
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

  void _startDisplayTimer() {
    // Ensure any existing timer is cancelled
    _displayTimer?.cancel();
    // Start a new timer that updates the local state every second
    _displayTimer = Timer.periodic(const Duration(milliseconds: 100), (_) { // Update more frequently for smoother progress
      // Check game state via provider *without listening* to avoid rebuild loops
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (!gameProvider.isPaused && !gameProvider.isCompleted) {
        if (mounted) { // Check if widget is still in the tree
            setState(() {
              _displayTime += const Duration(milliseconds: 100);
            });
        } else {
             _displayTimer?.cancel(); // Stop timer if widget is disposed
        }
      } else {
          _displayTimer?.cancel(); // Stop if paused or completed
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize _displayTime from GameProvider
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    _displayTime = gameProvider.elapsedTime;

    // Start the display timer immediately if the game isn't paused/completed
    if (!gameProvider.isPaused && !gameProvider.isCompleted) {
      _startDisplayTimer();
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel(); // Cancel timer when widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react ONLY to relevant GameProvider state changes
    // (isPaused, isCompleted, elapsedTime for initialization/reset)
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // --- Sync display time and timer state with GameProvider ---
         final bool shouldTimerRun = !gameProvider.isPaused && !gameProvider.isCompleted;

         // Sync time if it diverges significantly or on state change
         if (_displayTime.inSeconds != gameProvider.elapsedTime.inSeconds || shouldTimerRun != (_displayTimer?.isActive ?? false)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) {
                   // Update display time to match provider state accurately
                   setState(() => _displayTime = gameProvider.elapsedTime);

                   // Start/stop the display timer based on provider state
                   if (shouldTimerRun && !(_displayTimer?.isActive ?? false)) {
                      _startDisplayTimer();
                   } else if (!shouldTimerRun && (_displayTimer?.isActive ?? false)) {
                      _displayTimer?.cancel();
                   }
                 }
              });
         }
        // --- End Sync Logic ---

        // --- Build Engaging Timer UI ---
        double progress = (_displayTime.inMilliseconds % 60000) / 60000.0; // 0.0 to 1.0 for seconds
        Color progressColor = Theme.of(context).primaryColor;
        Color trackColor = Theme.of(context).primaryColor.withOpacity(0.2);
        double indicatorSize = 40.0; // Size of the circular indicator

        return Stack(
          alignment: Alignment.center,
          children: [
            // Circular Progress Indicator background track
            SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: CircularProgressIndicator(
                value: 1.0, // Full circle track
                strokeWidth: 3.0, // Thickness of track
                valueColor: AlwaysStoppedAnimation<Color>(trackColor),
              ),
            ),
            // Circular Progress Indicator foreground progress
             SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: Transform( // Rotate to start from top
                 alignment: Alignment.center,
                 transform: Matrix4.rotationZ(-pi / 2),
                 child: CircularProgressIndicator(
                   value: progress,
                   strokeWidth: 3.5, // Slightly thicker progress line
                   valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                   // Optional: Add strokeCap for rounded ends
                   // strokeCap: StrokeCap.round,
                 ),
               ),
             ),
            // Display the time text in the center
            Text(
              _formatDuration(_displayTime),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Smaller font inside circle
                fontWeight: FontWeight.w600,
                fontFeatures: [const ui.FontFeature.tabularFigures()], // Consistent number width
                 color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9),
              ),
            ),
          ],
        );
      },
    );
  }
}