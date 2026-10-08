import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/pattern_library_screen.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/sequencer_screen.dart';

import '../audio/fake_audio_engine.dart';
import '../persistence/fake_settings_store.dart';

void main() {
  group('UI Polish: PatternLibraryScreen and SequencerScreen', () {
    testWidgets('PatternLibraryScreen displays friendly empty state when list is empty',
        (tester) async {
      final fakeStore = FakeSettingsStore();
      final fakeEngine = FakeAudioEngine();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(fakeStore),
            audioEngineProvider.overrideWithValue(fakeEngine),
          ],
          child: const MaterialApp(
            home: PatternLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No patterns yet'), findsOneWidget);
      expect(
        find.text('Create and save patterns in the Sequencer to view them here.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.library_music_outlined), findsOneWidget);
    });

    testWidgets('SequencerScreen Clear button shows confirmation dialog before clearing pattern',
        (tester) async {
      final fakeStore = FakeSettingsStore();
      final fakeEngine = FakeAudioEngine();

      // Create container with an active step
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(fakeStore),
          audioEngineProvider.overrideWithValue(fakeEngine),
        ],
      );
      addTearDown(container.dispose);

      // Set step 0 active on track 0
      container.read(sequencerControllerProvider.notifier).toggleStep(0, 0);
      expect(container.read(sequencerControllerProvider).pattern.tracks[0][0], isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SequencerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Clear button
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Clear Pattern'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to clear the working pattern? All active steps will be reset.',
        ),
        findsOneWidget,
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Pattern should NOT be cleared
      expect(container.read(sequencerControllerProvider).pattern.tracks[0][0], isTrue);

      // Tap Clear again and confirm
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pumpAndSettle();

      // Pattern should now be cleared
      expect(container.read(sequencerControllerProvider).pattern.tracks[0][0], isFalse);
    });
  });
}
