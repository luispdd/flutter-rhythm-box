import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/ui/sequencer_controls.dart';

void main() {
  testWidgets('SequencerControls displays all elements and handles callbacks', (WidgetTester tester) async {
    bool playToggled = false;
    int? newStepCount;
    bool patternCleared = false;
    bool patternSaved = false;
    bool labelsToggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SequencerControls(
            isPlaying: false,
            stepCount: 8,
            showTrackLabels: true,
            onToggleTrackLabels: () => labelsToggled = true,
            onPlayPauseToggled: () => playToggled = true,
            onStepCountChanged: (val) => newStepCount = val,
            onClearPattern: () => patternCleared = true,
            onSavePattern: () => patternSaved = true,
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.byKey(const Key('toggle_track_labels_button')), findsOneWidget);
    expect(find.byIcon(Icons.label), findsOneWidget);
    expect(find.text('Steps: 8'), findsOneWidget);
    expect(find.byKey(const Key('clear_pattern_button')), findsOneWidget);
    expect(find.byKey(const Key('save_pattern_button')), findsOneWidget);
    expect(find.byKey(const Key('play_stop_button')), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // Tap toggle labels
    await tester.tap(find.byKey(const Key('toggle_track_labels_button')));
    expect(labelsToggled, true);

    // Tap play
    await tester.tap(find.byKey(const Key('play_stop_button')));
    expect(playToggled, true);

    // Tap clear
    await tester.tap(find.byKey(const Key('clear_pattern_button')));
    expect(patternCleared, true);

    // Tap save
    await tester.tap(find.byKey(const Key('save_pattern_button')));
    expect(patternSaved, true);

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
            showTrackLabels: false,
            onToggleTrackLabels: () {},
            onPlayPauseToggled: () {},
            onStepCountChanged: (_) {},
            onClearPattern: () {},
            onSavePattern: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.label_off_outlined), findsOneWidget);
  });
}
