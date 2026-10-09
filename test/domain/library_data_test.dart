import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/library_data.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';

void main() {
  group('LibraryData', () {
    test('initializes with default envelope values', () {
      final data = LibraryData();
      expect(data.format, equals('rhythm-box-library'));
      expect(data.formatVersion, equals(1));
      expect(data.appVersion, equals('1.0.0'));
      expect(data.patterns, isEmpty);
      expect(data.sequences, isEmpty);
      expect(data.exportedAt, isNotEmpty);
    });

    test('serializes and deserializes cleanly (round-trip)', () {
      final pattern = Pattern(
        id: 'pat_1',
        name: 'Funk Beat',
        tempoBpm: 110,
        stepCount: 16,
        kitId: 'classic-synth',
      );
      final sequence = Sequence(
        id: 'seq_1',
        name: 'Track 1',
        loop: true,
        kitId: 'retro-8bit',
        entries: [
          SequenceEntry(patternId: 'pat_1', repeats: 4),
        ],
      );

      final original = LibraryData(
        exportedAt: '2026-10-08T12:00:00Z',
        appVersion: '1.0.0',
        patterns: [pattern],
        sequences: [sequence],
      );

      final jsonMap = original.toJson();
      expect(jsonMap['format'], equals('rhythm-box-library'));
      expect(jsonMap['formatVersion'], equals(1));
      expect(jsonMap['exportedAt'], equals('2026-10-08T12:00:00Z'));
      expect(jsonMap['patterns'], hasLength(1));
      expect(jsonMap['sequences'], hasLength(1));

      final fromMap = LibraryData.fromJson(jsonMap);
      expect(fromMap, equals(original));

      final jsonStr = original.toJsonString(pretty: true);
      expect(jsonStr, contains('"format": "rhythm-box-library"'));
      expect(jsonStr, contains('"name": "Funk Beat"'));

      final fromString = LibraryData.fromJsonString(jsonStr);
      expect(fromString, equals(original));
    });

    test('throws FormatException when envelope format is missing or invalid', () {
      expect(
        () => LibraryData.fromJson({
          'formatVersion': 1,
          'patterns': [],
          'sequences': [],
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LibraryData.fromJson({
          'format': 123,
          'formatVersion': 1,
          'patterns': [],
          'sequences': [],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when formatVersion is missing or invalid', () {
      expect(
        () => LibraryData.fromJson({
          'format': 'rhythm-box-library',
          'patterns': [],
          'sequences': [],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when patterns or sequences list is missing', () {
      expect(
        () => LibraryData.fromJson({
          'format': 'rhythm-box-library',
          'formatVersion': 1,
          'sequences': [],
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LibraryData.fromJson({
          'format': 'rhythm-box-library',
          'formatVersion': 1,
          'patterns': [],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
