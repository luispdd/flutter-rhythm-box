import 'package:flutter/material.dart';
import 'package:rhythm_box/domain/pattern.dart';

class SequencerControls extends StatelessWidget {
  final bool isPlaying;
  final int stepCount;
  final VoidCallback onPlayPauseToggled;
  final void Function(int) onStepCountChanged;
  final VoidCallback onClearPattern;

  const SequencerControls({
    super.key,
    required this.isPlaying,
    required this.stepCount,
    required this.onPlayPauseToggled,
    required this.onStepCountChanged,
    required this.onClearPattern,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 48.0,
          icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
          onPressed: onPlayPauseToggled,
          tooltip: isPlaying ? 'Stop' : 'Play',
          color: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: Row(
            children: [
              Text('Steps: $stepCount'),
              Expanded(
                child: Slider(
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
        ElevatedButton(
          onPressed: onClearPattern,
          child: const Text('Clear'),
        ),
      ],
    );
  }
}
