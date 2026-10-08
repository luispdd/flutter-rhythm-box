import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';
import 'package:rhythm_box/ui/sequence_library_notifier.dart';

import '../persistence/fake_settings_store.dart';

void main() {
  group('SequenceLibraryNotifier', () {
    late FakeSettingsStore fakeStore;
    late ProviderContainer container;

    setUp(() {
      fakeStore = FakeSettingsStore();
      container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(fakeStore),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with empty library if store has no sequences', () async {
      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      final state = container.read(sequenceLibraryProvider);
      expect(state, isEmpty);
    });

    test('initializes with loaded sequences from store', () async {
      final initial = [
        Sequence(id: 's1', name: 'Song 1', entries: [SequenceEntry(patternId: 'p1')]),
        Sequence(id: 's2', name: 'Song 2', entries: [SequenceEntry(patternId: 'p2')]),
      ];
      fakeStore.savedSequenceLibrary = initial;

      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      final state = container.read(sequenceLibraryProvider);
      expect(state, equals(initial));
    });

    test('saveSequence adds and replaces sequences', () async {
      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      final seq1 = Sequence(id: 's1', name: 'Intro', entries: [SequenceEntry(patternId: 'p1')]);
      await notifier.saveSequence(seq1);

      expect(container.read(sequenceLibraryProvider), hasLength(1));
      expect(container.read(sequenceLibraryProvider).first.name, equals('Intro'));
      expect(fakeStore.savedSequenceLibrary, hasLength(1));

      // Replace with updated version
      final updatedSeq1 = seq1.copyWith(name: 'Updated Intro');
      await notifier.saveSequence(updatedSeq1);

      expect(container.read(sequenceLibraryProvider), hasLength(1));
      expect(container.read(sequenceLibraryProvider).first.name, equals('Updated Intro'));
      expect(fakeStore.savedSequenceLibrary.first.name, equals('Updated Intro'));
    });

    test('renameSequence renames sequence and saves to store', () async {
      final seq = Sequence(id: 's1', name: 'Old Name');
      fakeStore.savedSequenceLibrary = [seq];

      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.renameSequence('s1', 'New Name');

      expect(container.read(sequenceLibraryProvider).first.name, equals('New Name'));
      expect(fakeStore.savedSequenceLibrary.first.name, equals('New Name'));
    });

    test('deleteSequence removes sequence and saves to store', () async {
      final seq1 = Sequence(id: 's1', name: 'Seq 1');
      final seq2 = Sequence(id: 's2', name: 'Seq 2');
      fakeStore.savedSequenceLibrary = [seq1, seq2];

      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.deleteSequence('s1');

      final state = container.read(sequenceLibraryProvider);
      expect(state, hasLength(1));
      expect(state.first.id, equals('s2'));
      expect(fakeStore.savedSequenceLibrary, hasLength(1));
      expect(fakeStore.savedSequenceLibrary.first.id, equals('s2'));
    });

    test('sequencesReferencingPattern finds all matching sequences', () async {
      final s1 = Sequence(id: 's1', entries: [
        SequenceEntry(patternId: 'target'),
        SequenceEntry(patternId: 'other'),
      ]);
      final s2 = Sequence(id: 's2', entries: [
        SequenceEntry(patternId: 'other'),
      ]);
      final s3 = Sequence(id: 's3', entries: [
        SequenceEntry(patternId: 'target', repeats: 3),
      ]);
      fakeStore.savedSequenceLibrary = [s1, s2, s3];

      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      final matches = notifier.sequencesReferencingPattern('target');
      expect(matches.map((s) => s.id), containsAll(['s1', 's3']));
      expect(matches.map((s) => s.id), isNot(contains('s2')));
    });

    test('removePatternReferences strips target pattern entries from all sequences', () async {
      final s1 = Sequence(id: 's1', entries: [
        SequenceEntry(patternId: 'del'),
        SequenceEntry(patternId: 'keep'),
      ]);
      final s2 = Sequence(id: 's2', entries: [
        SequenceEntry(patternId: 'keep'),
      ]);
      final s3 = Sequence(id: 's3', entries: [
        SequenceEntry(patternId: 'del'),
      ]);
      fakeStore.savedSequenceLibrary = [s1, s2, s3];

      final notifier = container.read(sequenceLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.removePatternReferences('del');

      final state = container.read(sequenceLibraryProvider);
      expect(state[0].entries, hasLength(1));
      expect(state[0].entries.first.patternId, equals('keep'));

      expect(state[1].entries, hasLength(1));
      expect(state[1].entries.first.patternId, equals('keep'));

      expect(state[2].entries, isEmpty);

      expect(fakeStore.savedSequenceLibrary[0].entries, hasLength(1));
      expect(fakeStore.savedSequenceLibrary[2].entries, isEmpty);
    });

    test('deleting a pattern via PatternLibraryNotifier cascades removal of pattern entries from sequences', () async {
      final patternToDelete = Pattern.empty(id: 'pat-to-delete', name: 'Delete Me');
      final patternToKeep = Pattern.empty(id: 'pat-keep', name: 'Keep Me');
      fakeStore.savedPatternLibrary = [patternToDelete, patternToKeep];

      final seq = Sequence(id: 'seq-1', name: 'My Song', entries: [
        SequenceEntry(patternId: 'pat-to-delete', repeats: 2),
        SequenceEntry(patternId: 'pat-keep', repeats: 1),
      ]);
      fakeStore.savedSequenceLibrary = [seq];

      final patternNotifier = container.read(patternLibraryProvider.notifier);
      final sequenceNotifier = container.read(sequenceLibraryProvider.notifier);

      await patternNotifier.loadFromStore();
      await sequenceNotifier.loadFromStore();

      // Delete the pattern from pattern library
      await patternNotifier.deletePattern('pat-to-delete');

      // Verify pattern is deleted from pattern library
      expect(container.read(patternLibraryProvider), hasLength(1));
      expect(container.read(patternLibraryProvider).first.id, equals('pat-keep'));

      // Verify cascading removal in sequence library
      final updatedSequences = container.read(sequenceLibraryProvider);
      expect(updatedSequences, hasLength(1));
      expect(updatedSequences.first.entries, hasLength(1));
      expect(updatedSequences.first.entries.first.patternId, equals('pat-keep'));
      expect(fakeStore.savedSequenceLibrary.first.entries, hasLength(1));
      expect(fakeStore.savedSequenceLibrary.first.entries.first.patternId, equals('pat-keep'));
    });
  });
}
