import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/tempo.dart';

void main() {
  group('Pattern Domain Model', () {
    test('new empty pattern defaults to stepCount 16, tempo 120, and 8 tracks of 16 inactive steps', () {
      final pattern = Pattern();

      expect(pattern.stepCount, equals(Pattern.defaultStepCount));
      expect(pattern.stepCount, equals(16));
      expect(pattern.tempoBpm, equals(Pattern.defaultTempoBpm));
      expect(pattern.tempoBpm, equals(120));
      expect(pattern.id, equals(''));
      expect(pattern.name, equals(''));
      expect(pattern.tracks.length, equals(Pattern.trackCount));
      expect(pattern.tracks.length, equals(8));

      for (int t = 0; t < Pattern.trackCount; t++) {
        expect(pattern.tracks[t].length, equals(Pattern.stepsPerTrack));
        expect(pattern.tracks[t].length, equals(16));
        for (int s = 0; s < Pattern.stepsPerTrack; s++) {
          expect(pattern.tracks[t][s], isFalse);
          expect(pattern.isStepOn(t, s), isFalse);
        }
      }
    });

    test('Pattern.empty factory creates configured pattern with all steps inactive', () {
      final pattern = Pattern.empty(
        id: 'pat-1',
        name: 'Rock Beat',
        tempoBpm: 140,
        stepCount: 12,
      );

      expect(pattern.id, equals('pat-1'));
      expect(pattern.name, equals('Rock Beat'));
      expect(pattern.tempoBpm, equals(140));
      expect(pattern.stepCount, equals(12));
      for (int t = 0; t < Pattern.trackCount; t++) {
        expect(pattern.tracks[t], equals(List.filled(16, false)));
      }
    });

    test('step count below 4 or above 16 is clamped to [4, 16]', () {
      expect(Pattern(stepCount: 0).stepCount, equals(4));
      expect(Pattern(stepCount: 3).stepCount, equals(4));
      expect(Pattern(stepCount: 4).stepCount, equals(4));
      expect(Pattern(stepCount: 16).stepCount, equals(16));
      expect(Pattern(stepCount: 17).stepCount, equals(16));
      expect(Pattern(stepCount: 32).stepCount, equals(16));

      final base = Pattern(stepCount: 8);
      expect(base.setStepCount(2).stepCount, equals(4));
      expect(base.setStepCount(20).stepCount, equals(16));
      expect(base.copyWith(stepCount: 1).stepCount, equals(4));
      expect(base.copyWith(stepCount: 99).stepCount, equals(16));
    });

    test('tempoBpm is clamped between 30 and 300', () {
      expect(Pattern(tempoBpm: 10).tempoBpm, equals(Tempo.minBpm));
      expect(Pattern(tempoBpm: 400).tempoBpm, equals(Tempo.maxBpm));
      expect(Pattern(tempoBpm: 135).tempoBpm, equals(135));

      final base = Pattern(tempoBpm: 120);
      expect(base.copyWith(tempoBpm: 15).tempoBpm, equals(30));
      expect(base.copyWith(tempoBpm: 500).tempoBpm, equals(300));
    });

    test('tracks cannot be mutated directly because lists are unmodifiable', () {
      final pattern = Pattern();
      expect(() => pattern.tracks[0][0] = true, throwsUnsupportedError);
      expect(() => pattern.tracks.add([]), throwsUnsupportedError);
    });

    test('toggle step does not mutate the original pattern instance', () {
      final original = Pattern(id: 'orig', name: 'Original');
      expect(original.isStepOn(2, 5), isFalse);

      final modified = original.toggle(2, 5);

      // Returned pattern has step flipped
      expect(modified.isStepOn(2, 5), isTrue);
      expect(modified.tracks[2][5], isTrue);

      // Original is completely unchanged
      expect(original.isStepOn(2, 5), isFalse);
      expect(original.tracks[2][5], isFalse);
      expect(original.id, equals(modified.id));
      expect(original.name, equals(modified.name));

      // Toggling again flips it back to false
      final toggledBack = modified.toggleStep(2, 5);
      expect(toggledBack.isStepOn(2, 5), isFalse);
      expect(toggledBack, equals(original));
    });

    test('toggle rejects out-of-bound track or step indices', () {
      final pattern = Pattern();
      expect(() => pattern.toggle(-1, 0), throwsRangeError);
      expect(() => pattern.toggle(8, 0), throwsRangeError);
      expect(() => pattern.toggle(0, -1), throwsRangeError);
      expect(() => pattern.toggle(0, 16), throwsRangeError);
      expect(() => pattern.isStepOn(-1, 0), throwsRangeError);
      expect(() => pattern.isStepOn(0, 16), throwsRangeError);
    });

    test('shrink then grow preserves previously entered steps', () {
      // Step 14 of track 2 is on
      final initial = Pattern(stepCount: 16).toggle(2, 14);
      expect(initial.isStepOn(2, 14), isTrue);

      // Step count reduced to 8
      final shrunk = initial.setStepCount(8);
      expect(shrunk.stepCount, equals(8));
      // Stored step is still preserved in underlying tracks
      expect(shrunk.isStepOn(2, 14), isTrue);

      // Step count set back to 16
      final restored = shrunk.setStepCount(16);
      expect(restored.stepCount, equals(16));
      expect(restored.isStepOn(2, 14), isTrue);
      expect(restored, equals(initial));
    });

    test('clear turns all 8x16 steps off while keeping metadata', () {
      final configured = Pattern(
        id: 'pat-42',
        name: 'Funk Beat',
        tempoBpm: 105,
        stepCount: 12,
      ).toggle(0, 0).toggle(1, 4).toggle(2, 8).toggle(7, 15);

      expect(configured.isStepOn(0, 0), isTrue);
      expect(configured.isStepOn(1, 4), isTrue);
      expect(configured.isStepOn(2, 8), isTrue);
      expect(configured.isStepOn(7, 15), isTrue);

      final cleared = configured.clear();

      // Original is not mutated
      expect(configured.isStepOn(0, 0), isTrue);

      // Metadata is unchanged
      expect(cleared.id, equals('pat-42'));
      expect(cleared.name, equals('Funk Beat'));
      expect(cleared.tempoBpm, equals(105));
      expect(cleared.stepCount, equals(12));

      // All 8x16 steps are off
      for (int t = 0; t < Pattern.trackCount; t++) {
        for (int s = 0; s < Pattern.stepsPerTrack; s++) {
          expect(cleared.isStepOn(t, s), isFalse);
        }
      }
    });

    test('copyWith updates individual properties correctly', () {
      final base = Pattern(id: 'base', name: 'Base', tempoBpm: 100, stepCount: 8);
      final updated = base.copyWith(
        id: 'updated',
        name: 'Updated',
        tempoBpm: 130,
        stepCount: 14,
      );

      expect(updated.id, equals('updated'));
      expect(updated.name, equals('Updated'));
      expect(updated.tempoBpm, equals(130));
      expect(updated.stepCount, equals(14));
      expect(base.id, equals('base'));
    });

    test('equality and hashCode compare all metadata and all 8x16 steps', () {
      final p1 = Pattern(id: '1', name: 'P', tempoBpm: 120, stepCount: 16)
          .toggle(0, 0)
          .toggle(3, 7);
      final p2 = Pattern(id: '1', name: 'P', tempoBpm: 120, stepCount: 16)
          .toggle(0, 0)
          .toggle(3, 7);
      final p3 = Pattern(id: '1', name: 'P', tempoBpm: 120, stepCount: 16)
          .toggle(0, 0)
          .toggle(3, 8); // different step

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1, isNot(equals(p1.copyWith(name: 'Other'))));
      expect(p1, isNot(equals(p1.copyWith(id: 'other-id'))));
      expect(p1, isNot(equals(p1.copyWith(tempoBpm: 125))));
      expect(p1, isNot(equals(p1.copyWith(stepCount: 8))));
    });

    test('JSON serialization and deserialization round trip preserves equality', () {
      final pattern = Pattern(
        id: 'pat-json-1',
        name: 'Electro 808',
        tempoBpm: 128,
        stepCount: 16,
      )
          .toggle(0, 0)
          .toggle(0, 4)
          .toggle(0, 8)
          .toggle(0, 12)
          .toggle(1, 2)
          .toggle(2, 6)
          .toggle(7, 14);

      final json = pattern.toJson();

      expect(json['id'], equals('pat-json-1'));
      expect(json['name'], equals('Electro 808'));
      expect(json['tempoBpm'], equals(128));
      expect(json['stepCount'], equals(16));
      expect(json['tracks'], isA<List>());
      expect((json['tracks'] as List).length, equals(8));

      final restored = Pattern.fromJson(json);

      expect(restored, equals(pattern));
      expect(restored.id, equals(pattern.id));
      expect(restored.name, equals(pattern.name));
      expect(restored.tempoBpm, equals(pattern.tempoBpm));
      expect(restored.stepCount, equals(pattern.stepCount));
      expect(restored.tracks, equals(pattern.tracks));
    });

    test('deserialization rejects malformed track data with descriptive errors', () {
      final validMap = Pattern(id: '1', name: 'Test').toJson();

      // Fewer than 8 tracks
      final fewerTracks = Map<String, dynamic>.from(validMap)
        ..['tracks'] = (validMap['tracks'] as List).take(7).toList();
      expect(
        () => Pattern.fromJson(fewerTracks),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('Expected exactly 8 tracks'),
          ),
        ),
      );

      // More than 8 tracks
      final moreTracks = Map<String, dynamic>.from(validMap)
        ..['tracks'] = [
          ...(validMap['tracks'] as List),
          List.filled(16, false),
        ];
      expect(
        () => Pattern.fromJson(moreTracks),
        throwsA(isA<ArgumentError>()),
      );

      // Track length not 16
      final wrongTrackLength = Map<String, dynamic>.from(validMap)
        ..['tracks'] = [
          List.filled(12, false),
          for (int i = 1; i < 8; i++) List.filled(16, false),
        ];
      expect(
        () => Pattern.fromJson(wrongTrackLength),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('must have exactly 16 steps'),
          ),
        ),
      );

      // Track is not a list
      final nonListTrack = Map<String, dynamic>.from(validMap)
        ..['tracks'] = [
          'invalid',
          for (int i = 1; i < 8; i++) List.filled(16, false),
        ];
      expect(
        () => Pattern.fromJson(nonListTrack),
        throwsA(isA<ArgumentError>()),
      );

      // Step is not a boolean
      final nonBoolStep = Map<String, dynamic>.from(validMap)
        ..['tracks'] = [
          [1, ...List.filled(15, false)],
          for (int i = 1; i < 8; i++) List.filled(16, false),
        ];
      expect(
        () => Pattern.fromJson(nonBoolStep),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deserialization rejects missing or invalid root properties', () {
      final valid = Pattern(id: '1', name: 'Test').toJson();

      expect(
        () => Pattern.fromJson(Map.from(valid)..remove('id')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Pattern.fromJson(Map.from(valid)..['id'] = 123),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Pattern.fromJson(Map.from(valid)..remove('name')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Pattern.fromJson(Map.from(valid)..remove('tempoBpm')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Pattern.fromJson(Map.from(valid)..remove('stepCount')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Pattern.fromJson(Map.from(valid)..remove('tracks')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('constructor rejects invalid track dimensions when provided directly', () {
      expect(
        () => Pattern(tracks: List.generate(7, (_) => List.filled(16, false))),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Pattern(
          tracks: [
            List.filled(15, false),
            for (int i = 1; i < 8; i++) List.filled(16, false),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toString formatting includes key metadata', () {
      final pattern = Pattern(id: 'p1', name: 'Test', tempoBpm: 125, stepCount: 8);
      expect(
        pattern.toString(),
        equals('Pattern(id: p1, name: "Test", tempoBpm: 125, stepCount: 8, kitId: "classic-synth", schemaVersion: 1)'),
      );
    });

    test('missing schemaVersion defaults to 1 when deserializing from JSON', () {
      final json = Pattern(id: 'pat-1', name: 'Test').toJson();
      json.remove('schemaVersion');
      final restored = Pattern.fromJson(json);
      expect(restored.schemaVersion, equals(1));
    });

    test('kitId defaults to classic-synth and round-trips correctly', () {
      final defaultPattern = Pattern();
      expect(defaultPattern.kitId, equals('classic-synth'));

      final retroPattern = Pattern(id: 'p-retro', kitId: 'retro-8bit');
      expect(retroPattern.kitId, equals('retro-8bit'));

      final json = retroPattern.toJson();
      expect(json['kitId'], equals('retro-8bit'));

      final restored = Pattern.fromJson(json);
      expect(restored.kitId, equals('retro-8bit'));
      expect(restored, equals(retroPattern));

      final updated = retroPattern.copyWith(kitId: 'classic-synth');
      expect(updated.kitId, equals('classic-synth'));
    });

    test('backward compatibility: missing kitId in JSON defaults to classic-synth', () {
      final json = Pattern(id: 'pat-legacy', name: 'Legacy').toJson();
      json.remove('kitId');
      expect(json.containsKey('kitId'), isFalse);

      final restored = Pattern.fromJson(json);
      expect(restored.kitId, equals('classic-synth'));
    });
  });
}

