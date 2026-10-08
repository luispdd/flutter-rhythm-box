import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/voice.dart';

void main() {
  group('MetronomeSettings Domain Model', () {
    test('default settings have expected values', () {
      final settings = MetronomeSettings();

      expect(settings.beatsPerBar, equals(4));
      expect(settings.beatsPerBar, equals(MetronomeSettings.defaultBeatsPerBar));
      expect(settings.accent, isTrue);
      expect(settings.accentOnBeat1, isTrue);
      expect(settings.waveform, equals(Waveform.sine));
      expect(settings.pitchHz, equals(1000.0));
      expect(settings.pitch, equals(1000.0));
      expect(settings.decayMs, equals(40.0));
      expect(settings.decay, equals(40.0));
      expect(settings.accentPitchHz, equals(1500.0));
      expect(settings.accentPitch, equals(1500.0));
    });

    test('accent pitch is always 1.5 times the pitch', () {
      final settings = MetronomeSettings(pitchHz: 800.0);
      expect(settings.pitchHz, equals(800.0));
      expect(settings.accentPitchHz, equals(1200.0));
      expect(settings.accentPitch, equals(1200.0));

      final highPitch = MetronomeSettings(pitchHz: 2000.0);
      expect(highPitch.accentPitchHz, equals(3000.0));
    });

    test('values clamped to valid ranges', () {
      // Pitch: 200 to 4000 Hz
      expect(MetronomeSettings(pitchHz: 50.0).pitchHz, equals(200.0));
      expect(MetronomeSettings(pitch: 50.0).pitchHz, equals(200.0));
      expect(MetronomeSettings(pitchHz: 150.0).pitchHz, equals(200.0));
      expect(MetronomeSettings(pitchHz: 5000.0).pitchHz, equals(4000.0));
      expect(MetronomeSettings(pitch: 5000.0).pitchHz, equals(4000.0));
      expect(MetronomeSettings.clampPitchHz(50), equals(200.0));
      expect(MetronomeSettings.clampPitchHz(5000), equals(4000.0));

      // Decay: 10 to 200 ms
      expect(MetronomeSettings(decayMs: 500.0).decayMs, equals(200.0));
      expect(MetronomeSettings(decay: 500.0).decayMs, equals(200.0));
      expect(MetronomeSettings(decayMs: 5.0).decayMs, equals(10.0));
      expect(MetronomeSettings(decay: 5.0).decayMs, equals(10.0));
      expect(MetronomeSettings.clampDecayMs(5), equals(10.0));
      expect(MetronomeSettings.clampDecayMs(500), equals(200.0));

      // Beats per bar: 2 to 9
      expect(MetronomeSettings(beatsPerBar: 12).beatsPerBar, equals(9));
      expect(MetronomeSettings(beatsPerBar: 1).beatsPerBar, equals(2));
      expect(MetronomeSettings(beatsPerBar: 0).beatsPerBar, equals(2));
      expect(MetronomeSettings(beatsPerBar: -3).beatsPerBar, equals(2));
      expect(MetronomeSettings.clampBeatsPerBar(1), equals(2));
      expect(MetronomeSettings.clampBeatsPerBar(12), equals(9));
    });

    test('supported click waveforms are accepted', () {
      expect(
        MetronomeSettings(waveform: Waveform.sine).waveform,
        equals(Waveform.sine),
      );
      expect(
        MetronomeSettings(waveform: Waveform.triangle).waveform,
        equals(Waveform.triangle),
      );
      expect(
        MetronomeSettings(waveform: Waveform.square).waveform,
        equals(Waveform.square),
      );
    });

    test('noise waveform is rejected with ArgumentError', () {
      expect(
        () => MetronomeSettings(waveform: Waveform.noise),
        throwsArgumentError,
      );
    });

    test('copyWith produces updated and clamped instances', () {
      final base = MetronomeSettings();
      final updated = base.copyWith(
        beatsPerBar: 3,
        accent: false,
        waveform: Waveform.triangle,
        pitchHz: 1200.0,
        decayMs: 60.0,
      );

      expect(updated.beatsPerBar, equals(3));
      expect(updated.accent, isFalse);
      expect(updated.waveform, equals(Waveform.triangle));
      expect(updated.pitchHz, equals(1200.0));
      expect(updated.decayMs, equals(60.0));
      expect(updated.accentPitchHz, equals(1800.0));

      // copyWith clamping
      expect(base.copyWith(beatsPerBar: 20).beatsPerBar, equals(9));
      expect(base.copyWith(pitchHz: 10).pitchHz, equals(200.0));
      expect(base.copyWith(decayMs: 999).decayMs, equals(200.0));

      // copyWith noise rejection
      expect(
        () => base.copyWith(waveform: Waveform.noise),
        throwsArgumentError,
      );
    });

    test('JSON serialization round trip preserves all values', () {
      final original = MetronomeSettings(
        beatsPerBar: 7,
        accent: false,
        waveform: Waveform.square,
        pitchHz: 1600.0,
        decayMs: 80.0,
      );

      final json = original.toJson();
      expect(json, equals({
        'schemaVersion': 1,
        'beatsPerBar': 7,
        'accent': false,
        'waveform': 'square',
        'pitchHz': 1600.0,
        'decayMs': 80.0,
      }));

      final restored = MetronomeSettings.fromJson(json);
      expect(restored, equals(original));
      expect(restored.beatsPerBar, equals(7));
      expect(restored.accent, isFalse);
      expect(restored.waveform, equals(Waveform.square));
      expect(restored.pitchHz, equals(1600.0));
      expect(restored.decayMs, equals(80.0));
      expect(restored.accentPitchHz, equals(2400.0));
    });

    test('partial JSON with only pitch present deserializes with defaults for others', () {
      final fromPitchHz = MetronomeSettings.fromJson({'pitchHz': 800.0});
      expect(fromPitchHz.pitchHz, equals(800.0));
      expect(fromPitchHz.beatsPerBar, equals(4));
      expect(fromPitchHz.accent, isTrue);
      expect(fromPitchHz.waveform, equals(Waveform.sine));
      expect(fromPitchHz.decayMs, equals(40.0));
      expect(fromPitchHz.accentPitchHz, equals(1200.0));

      final fromPitch = MetronomeSettings.fromJson({'pitch': 800.0});
      expect(fromPitch.pitchHz, equals(800.0));
      expect(fromPitch.beatsPerBar, equals(4));
      expect(fromPitch.accent, isTrue);
      expect(fromPitch.waveform, equals(Waveform.sine));
      expect(fromPitch.decayMs, equals(40.0));
      expect(fromPitch.accentPitchHz, equals(1200.0));
    });

    test('empty JSON uses defaults for all fields', () {
      final settings = MetronomeSettings.fromJson({});
      expect(settings, equals(MetronomeSettings()));
      expect(settings.beatsPerBar, equals(4));
      expect(settings.accent, isTrue);
      expect(settings.waveform, equals(Waveform.sine));
      expect(settings.pitchHz, equals(1000.0));
      expect(settings.decayMs, equals(40.0));
      expect(settings.accentPitchHz, equals(1500.0));
    });

    test('JSON deserialization clamps out-of-range values', () {
      final clamped = MetronomeSettings.fromJson({
        'beatsPerBar': 20,
        'pitchHz': 20.0,
        'decayMs': 1000.0,
      });

      expect(clamped.beatsPerBar, equals(9));
      expect(clamped.pitchHz, equals(200.0));
      expect(clamped.decayMs, equals(200.0));
    });

    test('JSON deserialization rejects noise waveform', () {
      expect(
        () => MetronomeSettings.fromJson({'waveform': 'noise'}),
        throwsArgumentError,
      );
    });

    test('value equality and hashCode', () {
      final a = MetronomeSettings(
        beatsPerBar: 3,
        accent: true,
        waveform: Waveform.triangle,
        pitchHz: 1200.0,
        decayMs: 50.0,
      );
      final b = MetronomeSettings(
        beatsPerBar: 3,
        accent: true,
        waveform: Waveform.triangle,
        pitchHz: 1200.0,
        decayMs: 50.0,
      );
      final diffBeats = a.copyWith(beatsPerBar: 4);
      final diffAccent = a.copyWith(accent: false);
      final diffWaveform = a.copyWith(waveform: Waveform.sine);
      final diffPitch = a.copyWith(pitchHz: 1300.0);
      final diffDecay = a.copyWith(decayMs: 60.0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      expect(a, isNot(equals(diffBeats)));
      expect(a, isNot(equals(diffAccent)));
      expect(a, isNot(equals(diffWaveform)));
      expect(a, isNot(equals(diffPitch)));
      expect(a, isNot(equals(diffDecay)));
    });

    test('toString contains formatted summary', () {
      final settings = MetronomeSettings();
      expect(
        settings.toString(),
        equals('MetronomeSettings(schemaVersion: 1, beatsPerBar: 4, accent: true, waveform: sine, pitch: 1000.0Hz, decay: 40.0ms)'),
      );
    });

    test('missing schemaVersion defaults to 1 when deserializing from JSON', () {
      final json = MetronomeSettings().toJson();
      json.remove('schemaVersion');
      final restored = MetronomeSettings.fromJson(json);
      expect(restored.schemaVersion, equals(1));
    });
  });
}
