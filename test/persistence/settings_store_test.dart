import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/persistence/shared_preferences_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesSettingsStore', () {
    late SharedPreferences prefs;
    late SharedPreferencesSettingsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = SharedPreferencesSettingsStore(prefs);
    });

    group('MetronomeSettings', () {
      test('loadMetronomeSettings returns null when empty', () async {
        final result = await store.loadMetronomeSettings();
        expect(result, isNull);
      });

      test('round-trips custom MetronomeSettings correctly', () async {
        final original = MetronomeSettings(
          beatsPerBar: 3,
          accent: false,
          waveform: Waveform.triangle,
          pitchHz: 1200.0,
          decayMs: 65.0,
        );

        await store.saveMetronomeSettings(original);
        final loaded = await store.loadMetronomeSettings();

        expect(loaded, isNotNull);
        expect(loaded, equals(original));
        expect(loaded!.beatsPerBar, equals(3));
        expect(loaded.accent, isFalse);
        expect(loaded.waveform, equals(Waveform.triangle));
        expect(loaded.pitchHz, equals(1200.0));
        expect(loaded.decayMs, equals(65.0));

        // Verify stored value in SharedPreferences is valid JSON string
        final raw = prefs.getString(SharedPreferencesSettingsStore.metronomeSettingsKey);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as Map<String, dynamic>;
        expect(decoded['beatsPerBar'], equals(3));
        expect(decoded['waveform'], equals('triangle'));
      });

      test('returns null gracefully when stored JSON is invalid or corrupted', () async {
        await prefs.setString(
          SharedPreferencesSettingsStore.metronomeSettingsKey,
          'not valid json {[[',
        );

        final result = await store.loadMetronomeSettings();
        expect(result, isNull);
      });
    });

    group('Tempo', () {
      test('loadTempo returns null when empty', () async {
        final result = await store.loadTempo();
        expect(result, isNull);
        final bpmResult = await store.loadTempoBpm();
        expect(bpmResult, isNull);
      });

      test('round-trips custom Tempo correctly', () async {
        const original = Tempo(144);
        await store.saveTempo(original);

        final loaded = await store.loadTempo();
        expect(loaded, isNotNull);
        expect(loaded, equals(original));
        expect(loaded!.bpm, equals(144));

        final loadedBpm = await store.loadTempoBpm();
        expect(loadedBpm, equals(144));

        // Verify stored value in SharedPreferences is a JSON string
        final raw = prefs.getString(SharedPreferencesSettingsStore.tempoKey);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as Map<String, dynamic>;
        expect(decoded['bpm'], equals(144));
      });

      test('saveTempoBpm saves and round-trips correctly', () async {
        await store.saveTempoBpm(160);
        final loaded = await store.loadTempo();
        expect(loaded, equals(const Tempo(160)));
      });

      test('returns null gracefully when stored JSON is invalid or corrupted', () async {
        await prefs.setString(
          SharedPreferencesSettingsStore.tempoKey,
          'corrupted tempo string {',
        );

        final result = await store.loadTempo();
        expect(result, isNull);
      });
    });

    group('clear', () {
      test('removes all saved settings from storage', () async {
        final settings = MetronomeSettings(beatsPerBar: 5);
        await store.saveMetronomeSettings(settings);
        await store.saveTempo(const Tempo(90));

        expect(await store.loadMetronomeSettings(), isNotNull);
        expect(await store.loadTempo(), isNotNull);

        await store.clear();

        expect(await store.loadMetronomeSettings(), isNull);
        expect(await store.loadTempo(), isNull);
      });
    });

    group('Riverpod settingsStoreProvider', () {
      test('throws error when not overridden', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(settingsStoreProvider),
          throwsA(
            predicate(
              (e) => e.toString().contains('UnimplementedError'),
            ),
          ),
        );
      });

      test('can be overridden with an active store instance', () {
        final container = ProviderContainer(
          overrides: [
            settingsStoreProvider.overrideWithValue(store),
          ],
        );
        addTearDown(container.dispose);

        final resolvedStore = container.read(settingsStoreProvider);
        expect(resolvedStore, same(store));
      });
    });
  });
}
