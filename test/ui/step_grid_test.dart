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

  testWidgets('StepGrid displays custom voice labels when provided', (WidgetTester tester) async {
    final pattern = Pattern.empty(stepCount: 8);
    final customLabels = [
      'Bass',      // track 0
      'Snare',     // track 1
      'Rimshot',   // track 2
      'Clap',      // track 3
      'Cowbell',   // track 4
      'Tom',       // track 5
      'Closed HH', // track 6
      'Open HH',   // track 7
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepGrid(
            stepCount: pattern.stepCount,
            tracks: pattern.tracks,
            trackLabels: customLabels,
            onStepToggled: (_, _) {},
          ),
        ),
      ),
    );

    for (final label in customLabels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('StepGrid falls back to generic Trk N when labels are omitted', (WidgetTester tester) async {
    final pattern = Pattern.empty(stepCount: 8);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepGrid(
            stepCount: pattern.stepCount,
            tracks: pattern.tracks,
            onStepToggled: (_, _) {},
          ),
        ),
      ),
    );

    for (var i = 1; i <= 8; i++) {
      expect(find.text('Trk $i'), findsOneWidget);
    }
  });
}
