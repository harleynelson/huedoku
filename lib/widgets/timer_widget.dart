// File: lib/widgets/timer_widget.dart
// Location: ./lib/widgets/timer_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huedoku/providers/game_provider.dart';
import 'package:provider/provider.dart';

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
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Check game state via provider *without listening* to avoid rebuild loops
      // We rely on the listener below to stop/start this timer correctly
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (!gameProvider.isPaused && !gameProvider.isCompleted) {
        if (mounted) { // Check if widget is still in the tree
            setState(() {
              _displayTime += const Duration(seconds: 1);
            });
        } else {
             _displayTimer?.cancel(); // Stop timer if widget is disposed
        }
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
        // This logic runs when GameProvider notifies (e.g., on pause, resume, new game)

        // If game just reset, update display time
        if (gameProvider.elapsedTime == Duration.zero && _displayTime != Duration.zero) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) setState(() => _displayTime = Duration.zero);
           });
        }

        // Check if display timer needs starting/stopping
        final bool shouldTimerRun = !gameProvider.isPaused && !gameProvider.isCompleted;
        if (shouldTimerRun && !(_displayTimer?.isActive ?? false)) {
           // If timer should run but isn't, sync time and start it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                 // Ensure display time catches up if paused/resumed
                 if (_displayTime != gameProvider.elapsedTime) {
                    setState(() => _displayTime = gameProvider.elapsedTime);
                 }
                 _startDisplayTimer();
              }
            });
        } else if (!shouldTimerRun && (_displayTimer?.isActive ?? false)) {
           // If timer shouldn't run but is, stop it
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _displayTimer?.cancel();
               // Ensure display time matches final time on completion/pause
                if (mounted && _displayTime != gameProvider.elapsedTime) {
                   setState(() => _displayTime = gameProvider.elapsedTime);
                }
            });
        }
        // --- End Sync Logic ---


        // Display the locally managed _displayTime
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 20, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              _formatDuration(_displayTime), // Use local state variable
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        );
      },
    );
  }
}