import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/ui/sequencer_controls.dart';

void main() {
  testWidgets('SequencerControls displays all elements and handles callbacks', (WidgetTester tester) async {
    bool playToggled = false;
    int? newStepCount;
    bool patternCleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SequencerControls(
            isPlaying: false,
            stepCount: 8,
            onPlayPauseToggled: () => playToggled = true,
            onStepCountChanged: (val) => newStepCount = val,
            onClearPattern: () => patternCleared = true,
            onSavePattern: () {},
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.text('Steps: 8'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // Tap play
    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(playToggled, true);

    // Tap clear
    await tester.tap(find.text('Clear'));
    expect(patternCleared, true);

    // Slide the step count slider
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(newStepCount, isNotNull);
  });

  testWidgets('SequencerControls shows stop icon when playing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SequencerControls(
            isPlaying: true,
            stepCount: 16,
            onPlayPauseToggled: () {},
            onStepCountChanged: (_) {},
            onClearPattern: () {},
            onSavePattern: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.stop), findsOneWidget);
  });
}
