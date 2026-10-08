import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/sequence.dart';

void main() {
  group('SequenceEntry Domain Model', () {
    test('defaults to 1 repeat and clamps values to [1, 99]', () {
      final defaultEntry = SequenceEntry(patternId: 'p1');
      expect(defaultEntry.patternId, equals('p1'));
      expect(defaultEntry.repeats, equals(1));

      expect(SequenceEntry(patternId: 'p1', repeats: 0).repeats, equals(1));
      expect(SequenceEntry(patternId: 'p1', repeats: -5).repeats, equals(1));
      expect(SequenceEntry(patternId: 'p1', repeats: 1).repeats, equals(1));
      expect(SequenceEntry(patternId: 'p1', repeats: 50).repeats, equals(50));
      expect(SequenceEntry(patternId: 'p1', repeats: 99).repeats, equals(99));
      expect(SequenceEntry(patternId: 'p1', repeats: 100).repeats, equals(99));

      final copied = defaultEntry.copyWith(repeats: 150);
      expect(copied.repeats, equals(99));
      expect(copied.copyWith(repeats: 0).repeats, equals(1));
    });

    test('value equality and hashCode', () {
      final a1 = SequenceEntry(patternId: 'p1', repeats: 4);
      final a2 = SequenceEntry(patternId: 'p1', repeats: 4);
      final b = SequenceEntry(patternId: 'p2', repeats: 4);
      final c = SequenceEntry(patternId: 'p1', repeats: 2);

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(b)));
      expect(a1, isNot(equals(c)));
    });

    test('serialization and round-trip', () {
      final entry = SequenceEntry(patternId: 'p1', repeats: 3);
      final json = entry.toJson();
      expect(json, equals({'patternId': 'p1', 'repeats': 3}));

      final restored = SequenceEntry.fromJson(json);
      expect(restored, equals(entry));
    });

    test('fromJson validates types and throws ArgumentError on invalid input', () {
      expect(
        () => SequenceEntry.fromJson({'patternId': 123, 'repeats': 1}),
        throwsArgumentError,
      );
      expect(
        () => SequenceEntry.fromJson({'patternId': 'p1', 'repeats': 'invalid'}),
        throwsArgumentError,
      );
    });
  });

  group('Sequence Domain Model', () {
    test('defaults and empty factory', () {
      final emptySeq = Sequence.empty(id: 's1', name: 'Intro Track');
      expect(emptySeq.id, equals('s1'));
      expect(emptySeq.name, equals('Intro Track'));
      expect(emptySeq.loop, isTrue);
      expect(emptySeq.isLooping, isTrue);
      expect(emptySeq.entries, isEmpty);

      final direct = Sequence();
      expect(direct.id, equals(''));
      expect(direct.name, equals(''));
      expect(direct.loop, isTrue);
      expect(direct.entries, isEmpty);
    });

    test('entries list is unmodifiable', () {
      final entry = SequenceEntry(patternId: 'p1', repeats: 2);
      final seq = Sequence(entries: [entry]);
      expect(() => seq.entries.add(entry), throwsUnsupportedError);
    });

    test('copyWith updates properties correctly', () {
      final seq = Sequence(id: 's1', name: 'Song', loop: true, entries: [
        SequenceEntry(patternId: 'p1', repeats: 2),
      ]);

      final updated = seq.copyWith(
        name: 'Updated Song',
        loop: false,
        entries: [
          SequenceEntry(patternId: 'p1', repeats: 1),
          SequenceEntry(patternId: 'p2', repeats: 4),
        ],
      );

      expect(updated.id, equals('s1'));
      expect(updated.name, equals('Updated Song'));
      expect(updated.loop, isFalse);
      expect(updated.entries.length, equals(2));
      expect(updated.entries[1].patternId, equals('p2'));
    });

    test('value equality and hashCode', () {
      final e1 = SequenceEntry(patternId: 'p1', repeats: 2);
      final e2 = SequenceEntry(patternId: 'p2', repeats: 1);

      final s1 = Sequence(id: 's1', name: 'Seq', loop: true, entries: [e1, e2]);
      final s2 = Sequence(id: 's1', name: 'Seq', loop: true, entries: [e1, e2]);
      final sDiffEntries = Sequence(id: 's1', name: 'Seq', loop: true, entries: [e1]);
      final sDiffLoop = Sequence(id: 's1', name: 'Seq', loop: false, entries: [e1, e2]);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(sDiffEntries)));
      expect(s1, isNot(equals(sDiffLoop)));
    });

    test('round-trip JSON serialization', () {
      final seq = Sequence(
        id: 'seq-123',
        name: 'Full Song',
        loop: false,
        entries: [
          SequenceEntry(patternId: 'pat-intro', repeats: 2),
          SequenceEntry(patternId: 'pat-verse', repeats: 4),
          SequenceEntry(patternId: 'pat-chorus', repeats: 2),
        ],
      );

      final json = seq.toJson();
      expect(json, equals({
        'schemaVersion': 1,
        'id': 'seq-123',
        'name': 'Full Song',
        'loop': false,
        'entries': [
          {'patternId': 'pat-intro', 'repeats': 2},
          {'patternId': 'pat-verse', 'repeats': 4},
          {'patternId': 'pat-chorus', 'repeats': 2},
        ],
      }));

      final restored = Sequence.fromJson(json);
      expect(restored, equals(seq));
    });

    test('missing schemaVersion defaults to 1 when deserializing from JSON', () {
      final json = Sequence(id: 's1', name: 'Seq').toJson();
      json.remove('schemaVersion');
      final restored = Sequence.fromJson(json);
      expect(restored.schemaVersion, equals(1));
    });

    test('fromJson validates properties and handles invalid inputs', () {
      expect(
        () => Sequence.fromJson({'id': 123, 'name': 'N', 'loop': true, 'entries': []}),
        throwsArgumentError,
      );
      expect(
        () => Sequence.fromJson({'id': 's1', 'name': 123, 'loop': true, 'entries': []}),
        throwsArgumentError,
      );
      expect(
        () => Sequence.fromJson({'id': 's1', 'name': 'N', 'loop': 'invalid', 'entries': []}),
        throwsArgumentError,
      );
      expect(
        () => Sequence.fromJson({'id': 's1', 'name': 'N', 'loop': true, 'entries': 'not-a-list'}),
        throwsArgumentError,
      );
    });
  });
}
