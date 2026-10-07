import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/voice.dart';

void main() {
  group('Waveform Enum', () {
    test('serializes to string name', () {
      expect(Waveform.sine.toJson(), equals('sine'));
      expect(Waveform.triangle.toJson(), equals('triangle'));
      expect(Waveform.square.toJson(), equals('square'));
      expect(Waveform.noise.toJson(), equals('noise'));
    });

    test('deserializes known waveform names', () {
      expect(Waveform.fromJson('sine'), equals(Waveform.sine));
      expect(Waveform.fromJson('triangle'), equals(Waveform.triangle));
      expect(Waveform.fromJson('square'), equals(Waveform.square));
      expect(Waveform.fromJson('noise'), equals(Waveform.noise));
    });

    test('deserializes case-insensitively', () {
      expect(Waveform.fromJson('SINE'), equals(Waveform.sine));
      expect(Waveform.fromJson('Triangle'), equals(Waveform.triangle));
      expect(Waveform.fromJson('SQUARE'), equals(Waveform.square));
      expect(Waveform.fromJson('Noise'), equals(Waveform.noise));
    });

    test('rejects unknown waveform with descriptive error', () {
      expect(
        () => Waveform.fromJson('sawtooth'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown waveform "sawtooth"'),
          ),
        ),
      );
      expect(
        () => Waveform.fromJson(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Voice Domain Model', () {
    test('constructs with expected fields and defaults', () {
      const voice = Voice(
        waveform: Waveform.sine,
        startFreqHz: 150,
        endFreqHz: 45,
        decayMs: 260,
      );

      expect(voice.waveform, equals(Waveform.sine));
      expect(voice.startFreqHz, equals(150.0));
      expect(voice.endFreqHz, equals(45.0));
      expect(voice.decayMs, equals(260.0));
      expect(voice.gain, equals(1.0));
      expect(voice.highpassHz, isNull);
      expect(voice.lowpassHz, isNull);
    });

    test('JSON round-trip preserves all fields including null filters', () {
      const voice = Voice(
        waveform: Waveform.sine,
        startFreqHz: 150.0,
        endFreqHz: 45.0,
        decayMs: 260.0,
        gain: 0.8,
        highpassHz: null,
        lowpassHz: null,
      );

      final json = voice.toJson();
      expect(json, equals({
        'waveform': 'sine',
        'startFreqHz': 150.0,
        'endFreqHz': 45.0,
        'decayMs': 260.0,
        'gain': 0.8,
        'highpassHz': null,
        'lowpassHz': null,
      }));

      final restored = Voice.fromJson(json);
      expect(restored, equals(voice));
      expect(restored.highpassHz, isNull);
      expect(restored.lowpassHz, isNull);
    });

    test('JSON round-trip preserves optional highpass and lowpass filters', () {
      const voice = Voice(
        waveform: Waveform.noise,
        startFreqHz: 0.0,
        endFreqHz: 0.0,
        decayMs: 80.0,
        gain: 0.6,
        highpassHz: 3000.0,
        lowpassHz: 12000.0,
      );

      final json = voice.toJson();
      final restored = Voice.fromJson(json);
      expect(restored, equals(voice));
      expect(restored.highpassHz, equals(3000.0));
      expect(restored.lowpassHz, equals(12000.0));
    });

    test('JSON deserialization rejects unknown waveform with descriptive error', () {
      final json = {
        'waveform': 'supersaw',
        'startFreqHz': 220,
        'endFreqHz': 220,
        'decayMs': 100,
        'gain': 0.5,
      };

      expect(
        () => Voice.fromJson(json),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'error message',
            contains('Unknown waveform "supersaw"'),
          ),
        ),
      );
    });

    test('JSON deserialization rejects non-string waveform', () {
      final json = {
        'waveform': 123,
        'decayMs': 100,
      };

      expect(
        () => Voice.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('JSON deserialization rejects missing or invalid decayMs', () {
      expect(
        () => Voice.fromJson({'waveform': 'sine'}),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Voice.fromJson({'waveform': 'sine', 'decayMs': 'invalid'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('JSON round-trip succeeds for all defaultVoices', () {
      for (final voice in defaultVoices) {
        final json = voice.toJson();
        final restored = Voice.fromJson(json);
        expect(restored, equals(voice));
      }
    });

    test('copyWith updates specified fields and handles null clearing', () {
      const voice = Voice(
        waveform: Waveform.noise,
        decayMs: 80,
        gain: 0.6,
        highpassHz: 3000,
      );

      final modified = voice.copyWith(
        waveform: Waveform.square,
        startFreqHz: 400,
        decayMs: 90,
        gain: 0.4,
        highpassHz: null,
      );

      expect(modified.waveform, equals(Waveform.square));
      expect(modified.startFreqHz, equals(400.0));
      expect(modified.decayMs, equals(90.0));
      expect(modified.gain, equals(0.4));
      expect(modified.highpassHz, isNull);

      // Unspecified fields in copyWith remain unchanged
      final copySame = voice.copyWith();
      expect(copySame, equals(voice));
      expect(copySame.highpassHz, equals(3000.0));
    });

    test('value equality and hashCode', () {
      const voice1 = Voice(
        waveform: Waveform.sine,
        startFreqHz: 150,
        endFreqHz: 45,
        decayMs: 260,
        gain: 0.8,
      );
      const voice2 = Voice(
        waveform: Waveform.sine,
        startFreqHz: 150,
        endFreqHz: 45,
        decayMs: 260,
        gain: 0.8,
      );
      const different = Voice(
        waveform: Waveform.sine,
        startFreqHz: 150,
        endFreqHz: 45,
        decayMs: 260,
        gain: 0.9,
      );

      expect(voice1, equals(voice2));
      expect(voice1.hashCode, equals(voice2.hashCode));
      expect(voice1, isNot(equals(different)));
    });

    test('toString formatting contains key properties', () {
      const voice = Voice(
        waveform: Waveform.sine,
        startFreqHz: 150,
        endFreqHz: 45,
        decayMs: 260,
        gain: 0.8,
      );
      expect(voice.toString(), contains('sine'));
      expect(voice.toString(), contains('150.0Hz->45.0Hz'));
      expect(voice.toString(), contains('260.0ms'));
      expect(voice.toString(), contains('gain: 0.8'));
    });
  });

  group('Default Voice Ladder', () {
    test('contains exactly 8 voices in order from track 0 to track 7', () {
      expect(defaultVoices.length, equals(8));
    });

    test('track 0 matches specification: sine 150Hz -> 45Hz, 260ms decay, gain 0.8', () {
      final track0 = defaultVoices[0];
      expect(track0.waveform, equals(Waveform.sine));
      expect(track0.startFreqHz, equals(150.0));
      expect(track0.endFreqHz, equals(45.0));
      expect(track0.decayMs, equals(260.0));
      expect(track0.gain, equals(0.8));
      expect(track0.highpassHz, isNull);
      expect(track0.lowpassHz, isNull);
    });

    test('track 1 matches specification: sine 120Hz -> 70Hz, 200ms decay, gain 0.8', () {
      final track1 = defaultVoices[1];
      expect(track1.waveform, equals(Waveform.sine));
      expect(track1.startFreqHz, equals(120.0));
      expect(track1.endFreqHz, equals(70.0));
      expect(track1.decayMs, equals(200.0));
      expect(track1.gain, equals(0.8));
      expect(track1.highpassHz, isNull);
      expect(track1.lowpassHz, isNull);
    });

    test('track 2 matches specification: triangle 180Hz -> 120Hz, 160ms decay, gain 0.8', () {
      final track2 = defaultVoices[2];
      expect(track2.waveform, equals(Waveform.triangle));
      expect(track2.startFreqHz, equals(180.0));
      expect(track2.endFreqHz, equals(120.0));
      expect(track2.decayMs, equals(160.0));
      expect(track2.gain, equals(0.8));
      expect(track2.highpassHz, isNull);
      expect(track2.lowpassHz, isNull);
    });

    test('track 3 matches specification: triangle 260Hz -> 200Hz, 140ms decay, gain 0.8', () {
      final track3 = defaultVoices[3];
      expect(track3.waveform, equals(Waveform.triangle));
      expect(track3.startFreqHz, equals(260.0));
      expect(track3.endFreqHz, equals(200.0));
      expect(track3.decayMs, equals(140.0));
      expect(track3.gain, equals(0.8));
      expect(track3.highpassHz, isNull);
      expect(track3.lowpassHz, isNull);
    });

    test('track 4 matches specification: square 400Hz -> 400Hz, 90ms decay, gain 0.4', () {
      final track4 = defaultVoices[4];
      expect(track4.waveform, equals(Waveform.square));
      expect(track4.startFreqHz, equals(400.0));
      expect(track4.endFreqHz, equals(400.0));
      expect(track4.decayMs, equals(90.0));
      expect(track4.gain, equals(0.4));
      expect(track4.highpassHz, isNull);
      expect(track4.lowpassHz, isNull);
    });

    test('track 5 matches specification: square 800Hz -> 800Hz, 70ms decay, gain 0.4', () {
      final track5 = defaultVoices[5];
      expect(track5.waveform, equals(Waveform.square));
      expect(track5.startFreqHz, equals(800.0));
      expect(track5.endFreqHz, equals(800.0));
      expect(track5.decayMs, equals(70.0));
      expect(track5.gain, equals(0.4));
      expect(track5.highpassHz, isNull);
      expect(track5.lowpassHz, isNull);
    });

    test('track 6 matches specification: noise, 80ms decay, gain 0.6, highpass 3000Hz', () {
      final track6 = defaultVoices[6];
      expect(track6.waveform, equals(Waveform.noise));
      expect(track6.decayMs, equals(80.0));
      expect(track6.gain, equals(0.6));
      expect(track6.highpassHz, equals(3000.0));
      expect(track6.lowpassHz, isNull);
    });

    test('track 7 matches specification: noise, 40ms decay, gain 0.6, highpass 7000Hz', () {
      final track7 = defaultVoices[7];
      expect(track7.waveform, equals(Waveform.noise));
      expect(track7.decayMs, equals(40.0));
      expect(track7.gain, equals(0.6));
      expect(track7.highpassHz, equals(7000.0));
      expect(track7.lowpassHz, isNull);
    });
  });
}
