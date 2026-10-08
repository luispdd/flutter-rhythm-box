import 'package:flutter/material.dart';

class StepGrid extends StatelessWidget {
  final int stepCount;
  final List<List<bool>> tracks;
  final void Function(int trackIndex, int stepIndex) onStepToggled;

  const StepGrid({
    super.key,
    required this.stepCount,
    required this.tracks,
    required this.onStepToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(8, (row) {
        // Track 0 is the lowest voice, display it at the bottom.
        final trackIndex = 7 - row;
        return Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('Trk ${trackIndex + 1}', style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: Row(
                  children: List.generate(stepCount, (stepIndex) {
                    final isActive = tracks[trackIndex][stepIndex];
                    final colorScheme = Theme.of(context).colorScheme;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onStepToggled(trackIndex, stepIndex),
                        child: Container(
                          margin: const EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            color: isActive ? colorScheme.primary : colorScheme.outline,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
