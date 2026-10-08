import 'package:flutter/material.dart';

class StepGrid extends StatelessWidget {
  final int stepCount;
  final List<List<bool>> tracks;
  final void Function(int trackIndex, int stepIndex) onStepToggled;
  final List<String>? trackLabels;

  static const double labelWidth = 76.0;

  const StepGrid({
    super.key,
    required this.stepCount,
    required this.tracks,
    required this.onStepToggled,
    this.trackLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(8, (row) {
        // Track 0 is the lowest voice, display it at the bottom.
        final trackIndex = 7 - row;
        final label = (trackLabels != null && trackIndex < trackLabels!.length)
            ? trackLabels![trackIndex]
            : 'Trk ${trackIndex + 1}';
        return Expanded(
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
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
