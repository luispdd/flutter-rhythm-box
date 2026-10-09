import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
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

    group('Working Pattern', () {
      test('loadWorkingPattern returns null when empty', () async {
        final result = await store.loadWorkingPattern();
        expect(result, isNull);
      });

      test('round-trips custom Pattern correctly', () async {
        var pattern = Pattern.empty();
        pattern = pattern.toggle(0, 0); // track 0, step 0
        pattern = pattern.setStepCount(8);

        await store.saveWorkingPattern(pattern);
        final loaded = await store.loadWorkingPattern();

        expect(loaded, isNotNull);
        expect(loaded, equals(pattern));
        expect(loaded!.stepCount, equals(8));
        expect(loaded.isStepOn(0, 0), isTrue);

        // Verify stored value in SharedPreferences is valid JSON string
        final raw = prefs.getString(SharedPreferencesSettingsStore.workingPatternKey);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as Map<String, dynamic>;
        expect(decoded['stepCount'], equals(8));
      });

      test('returns null gracefully when stored JSON is invalid or corrupted', () async {
        await prefs.setString(
          SharedPreferencesSettingsStore.workingPatternKey,
          'not valid json {[[',
        );

        final result = await store.loadWorkingPattern();
        expect(result, isNull);
      });
    });

    group('Pattern Library', () {
      test('loadPatternLibrary returns empty list when empty', () async {
        final result = await store.loadPatternLibrary();
        expect(result, isEmpty);
      });

      test('round-trips custom Pattern Library correctly', () async {
        var pattern1 = Pattern.empty(id: '1', name: 'Beat 1');
        pattern1 = pattern1.toggle(0, 0); // track 0, step 0
        pattern1 = pattern1.setStepCount(8);

        var pattern2 = Pattern.empty(id: '2', name: 'Beat 2');
        pattern2 = pattern2.toggle(1, 4);

        final library = [pattern1, pattern2];

        await store.savePatternLibrary(library);
        final loaded = await store.loadPatternLibrary();

        expect(loaded, isNotEmpty);
        expect(loaded.length, equals(2));
        expect(loaded[0], equals(pattern1));
        expect(loaded[1], equals(pattern2));

        // Verify stored value in SharedPreferences is valid JSON string
        final raw = prefs.getString('pattern_library');
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as List<dynamic>;
        expect(decoded.length, equals(2));
        expect(decoded[0]['name'], equals('Beat 1'));
      });

      test('returns empty list gracefully when stored JSON is invalid or corrupted', () async {
        await prefs.setString(
          'pattern_library',
          'not valid json {[[',
        );

        final result = await store.loadPatternLibrary();
        expect(result, isEmpty);
      });

      test('skips corrupted pattern items while preserving valid patterns', () async {
        final validPattern = Pattern.empty(id: 'valid', name: 'Valid Beat');
        final mixedJson = jsonEncode([
          validPattern.toJson(),
          {'invalid': 'data'},
        ]);
        await prefs.setString('pattern_library', mixedJson);

        final result = await store.loadPatternLibrary();
        expect(result.length, equals(1));
        expect(result[0].id, equals('valid'));
      });
    });

    group('Sequence Library', () {
      test('loadSequenceLibrary returns empty list when empty', () async {
        final result = await store.loadSequenceLibrary();
        expect(result, isEmpty);
      });

      test('round-trips custom Sequence Library correctly', () async {
        final seq1 = Sequence(
          id: 'seq-1',
          name: 'Verse-Chorus Sequence',
          loop: true,
          entries: [
            SequenceEntry(patternId: 'pat-1', repeats: 2),
            SequenceEntry(patternId: 'pat-2', repeats: 4),
          ],
        );

        final seq2 = Sequence(
          id: 'seq-2',
          name: 'Solo Section',
          loop: false,
          entries: [
            SequenceEntry(patternId: 'pat-3', repeats: 1),
          ],
        );

        final library = [seq1, seq2];

        await store.saveSequenceLibrary(library);
        final loaded = await store.loadSequenceLibrary();

        expect(loaded, isNotEmpty);
        expect(loaded.length, equals(2));
        expect(loaded[0], equals(seq1));
        expect(loaded[1], equals(seq2));

        final raw = prefs.getString(SharedPreferencesSettingsStore.sequenceLibraryKey);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as List<dynamic>;
        expect(decoded.length, equals(2));
        expect(decoded[0]['name'], equals('Verse-Chorus Sequence'));
      });

      test('returns empty list gracefully when stored JSON is invalid or corrupted', () async {
        await prefs.setString(
          SharedPreferencesSettingsStore.sequenceLibraryKey,
          'not valid json {[[',
        );

        final result = await store.loadSequenceLibrary();
        expect(result, isEmpty);
      });

      test('skips corrupted sequence items while preserving valid sequences', () async {
        final validSeq = Sequence(id: 'valid-seq', name: 'Valid Seq');
        final mixedJson = jsonEncode([
          validSeq.toJson(),
          {'corrupted': true},
        ]);
        await prefs.setString(
          SharedPreferencesSettingsStore.sequenceLibraryKey,
          mixedJson,
        );

        final result = await store.loadSequenceLibrary();
        expect(result.length, equals(1));
        expect(result[0].id, equals('valid-seq'));
      });
    });

    group('clear', () {
      test('removes all saved settings from storage', () async {
        final settings = MetronomeSettings(beatsPerBar: 5);
        await store.saveMetronomeSettings(settings);
        await store.saveTempo(const Tempo(90));
        await store.saveWorkingPattern(Pattern.empty());
        await store.savePatternLibrary([Pattern.empty()]);
        await store.saveSequenceLibrary([Sequence.empty()]);

        expect(await store.loadMetronomeSettings(), isNotNull);
        expect(await store.loadTempo(), isNotNull);
        expect(await store.loadWorkingPattern(), isNotNull);
        expect(await store.loadPatternLibrary(), isNotEmpty);
        expect(await store.loadSequenceLibrary(), isNotEmpty);

        await store.clear();

        expect(await store.loadMetronomeSettings(), isNull);
        expect(await store.loadTempo(), isNull);
        expect(await store.loadWorkingPattern(), isNull);
        expect(await store.loadPatternLibrary(), isEmpty);
        expect(await store.loadSequenceLibrary(), isEmpty);
      });
    });

    group('Selected Tab Index', () {
      test('loadSelectedTabIndex returns null when empty', () async {
        final result = await store.loadSelectedTabIndex();
        expect(result, isNull);
      });

      test('round-trips selected tab index correctly', () async {
        await store.saveSelectedTabIndex(2);
        final loaded = await store.loadSelectedTabIndex();
        expect(loaded, equals(2));
      });
    });

    group('replaceAll', () {
      test('overwrites existing patterns and sequences', () async {
        final initialPattern = Pattern(id: 'old_p', name: 'Old Pattern');
        final initialSequence = Sequence(id: 'old_s', name: 'Old Sequence');
        await store.savePatternLibrary([initialPattern]);
        await store.saveSequenceLibrary([initialSequence]);

        final newPattern = Pattern(id: 'new_p', name: 'New Pattern', tempoBpm: 140);
        final newSequence = Sequence(
          id: 'new_s',
          name: 'New Sequence',
          entries: [SequenceEntry(patternId: 'new_p', repeats: 2)],
        );

        await store.replaceAll([newPattern], [newSequence]);

        final loadedPatterns = await store.loadPatternLibrary();
        final loadedSequences = await store.loadSequenceLibrary();

        expect(loadedPatterns.length, equals(1));
        expect(loadedPatterns.first.id, equals('new_p'));
        expect(loadedPatterns.first.name, equals('New Pattern'));
        expect(loadedPatterns.first.tempoBpm, equals(140));

        expect(loadedSequences.length, equals(1));
        expect(loadedSequences.first.id, equals('new_s'));
        expect(loadedSequences.first.name, equals('New Sequence'));
        expect(loadedSequences.first.entries.first.patternId, equals('new_p'));
        expect(loadedSequences.first.entries.first.repeats, equals(2));
      });

      test('clears library when replacing with empty lists', () async {
        await store.savePatternLibrary([Pattern(id: 'p1', name: 'P1')]);
        await store.saveSequenceLibrary([Sequence(id: 's1', name: 'S1')]);

        await store.replaceAll([], []);

        final loadedPatterns = await store.loadPatternLibrary();
        final loadedSequences = await store.loadSequenceLibrary();

        expect(loadedPatterns, isEmpty);
        expect(loadedSequences, isEmpty);
      });
    });

    group('lastError', () {
      test('starts as null', () {
        expect(store.lastError, isNull);
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
