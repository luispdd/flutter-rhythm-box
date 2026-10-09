import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/library_validator.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';

void main() {
  group('LibraryValidator', () {
    final validPattern1 = Pattern(id: 'pat_1', name: 'Pattern 1', tempoBpm: 120);
    final validPattern2 = Pattern(id: 'pat_2', name: 'Pattern 2', tempoBpm: 90);
    final validSequence1 = Sequence(
      id: 'seq_1',
      name: 'Sequence 1',
      entries: [
        SequenceEntry(patternId: 'pat_1', repeats: 2),
        SequenceEntry(patternId: 'pat_2', repeats: 1),
      ],
    );

    Map<String, dynamic> createValidLibraryMap({
      List<Pattern>? patterns,
      List<Sequence>? sequences,
      int formatVersion = 1,
      String format = 'rhythm-box-library',
    }) {
      return {
        'format': format,
        'formatVersion': formatVersion,
        'exportedAt': '2026-10-08T14:00:00Z',
        'appVersion': '1.0.0',
        'patterns': (patterns ?? [validPattern1, validPattern2])
            .map((p) => p.toJson())
            .toList(),
        'sequences': (sequences ?? [validSequence1])
            .map((s) => s.toJson())
            .toList(),
      };
    }

    test('valid file returns success with parsed LibraryData', () {
      final map = createValidLibraryMap();
      final result = LibraryValidator.validateJsonString(jsonEncode(map));

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.data, isNotNull);
      expect(result.data!.patterns.length, equals(2));
      expect(result.data!.sequences.length, equals(1));
    });

    test('valid empty library (0 patterns and 0 sequences) passes', () {
      final map = createValidLibraryMap(patterns: [], sequences: []);
      final result = LibraryValidator.validateJsonString(jsonEncode(map));

      expect(result.isValid, isTrue);
      expect(result.data!.patterns, isEmpty);
      expect(result.data!.sequences, isEmpty);
    });

    test('rejects file exceeding size limit', () {
      final result = LibraryValidator.validateJsonString(
        '{}',
        byteLength: 11 * 1024 * 1024,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('10 MB'));
    });

    test('rejects invalid JSON string', () {
      final result = LibraryValidator.validateJsonString('{not json');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('File is not valid JSON'));
    });

    test('rejects root JSON if not an object', () {
      final result = LibraryValidator.validateJsonString('["not", "an", "object"]');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Root must be a JSON object'));
    });

    test('rejects missing or wrong format', () {
      final map = createValidLibraryMap(format: 'wrong-format');
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid format'));
    });

    test('rejects newer formatVersion with specific message', () {
      final map = createValidLibraryMap(formatVersion: 2);
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('newer version of the app'));
    });

    test('rejects missing patterns list', () {
      final map = createValidLibraryMap();
      map.remove('patterns');
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('patterns'));
    });

    test('rejects missing sequences list', () {
      final map = createValidLibraryMap();
      map.remove('sequences');
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('sequences'));
    });

    test('rejects invalid pattern content', () {
      final map = createValidLibraryMap();
      (map['patterns'] as List)[0] = {'id': 'p1', 'name': 'Missing fields'};
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid pattern'));
    });

    test('rejects duplicate pattern IDs', () {
      final dupPattern = Pattern(id: 'pat_1', name: 'Duplicate Pattern');
      final map = createValidLibraryMap(
        patterns: [validPattern1, dupPattern],
        sequences: [],
      );
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Duplicate pattern ID'));
    });

    test('rejects duplicate sequence IDs', () {
      final seq1 = Sequence(id: 'seq_same', name: 'Seq 1');
      final seq2 = Sequence(id: 'seq_same', name: 'Seq 2');
      final map = createValidLibraryMap(
        patterns: [],
        sequences: [seq1, seq2],
      );
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Duplicate sequence ID'));
    });

    test('rejects sequence referencing nonexistent pattern ID', () {
      final badSequence = Sequence(
        id: 'seq_bad',
        name: 'Dangling Seq',
        entries: [
          SequenceEntry(patternId: 'non_existent_pat', repeats: 1),
        ],
      );
      final map = createValidLibraryMap(
        patterns: [validPattern1],
        sequences: [badSequence],
      );
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('references missing pattern'));
    });

    test('rejects sequence with invalid repeat count (< 1 or > 99)', () {
      final map = createValidLibraryMap(
        patterns: [validPattern1],
        sequences: [],
      );
      map['sequences'] = [
        {
          'id': 'seq_bad_repeats',
          'name': 'Bad Repeats',
          'loop': true,
          'kitId': 'classic-synth',
          'schemaVersion': 1,
          'entries': [
            {'patternId': 'pat_1', 'repeats': 150},
          ],
        }
      ];
      final result = LibraryValidator.validateJsonString(jsonEncode(map));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('invalid repeats'));
    });
  });
}
