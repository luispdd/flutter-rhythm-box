import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/library_data.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/services/file_picker_service.dart';
import 'package:rhythm_box/ui/metronome_screen.dart';
import 'package:rhythm_box/ui/playback_controller.dart';

import '../audio/fake_audio_engine.dart';
import '../persistence/fake_settings_store.dart';
import '../services/fake_file_picker_service.dart';

void main() {
  testWidgets('MetronomeScreen layout contains all required controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      ),
    );

    // Initial build
    await tester.pumpAndSettle();

    // Verify Tempo controls
    expect(find.byKey(const Key('tempo_slider')), findsOneWidget);
    expect(find.byKey(const Key('tempo_decrement_button')), findsOneWidget);
    expect(find.byKey(const Key('tempo_increment_button')), findsOneWidget);
    expect(find.textContaining('BPM'), findsOneWidget);

    // Verify Playback controls
    expect(find.byKey(const Key('play_stop_button')), findsOneWidget);
    expect(find.text('Play'), findsOneWidget); // initially not playing

    // Verify Settings controls
    expect(find.byKey(const Key('beats_per_bar_slider')), findsOneWidget);
    expect(find.byKey(const Key('accent_toggle')), findsOneWidget);
    expect(find.byKey(const Key('waveform_segmented_button')), findsOneWidget);
    expect(find.byKey(const Key('pitch_slider')), findsOneWidget);
    expect(find.byKey(const Key('decay_slider')), findsOneWidget);
  });

  testWidgets('MetronomeScreen updates tempo and settings on interaction', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Interact with tempo increment
    await tester.tap(find.byKey(const Key('tempo_increment_button')));
    await tester.pumpAndSettle();
    expect(find.text('Tempo: 121 BPM'), findsOneWidget);

    // Interact with accent toggle
    final accentToggle = find.byKey(const Key('accent_toggle'));
    await tester.tap(accentToggle);
    await tester.pumpAndSettle();
    
    // Interact with play/stop
    final playButton = find.byKey(const Key('play_stop_button'));
    await tester.tap(playButton);
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('modifying settings during playback keeps playback running', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeEngine = FakeAudioEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Start playback
    await tester.tap(find.byKey(const Key('play_stop_button')));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Toggle accent during playback
    await tester.tap(find.byKey(const Key('accent_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Change waveform during playback
    await tester.tap(find.text('Square'));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Modify pitch slider during playback
    final pitchSlider = find.byKey(const Key('pitch_slider'));
    await tester.drag(pitchSlider, const Offset(50.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Modify decay slider during playback
    final decaySlider = find.byKey(const Key('decay_slider'));
    await tester.drag(decaySlider, const Offset(-30.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Verify swapLoopAtBoundary was triggered repeatedly without ever calling stop
    expect(fakeEngine.swapLoopCalls, greaterThanOrEqualTo(4));
    expect(fakeEngine.stopCalls, equals(0));
  });

  group('Library Export and Import UI in MetronomeScreen', () {
    late FakeSettingsStore fakeStore;
    late FakeFilePickerService fakePicker;
    late FakeAudioEngine fakeEngine;

    setUp(() {
      fakeStore = FakeSettingsStore();
      fakePicker = FakeFilePickerService();
      fakeEngine = FakeAudioEngine();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(fakeStore),
          filePickerServiceProvider.overrideWithValue(fakePicker),
          audioEngineProvider.overrideWithValue(fakeEngine),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      );
    }

    testWidgets('shows "Nothing to export" when library is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_library_button')), findsOneWidget);
      expect(find.byKey(const Key('import_library_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('export_library_button')));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to export'), findsOneWidget);
      expect(fakePicker.saveFileCalls, equals(0));
    });

    testWidgets('exports library and shows success snackbar when items exist', (WidgetTester tester) async {
      fakeStore.savedPatternLibrary = [Pattern(id: 'p1', name: 'Pattern 1')];
      fakePicker.saveResult = '/path/to/exported.json';

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export_library_button')));
      await tester.pumpAndSettle();

      expect(fakePicker.saveFileCalls, equals(1));
      expect(find.text('Exported 1 patterns and 0 sequences'), findsOneWidget);
    });

    testWidgets('cancels import dialog without mutating library when user taps Cancel', (WidgetTester tester) async {
      fakeStore.savedPatternLibrary = [Pattern(id: 'old_p', name: 'Old Pattern')];
      final library = LibraryData(
        patterns: [Pattern(id: 'new_p', name: 'New Pattern')],
        sequences: [],
      );
      fakePicker.pickResult = PickedFileData(
        name: 'library.json',
        bytes: Uint8List.fromList(utf8.encode(library.toJsonString())),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import_library_button')));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Replace all data?'), findsOneWidget);
      expect(find.textContaining('This file contains 1 patterns and 0 sequences'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const Key('cancel_import_button')));
      await tester.pumpAndSettle();

      // Dialog dismissed, no replacement called
      expect(find.text('Replace all data?'), findsNothing);
      expect(fakeStore.replaceAllCalls, equals(0));
      expect(fakeStore.savedPatternLibrary.first.id, equals('old_p'));
    });

    testWidgets('executes import and replaces library when user confirms dialog', (WidgetTester tester) async {
      fakeStore.savedPatternLibrary = [Pattern(id: 'old_p', name: 'Old Pattern')];
      final library = LibraryData(
        patterns: [Pattern(id: 'imported_p', name: 'Imported Pattern')],
        sequences: [],
      );
      fakePicker.pickResult = PickedFileData(
        name: 'library.json',
        bytes: Uint8List.fromList(utf8.encode(library.toJsonString())),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import_library_button')));
      await tester.pumpAndSettle();

      // Tap Replace All
      await tester.tap(find.byKey(const Key('confirm_import_button')));
      await tester.pumpAndSettle();

      // Success snackbar displayed
      expect(find.text('Imported 1 patterns and 0 sequences'), findsOneWidget);
      expect(fakeStore.replaceAllCalls, equals(1));
      expect(fakeStore.savedPatternLibrary.first.id, equals('imported_p'));
    });
  });
}
