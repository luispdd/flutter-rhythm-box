import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/sequencer_controls.dart';
import 'package:rhythm_box/ui/step_playhead.dart';
import 'package:rhythm_box/ui/tempo_controller.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/ui/hold_timer_icon_button.dart';

class SequencerScreen extends ConsumerWidget {
  const SequencerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sequencerControllerProvider);
    final tempo = ref.watch(tempoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequencer'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Tempo: $tempo BPM',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      HoldTimerIconButton(
                        icon: Icons.remove,
                        onPressed: () => ref.read(tempoProvider.notifier).decrement(),
                      ),
                      Expanded(
                        child: Slider(
                          value: tempo.toDouble(),
                          min: Tempo.minBpm.toDouble(),
                          max: Tempo.maxBpm.toDouble(),
                          onChanged: (value) =>
                              ref.read(tempoProvider.notifier).setBpm(value.toInt()),
                        ),
                      ),
                      HoldTimerIconButton(
                        icon: Icons.add,
                        onPressed: () => ref.read(tempoProvider.notifier).increment(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SequencerControls(
            isPlaying: state.isPlaying,
            stepCount: state.pattern.stepCount,
            onPlayPauseToggled: () {
              ref.read(sequencerControllerProvider.notifier).togglePlay();
            },
            onStepCountChanged: (val) {
              ref.read(sequencerControllerProvider.notifier).setStepCount(val);
            },
            onClearPattern: () {
              ref.read(sequencerControllerProvider.notifier).clearPattern();
            },
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: StepPlayhead(),
            ),
          ),
        ],
      ),
    );
  }
}
