import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/tempo.dart';

void main() {
  group('Tempo Domain Model', () {
    test('default tempo is 120 BPM', () {
      const defaultTempo = Tempo();
      expect(defaultTempo.bpm, equals(120));
      expect(defaultTempo.value, equals(120));
      expect(Tempo().bpm, equals(120));
    });

    test('values within range [30, 300] are preserved', () {
      expect(const Tempo(30).bpm, equals(30));
      expect(const Tempo(120).bpm, equals(120));
      expect(const Tempo(180).bpm, equals(180));
      expect(const Tempo(300).bpm, equals(300));
    });

    test('out-of-range values below 30 are clamped to 30', () {
      expect(const Tempo(29).bpm, equals(30));
      expect(const Tempo(0).bpm, equals(30));
      expect(const Tempo(-50).bpm, equals(30));
      expect(Tempo.clampBpm(10), equals(30));
    });

    test('out-of-range values above 300 are clamped to 300', () {
      expect(const Tempo(301).bpm, equals(300));
      expect(const Tempo(500).bpm, equals(300));
      expect(Tempo.clampBpm(400), equals(300));
    });

    test('increment increases BPM and clamps at 300', () {
      expect(const Tempo(120).increment().bpm, equals(121));
      expect(const Tempo(120).increment(5).bpm, equals(125));
      expect(const Tempo(300).increment().bpm, equals(300));
      expect(const Tempo(298).increment(10).bpm, equals(300));
    });

    test('decrement decreases BPM and clamps at 30', () {
      expect(const Tempo(120).decrement().bpm, equals(119));
      expect(const Tempo(120).decrement(10).bpm, equals(110));
      expect(const Tempo(30).decrement().bpm, equals(30));
      expect(const Tempo(35).decrement(10).bpm, equals(30));
    });

    test('copyWith produces updated clamped instances', () {
      const tempo = Tempo(120);
      expect(tempo.copyWith(bpm: 140).bpm, equals(140));
      expect(tempo.copyWith(bpm: 10).bpm, equals(30));
      expect(tempo.copyWith(bpm: 500).bpm, equals(300));
      expect(tempo.copyWith().bpm, equals(120));
    });

    test('value equality and hashCode', () {
      expect(const Tempo(120), equals(const Tempo(120)));
      expect(const Tempo(120), equals(Tempo(120)));
      expect(const Tempo(120), isNot(equals(const Tempo(140))));
      expect(const Tempo(120).hashCode, equals(const Tempo(120).hashCode));
    });

    test('JSON serialization round trip and fallbacks', () {
      const tempo = Tempo(145);
      final json = tempo.toJson();
      expect(json, equals({'bpm': 145}));

      final restored = Tempo.fromJson(json);
      expect(restored, equals(tempo));

      // Supports tempoBpm key
      expect(Tempo.fromJson({'tempoBpm': 90}).bpm, equals(90));

      // Clamps on deserialization
      expect(Tempo.fromJson({'bpm': 10}).bpm, equals(30));
      expect(Tempo.fromJson({'bpm': 500}).bpm, equals(300));

      // Fallback on missing/empty
      expect(Tempo.fromJson({}).bpm, equals(120));
    });

    test('toString formatting', () {
      expect(const Tempo(120).toString(), equals('Tempo(120 BPM)'));
    });
  });
}
