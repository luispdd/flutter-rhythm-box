import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/step_grid.dart';

class StepPlayhead extends ConsumerWidget {
  const StepPlayhead({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(audioEngineProvider);
    final tempo = ref.watch(tempoProvider);
    final state = ref.watch(sequencerControllerProvider);
    final isPlaying = state.isPlaying;
    final stepCount = state.pattern.stepCount;

    return StreamBuilder<Duration>(
      stream: engine.positionStream,
      builder: (context, snapshot) {
        int? activeStepIndex;

        if (isPlaying && snapshot.hasData) {
          final positionUs = snapshot.data!.inMicroseconds;
          // Step duration in microseconds = 60,000,000 / (BPM * 4)
          // => 15,000,000 / BPM
          final stepDurUs = (15000000 / tempo).round();
          activeStepIndex = (positionUs ~/ stepDurUs) % stepCount;
        }

        return Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Row(
                    children: List.generate(stepCount, (index) {
                      final isPlayheadHere = activeStepIndex == index;
                      return Expanded(
                        child: Container(
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            color: isPlayheadHere ? Colors.amber : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: StepGrid(
                stepCount: stepCount,
                tracks: state.pattern.tracks,
                onStepToggled: (trackIndex, stepIndex) {
                  ref.read(sequencerControllerProvider.notifier).toggleStep(trackIndex, stepIndex);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
