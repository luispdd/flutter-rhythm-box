import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/home_screen.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequence_controller.dart';
import 'package:rhythm_box/ui/sequence_library_notifier.dart';
import 'package:rhythm_box/ui/sequence_library_screen.dart';
import 'package:rhythm_box/ui/sequences_screen.dart';

import '../audio/fake_audio_engine.dart';
import '../persistence/fake_settings_store.dart';

void main() {
  late FakeAudioEngine fakeEngine;
  late FakeSettingsStore fakeStore;

  final patternA = Pattern(
    id: 'pat-a',
    name: 'Verse Beat',
    tempoBpm: 120,
    stepCount: 16,
  );

  final patternB = Pattern(
    id: 'pat-b',
    name: 'Chorus Beat',
    tempoBpm: 130,
    stepCount: 16,
  );

  setUp(() {
    fakeEngine = FakeAudioEngine();
    fakeStore = FakeSettingsStore();
    fakeStore.savedPatternLibrary = [patternA, patternB];
  });

  Widget buildTestableWidget(Widget child, [ProviderContainer? container]) {
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: child,
        ),
      );
    }
    return ProviderScope(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        settingsStoreProvider.overrideWithValue(fakeStore),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('HomeScreen routes to SequencesScreen via 3rd navigation tab', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(const HomeScreen()));
    await tester.pumpAndSettle();

    // Verify 3 bottom navigation tabs exist by icons
    expect(find.byIcon(Icons.timer), findsOneWidget);
    expect(find.byIcon(Icons.grid_on), findsOneWidget);
    expect(find.byIcon(Icons.queue_music), findsOneWidget);

    // Tap Sequences tab
    await tester.tap(find.byIcon(Icons.queue_music));
    await tester.pumpAndSettle();

    // Verify SequencesScreen is presented
    expect(find.byType(SequencesScreen), findsOneWidget);
    expect(find.byKey(const Key('sequence_play_button')), findsOneWidget);
  });

  testWidgets('SequenceEditor allows adding pattern entries, modifying repeats, and deleting entries', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        settingsStoreProvider.overrideWithValue(fakeStore),
      ],
    );
    addTearDown(container.dispose);

    // Preload library
    await container.read(patternLibraryProvider.notifier).loadFromStore();

    await tester.pumpWidget(buildTestableWidget(const SequencesScreen(), container));
    await tester.pumpAndSettle();

    // Initially no entries
    expect(find.textContaining('No entries in this sequence'), findsOneWidget);

    // Tap "Add Entry"
    await tester.tap(find.byKey(const Key('add_entry_button')));
    await tester.pumpAndSettle();

    // Verify pattern picker dialog shows available patterns
    expect(find.text('Add Pattern to Sequence'), findsOneWidget);
    expect(find.text('Verse Beat'), findsOneWidget);
    expect(find.text('Chorus Beat'), findsOneWidget);

    // Pick Verse Beat
    await tester.tap(find.text('Verse Beat'));
    await tester.pumpAndSettle();

    // Verify entry is added to list
    expect(find.text('Verse Beat'), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);

    // Increment repeats from 1 to 2
    await tester.tap(find.byKey(const Key('increment_0')));
    await tester.pumpAndSettle();
    expect(find.text('2x'), findsOneWidget);

    // Decrement repeats from 2 back to 1
    await tester.tap(find.byKey(const Key('decrement_0')));
    await tester.pumpAndSettle();
    expect(find.text('1x'), findsOneWidget);

    // Toggle Loop mode
    final loopSwitch = find.byType(Switch);
    expect(loopSwitch, findsOneWidget);
    await tester.tap(loopSwitch);
    await tester.pumpAndSettle();
    expect(container.read(sequenceControllerProvider).sequence.loop, isFalse);

    // Delete entry
    await tester.tap(find.byKey(const Key('delete_0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No entries in this sequence'), findsOneWidget);
  });

  testWidgets('Visual playhead tracking highlights the actively playing entry', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        settingsStoreProvider.overrideWithValue(fakeStore),
      ],
    );
    addTearDown(container.dispose);

    await container.read(patternLibraryProvider.notifier).loadFromStore();

    final controller = container.read(sequenceControllerProvider.notifier);
    controller.setSequence(
      Sequence(
        id: 's1',
        name: 'Track',
        entries: [
          SequenceEntry(patternId: 'pat-a', repeats: 1),
          SequenceEntry(patternId: 'pat-b', repeats: 1),
        ],
      ),
    );

    await tester.pumpWidget(buildTestableWidget(const SequencesScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('Verse Beat'), findsOneWidget);
    expect(find.text('Chorus Beat'), findsOneWidget);

    // Tap play and await isolate compute completion
    await tester.tap(find.byKey(const Key('sequence_play_button')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(container.read(sequenceControllerProvider).isPlaying, isTrue);

    // First entry should be active and show volume_up icon
    expect(find.byIcon(Icons.volume_up), findsOneWidget);

    // Simulate playback advancing to entry 1 (~2s in)
    fakeEngine.emitPosition(const Duration(milliseconds: 2500));
    await tester.pump();

    expect(container.read(sequenceControllerProvider).currentEntryIndex, equals(1));
    expect(find.byIcon(Icons.volume_up), findsOneWidget);

    // Stop playback
    await tester.tap(find.byKey(const Key('sequence_play_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(container.read(sequenceControllerProvider).isPlaying, isFalse);
    expect(find.byIcon(Icons.volume_up), findsNothing);
  });

  testWidgets('SequenceLibraryScreen allows loading, renaming, and deleting sequences', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.resetPhysicalSize);

    final initialSeq = Sequence(
      id: 'seq-1',
      name: 'Initial Song',
      entries: [SequenceEntry(patternId: 'pat-a', repeats: 2)],
    );
    fakeStore.savedSequenceLibrary = [initialSeq];

    final container = ProviderContainer(
      overrides: [
        audioEngineProvider.overrideWithValue(fakeEngine),
        settingsStoreProvider.overrideWithValue(fakeStore),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sequenceLibraryProvider.notifier).loadFromStore();

    await tester.pumpWidget(buildTestableWidget(const SequenceLibraryScreen(), container));
    await tester.pumpAndSettle();

    // Verify listed sequence
    expect(find.text('Initial Song'), findsOneWidget);
    expect(find.textContaining('1 entry'), findsOneWidget);

    // Rename sequence
    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Sequence'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Renamed Song');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Renamed Song'), findsOneWidget);
    expect(container.read(sequenceLibraryProvider).first.name, equals('Renamed Song'));

    // Tap to load
    await tester.tap(find.text('Renamed Song'));
    await tester.pumpAndSettle();

    expect(container.read(sequenceControllerProvider).sequence.name, equals('Renamed Song'));

    // Test delete directly on the screen
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Sequence'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No sequences yet'), findsOneWidget);
    expect(container.read(sequenceLibraryProvider), isEmpty);
  });
}
