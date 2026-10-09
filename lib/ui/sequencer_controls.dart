import 'package:flutter/material.dart';
import 'package:rhythm_box/domain/pattern.dart';

class SequencerControls extends StatelessWidget {
  final bool isPlaying;
  final int stepCount;
  final bool showTrackLabels;
  final VoidCallback onToggleTrackLabels;
  final VoidCallback onPlayPauseToggled;
  final void Function(int) onStepCountChanged;
  final VoidCallback onClearPattern;
  final VoidCallback onSavePattern;

  const SequencerControls({
    super.key,
    required this.isPlaying,
    required this.stepCount,
    required this.showTrackLabels,
    required this.onToggleTrackLabels,
    required this.onPlayPauseToggled,
    required this.onStepCountChanged,
    required this.onClearPattern,
    required this.onSavePattern,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            key: const Key('toggle_track_labels_button'),
            icon: Icon(showTrackLabels ? Icons.label : Icons.label_off_outlined),
            tooltip: showTrackLabels ? 'Hide track labels' : 'Show track labels',
            onPressed: onToggleTrackLabels,
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Steps: $stepCount',
                  style: const TextStyle(fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    key: const Key('step_count_slider'),
                    value: stepCount.toDouble(),
                    min: Pattern.minStepCount.toDouble(),
                    max: Pattern.maxStepCount.toDouble(),
                    divisions: Pattern.maxStepCount - Pattern.minStepCount,
                    label: stepCount.toString(),
                    onChanged: (val) => onStepCountChanged(val.toInt()),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('clear_pattern_button'),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear pattern',
            onPressed: onClearPattern,
          ),
          IconButton(
            key: const Key('save_pattern_button'),
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save pattern',
            onPressed: onSavePattern,
          ),
          IconButton(
            key: const Key('play_stop_button'),
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            tooltip: isPlaying ? 'Stop' : 'Play',
            color: Theme.of(context).colorScheme.primary,
            onPressed: onPlayPauseToggled,
          ),
        ],
      ),
    );
  }
}
