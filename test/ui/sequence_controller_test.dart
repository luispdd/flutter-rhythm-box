import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/synth/synth_timing.dart';
import 'package:rhythm_box/ui/metronome_controller.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequence_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';

import '../audio/fake_audio_engine.dart';
import '../audio/fake_background_audio_service.dart';
import '../persistence/fake_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SequenceController', () {
    late FakeAudioEngine fakeEngine;
    late FakeSettingsStore fakeStore;
    late FakeBackgroundAudioService fakeBackgroundService;
    late ProviderContainer container;

    final patternA = Pattern(
      id: 'pat-a',
      name: 'Beat A',
      tempoBpm: 120,
      stepCount: 16,
    );

    final patternB = Pattern(
      id: 'pat-b',
      name: 'Beat B',
      tempoBpm: 140,
      stepCount: 12,
    );

    setUp(() {
      fakeEngine = FakeAudioEngine();
      fakeStore = FakeSettingsStore();
      fakeBackgroundService = FakeBackgroundAudioService();
      fakeStore.savedPatternLibrary = [patternA, patternB];

      container = ProviderContainer(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
          settingsStoreProvider.overrideWithValue(fakeStore),
          backgroundAudioServiceProvider
              .overrideWithValue(fakeBackgroundService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has empty sequence and is not playing', () {
      final state = container.read(sequenceControllerProvider);
      expect(state.isPlaying, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.sequence.entries, isEmpty);
      expect(state.currentEntryIndex, equals(-1));
    });

    test('setSequence, updateName, and toggleLoop', () {
      final controller = container.read(sequenceControllerProvider.notifier);
      final initialSeq = Sequence(
        id: 'seq-1',
        name: 'My Sequence',
        loop: true,
        entries: [SequenceEntry(patternId: 'pat-a', repeats: 2)],
      );

      controller.setSequence(initialSeq);
      expect(container.read(sequenceControllerProvider).sequence.name, equals('My Sequence'));
      expect(container.read(sequenceControllerProvider).sequence.entries, hasLength(1));

      controller.updateName('New Name');
      expect(container.read(sequenceControllerProvider).sequence.name, equals('New Name'));

      controller.toggleLoop();
      expect(container.read(sequenceControllerProvider).sequence.loop, isFalse);

      controller.setLoop(true);
      expect(container.read(sequenceControllerProvider).sequence.loop, isTrue);
    });

    test('addEntry, removeEntry, reorderEntries, and setEntryRepeats', () {
      final controller = container.read(sequenceControllerProvider.notifier);
      controller.addEntry('pat-a', repeats: 2);
      controller.addEntry('pat-b', repeats: 1);

      expect(container.read(sequenceControllerProvider).sequence.entries, hasLength(2));
      expect(container.read(sequenceControllerProvider).sequence.entries[0].patternId, equals('pat-a'));
      expect(container.read(sequenceControllerProvider).sequence.entries[1].patternId, equals('pat-b'));

      controller.setEntryRepeats(0, 4);
      expect(container.read(sequenceControllerProvider).sequence.entries[0].repeats, equals(4));

      // Reorder using Flutter ReorderableListView semantics (dragging item 0 below item 1)
      controller.reorderEntries(0, 2);
      expect(container.read(sequenceControllerProvider).sequence.entries[0].patternId, equals('pat-b'));
      expect(container.read(sequenceControllerProvider).sequence.entries[1].patternId, equals('pat-a'));

      controller.removeEntry(0);
      expect(container.read(sequenceControllerProvider).sequence.entries, hasLength(1));
      expect(container.read(sequenceControllerProvider).sequence.entries[0].patternId, equals('pat-a'));
    });

    test('start triggers AudioEngine and mutually stops Metronome and Sequencer', () async {
      // Preload pattern library
      await container.read(patternLibraryProvider.notifier).loadFromStore();

      // Start metronome
      final metronomeController = container.read(metronomeControllerProvider.notifier);
      await metronomeController.start();
      expect(container.read(metronomeControllerProvider).isPlaying, isTrue);

      final seqController = container.read(sequenceControllerProvider.notifier);
      seqController.setSequence(
        Sequence(
          id: 's1',
          name: 'Song',
          loop: true,
          entries: [
            SequenceEntry(patternId: 'pat-a', repeats: 1),
            SequenceEntry(patternId: 'pat-b', repeats: 2),
          ],
        ),
      );

      await seqController.start();

      // Sequence should be playing
      expect(container.read(sequenceControllerProvider).isPlaying, isTrue);
      expect(fakeEngine.isPlaying, isTrue);
      expect(fakeEngine.lastLooping, isTrue);
      expect(fakeEngine.lastStartedBuffer, isNotNull);
      expect(fakeBackgroundService.startCalls, equals(2));

      // Metronome must have been stopped
      expect(container.read(metronomeControllerProvider).isPlaying, isFalse);

      // Now start Sequencer, which should stop Sequence
      final sequencerController = container.read(sequencerControllerProvider.notifier);
      await sequencerController.start();
      expect(container.read(sequencerControllerProvider).isPlaying, isTrue);
      expect(container.read(sequenceControllerProvider).isPlaying, isFalse);

      // Starting Sequence stops Sequencer
      await seqController.start();
      expect(container.read(sequenceControllerProvider).isPlaying, isTrue);
      expect(container.read(sequencerControllerProvider).isPlaying, isFalse);

      // Stopping sequence
      await seqController.stop();
      expect(container.read(sequenceControllerProvider).isPlaying, isFalse);
      expect(fakeEngine.isPlaying, isFalse);
      expect(fakeBackgroundService.stopCalls, greaterThanOrEqualTo(1));
    });

    test('visual playhead tracking maps positionStream to active entry index', () async {
      await container.read(patternLibraryProvider.notifier).loadFromStore();

      const timing = SynthTiming(sampleRate: SynthTiming.defaultSampleRate);
      final samplesA = timing.loopLengthSamples(patternA.stepCount, 120.0); // 16 steps at 120 BPM = 88200 samples = 2.0s
      final durUsA = (samplesA * 1000000 / 44100).round(); // ~2,000,000 us

      final seqController = container.read(sequenceControllerProvider.notifier);
      seqController.setSequence(
        Sequence(
          id: 's1',
          name: 'Track',
          loop: true,
          entries: [
            SequenceEntry(patternId: 'pat-a', repeats: 1), // 0 to ~2s
            SequenceEntry(patternId: 'pat-b', repeats: 1), // ~2s onward
          ],
        ),
      );

      await seqController.start();
      expect(container.read(sequenceControllerProvider).currentEntryIndex, equals(0));

      // Emit position in first entry
      fakeEngine.emitPosition(const Duration(milliseconds: 500));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sequenceControllerProvider).currentEntryIndex, equals(0));

      // Emit position in second entry (e.g. at 2.5s)
      fakeEngine.emitPosition(Duration(microseconds: durUsA + 500000));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sequenceControllerProvider).currentEntryIndex, equals(1));

      await seqController.stop();
      expect(container.read(sequenceControllerProvider).currentEntryIndex, equals(-1));
    });

    test('play-once mode (loop: false) stops playback when position reaches total duration', () async {
      await container.read(patternLibraryProvider.notifier).loadFromStore();

      const timing = SynthTiming(sampleRate: SynthTiming.defaultSampleRate);
      final samplesA = timing.loopLengthSamples(patternA.stepCount, 120.0);
      final durUsA = (samplesA * 1000000 / 44100).round();

      final seqController = container.read(sequenceControllerProvider.notifier);
      seqController.setSequence(
        Sequence(
          id: 's1',
          name: 'One shot',
          loop: false,
          entries: [
            SequenceEntry(patternId: 'pat-a', repeats: 1),
          ],
        ),
      );

      await seqController.start();
      expect(container.read(sequenceControllerProvider).isPlaying, isTrue);
      expect(fakeEngine.lastLooping, isFalse);

      // Emit position beyond total duration
      fakeEngine.emitPosition(Duration(microseconds: durUsA + 100000));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(sequenceControllerProvider).isPlaying, isFalse);
    });
  });
}
