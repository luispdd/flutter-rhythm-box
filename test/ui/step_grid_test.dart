import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/ui/step_grid.dart';
import 'package:rhythm_box/domain/pattern.dart';

void main() {
  testWidgets('StepGrid displays correct number of tracks and columns', (WidgetTester tester) async {
    final pattern = Pattern.empty(stepCount: 8);
    int tappedTrack = -1;
    int tappedStep = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepGrid(
            stepCount: pattern.stepCount,
            tracks: pattern.tracks,
            onStepToggled: (trackIndex, stepIndex) {
              tappedTrack = trackIndex;
              tappedStep = stepIndex;
            },
          ),
        ),
      ),
    );

    // 8 tracks * 8 steps = 64 cells
    expect(find.byType(GestureDetector), findsNWidgets(64));

    // Tap the top-left cell (track 7, step 0)
    await tester.tap(find.byType(GestureDetector).first);
    expect(tappedTrack, 7);
    expect(tappedStep, 0);
  });
}
