import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/kit.dart';
import 'package:rhythm_box/domain/voice.dart';

void main() {
  group('Kit Domain Model', () {
    test('classicSynth default matches specification', () {
      final kit = Kit.classicSynth;
      expect(kit.id, equals('classic-synth'));
      expect(kit.name, equals('Classic synth'));
      expect(kit.builtIn, isTrue);
      expect(kit.voices.length, equals(8));
      expect(kit.voices[0].label, equals('Kick'));
      expect(kit.voices[7].label, equals('Hat'));
    });

    test('serializes and deserializes JSON round-trip', () {
      final kit = Kit.classicSynth;
      final json = kit.toJson();
      expect(json['schemaVersion'], equals(1));
      expect(json['id'], equals('classic-synth'));
      expect(json['name'], equals('Classic synth'));
      expect(json['builtIn'], isTrue);
      expect((json['voices'] as List).length, equals(8));

      final restored = Kit.fromJson(json);
      expect(restored, equals(kit));
      expect(restored.hashCode, equals(kit.hashCode));
      expect(restored.toString(), contains('Kit(id: classic-synth'));
    });

    test('rejects kits with invalid voice count', () {
      final sevenVoices = defaultVoices.take(7).toList();
      expect(
        () => Kit(id: 'test', name: 'Test', voices: sevenVoices),
        throwsArgumentError,
      );

      final nineVoices = [...defaultVoices, defaultVoices.first];
      expect(
        () => Kit(id: 'test', name: 'Test', voices: nineVoices),
        throwsArgumentError,
      );
    });

    test('rejects kits with empty id or name', () {
      expect(
        () => Kit(id: '', name: 'Test', voices: defaultVoices),
        throwsArgumentError,
      );
      expect(
        () => Kit(id: 'test', name: '   ', voices: defaultVoices),
        throwsArgumentError,
      );
    });

    test('rejects out of range voice parameters', () {
      // Out of range dutyCycle
      final invalidDuty = defaultVoices.map((v) => v).toList();
      invalidDuty[0] = invalidDuty[0].copyWith(dutyCycle: 1.5);
      expect(
        () => Kit(id: 'test', name: 'Test', voices: invalidDuty),
        throwsArgumentError,
      );

      // Out of range bitDepth
      final invalidBitDepth = defaultVoices.map((v) => v).toList();
      invalidBitDepth[0] = invalidBitDepth[0].copyWith(bitDepth: 24);
      expect(
        () => Kit(id: 'test', name: 'Test', voices: invalidBitDepth),
        throwsArgumentError,
      );

      // Negative decayMs
      final invalidDecay = defaultVoices.map((v) => v).toList();
      invalidDecay[0] = invalidDecay[0].copyWith(decayMs: -10.0);
      expect(
        () => Kit(id: 'test', name: 'Test', voices: invalidDecay),
        throwsArgumentError,
      );
    });

    test('copyWith creates updated Kit', () {
      final kit = Kit.classicSynth;
      final updated = kit.copyWith(name: 'Updated Name', builtIn: false);
      expect(updated.id, equals('classic-synth'));
      expect(updated.name, equals('Updated Name'));
      expect(updated.builtIn, isFalse);
      expect(updated.voices, equals(kit.voices));
    });
  });
}
