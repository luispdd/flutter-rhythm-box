import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/kit.dart';
import 'package:rhythm_box/persistence/kit_repository.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/pattern_library_screen.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/sequencer_screen.dart';
import 'package:rhythm_box/ui/step_playhead.dart';

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
      await tester.tap(find.byKey(const Key('clear_pattern_button')));
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
      await tester.tap(find.byKey(const Key('clear_pattern_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pumpAndSettle();

      // Pattern should now be cleared
      expect(container.read(sequencerControllerProvider).pattern.tracks[0][0], isFalse);
    });

    testWidgets('SequencerScreen AppBar includes kit selector and updates kit and voice labels',
        (tester) async {
      final fakeStore = FakeSettingsStore();
      final fakeEngine = FakeAudioEngine();
      final fakeRetroKit = Kit(
        id: 'retro-8bit',
        name: 'Retro 8-bit',
        voices: Kit.classicSynth.voices
            .map((v) => v.copyWith(label: '8Bit ${v.label}'))
            .toList(),
      );
      final kitRepo = InMemoryKitRepository(
        kits: [Kit.classicSynth, fakeRetroKit],
      );

      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(fakeStore),
          audioEngineProvider.overrideWithValue(fakeEngine),
          kitRepositoryProvider.overrideWithValue(kitRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SequencerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle track labels to visible so voice labels are rendered
      await tester.tap(find.byKey(const Key('toggle_track_labels_button')));
      await tester.pumpAndSettle();

      // Find kit dropdown selector
      final selectorFinder = find.byKey(const Key('sequencerKitSelector'));
      expect(selectorFinder, findsOneWidget);
      expect(find.text('Classic synth'), findsWidgets);

      // Verify initial classic voice label is visible in step grid (e.g. Kick)
      expect(find.text(Kit.classicSynth.voices[0].label!), findsOneWidget);

      // Tap dropdown to open options
      await tester.tap(selectorFinder);
      await tester.pumpAndSettle();

      // Tap the Retro 8-bit item
      await tester.tap(find.text('Retro 8-bit').last);
      await tester.pumpAndSettle();

      // Verify controller state changed kitId
      expect(container.read(sequencerControllerProvider).pattern.kitId, equals('retro-8bit'));

      // Verify step grid labels updated to retro kit voice labels
      expect(find.text('8Bit ${Kit.classicSynth.voices[0].label!}'), findsOneWidget);
    });

    testWidgets('SequencerScreen shows BPM badge in AppBar and reordered controls with tooltips',
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
            home: SequencerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // BPM in AppBar
      expect(find.text('120 BPM'), findsOneWidget);
      // No "Tempo: 120 BPM" title above slider
      expect(find.text('Tempo: 120 BPM'), findsNothing);

      // Verify all control buttons exist by Key
      expect(find.byKey(const Key('toggle_track_labels_button')), findsOneWidget);
      expect(find.byKey(const Key('step_count_slider')), findsOneWidget);
      expect(find.byKey(const Key('clear_pattern_button')), findsOneWidget);
      expect(find.byKey(const Key('save_pattern_button')), findsOneWidget);
      expect(find.byKey(const Key('play_stop_button')), findsOneWidget);

      // Verify tooltips
      expect(find.byTooltip('Hide track labels'), findsNothing); // default hidden on android
      expect(find.byTooltip('Show track labels'), findsOneWidget);
      expect(find.byTooltip('Clear pattern'), findsOneWidget);
      expect(find.byTooltip('Save pattern'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
    });

    testWidgets('SequencerScreen is vertically scrollable in landscape orientation',
        (tester) async {
      // Simulate landscape phone dimensions (e.g., 800x360)
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeStore = FakeSettingsStore();
      final fakeEngine = FakeAudioEngine();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(fakeStore),
            audioEngineProvider.overrideWithValue(fakeEngine),
          ],
          child: const MaterialApp(
            home: SequencerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure SingleChildScrollView exists and can be scrolled down
      final scrollableFinder = find.byType(SingleChildScrollView);
      expect(scrollableFinder, findsOneWidget);

      // Drag to scroll down without layout overflow
      await tester.drag(scrollableFinder, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();

      // StepPlayhead is still rendered and responsive
      expect(find.byType(StepPlayhead), findsOneWidget);
    });

    testWidgets('track label toggle respects platform default and toggles visibility',
        (tester) async {
      final fakeStore = FakeSettingsStore();
      final fakeEngine = FakeAudioEngine();

      // Test mobile default (Android in test binding)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(fakeStore),
            audioEngineProvider.overrideWithValue(fakeEngine),
          ],
          child: const MaterialApp(
            home: SequencerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile default: track labels hidden
      expect(find.text(Kit.classicSynth.voices[0].label!), findsNothing);

      // Tap toggle button
      await tester.tap(find.byKey(const Key('toggle_track_labels_button')));
      await tester.pumpAndSettle();

      // Track labels now visible
      expect(find.text(Kit.classicSynth.voices[0].label!), findsOneWidget);

      // Tap toggle again
      await tester.tap(find.byKey(const Key('toggle_track_labels_button')));
      await tester.pumpAndSettle();

      // Track labels hidden again
      expect(find.text(Kit.classicSynth.voices[0].label!), findsNothing);
    });

    test('trackLabelsVisibleProvider defaults based on platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final mobileContainer = ProviderContainer();
      expect(mobileContainer.read(trackLabelsVisibleProvider), isFalse);
      mobileContainer.dispose();

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iosContainer = ProviderContainer();
      expect(iosContainer.read(trackLabelsVisibleProvider), isFalse);
      iosContainer.dispose();

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final linuxContainer = ProviderContainer();
      expect(linuxContainer.read(trackLabelsVisibleProvider), isTrue);
      linuxContainer.dispose();

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
