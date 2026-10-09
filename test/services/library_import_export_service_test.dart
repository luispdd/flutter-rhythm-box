import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';
import 'package:rhythm_box/domain/library_data.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/services/file_picker_service.dart';
import 'package:rhythm_box/services/library_import_export_service.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequence_controller.dart';
import 'package:rhythm_box/ui/sequence_library_notifier.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';

import '../audio/fake_audio_engine.dart';
import '../audio/fake_background_audio_service.dart';
import '../persistence/fake_settings_store.dart';
import 'fake_file_picker_service.dart';

void main() {
  group('LibraryImportExportService', () {
    late ProviderContainer container;
    late FakeSettingsStore store;
    late FakeFilePickerService filePicker;
    late FakeAudioEngine engine;
    late FakeBackgroundAudioService backgroundService;
    late LibraryImportExportService service;

    setUp(() {
      store = FakeSettingsStore();
      filePicker = FakeFilePickerService();
      engine = FakeAudioEngine();
      backgroundService = FakeBackgroundAudioService();

      container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          filePickerServiceProvider.overrideWithValue(filePicker),
          audioEngineProvider.overrideWithValue(engine),
          backgroundAudioServiceProvider.overrideWithValue(backgroundService),
        ],
      );

      service = container.read(libraryImportExportServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('exportLibrary', () {
      test('returns empty result when library has no patterns and no sequences', () async {
        store.savedPatternLibrary = [];
        store.savedSequenceLibrary = [];

        final result = await service.exportLibrary();

        expect(result.isEmpty, isTrue);
        expect(result.isSuccess, isFalse);
        expect(filePicker.saveFileCalls, equals(0));
      });

      test('saves serialized library and returns success when items exist', () async {
        final pattern = Pattern(id: 'p1', name: 'Pattern 1', tempoBpm: 120);
        final sequence = Sequence(id: 's1', name: 'Sequence 1');
        store.savedPatternLibrary = [pattern];
        store.savedSequenceLibrary = [sequence];
        filePicker.saveResult = '/path/to/exported.json';

        final result = await service.exportLibrary();

        expect(result.isSuccess, isTrue);
        expect(result.patternCount, equals(1));
        expect(result.sequenceCount, equals(1));
        expect(result.filePath, equals('/path/to/exported.json'));
        expect(filePicker.saveFileCalls, equals(1));
        expect(filePicker.lastSavedFileName, startsWith('rhythm-box-library-'));
        expect(filePicker.lastSavedFileName, endsWith('.json'));

        final savedJsonStr = utf8.decode(filePicker.lastSavedBytes!);
        final decoded = jsonDecode(savedJsonStr);
        expect(decoded['format'], equals('rhythm-box-library'));
        expect(decoded['formatVersion'], equals(1));
        expect(decoded['patterns'], hasLength(1));
        expect(decoded['sequences'], hasLength(1));
      });

      test('returns canceled result when user cancels file picker', () async {
        store.savedPatternLibrary = [Pattern(id: 'p1', name: 'P1')];
        filePicker.saveResult = null; // Canceled

        final result = await service.exportLibrary();

        expect(result.isCanceled, isTrue);
        expect(result.isSuccess, isFalse);
      });
    });

    group('pickAndValidateImportFile', () {
      test('returns canceled when user cancels file selection', () async {
        filePicker.pickResult = null;

        final result = await service.pickAndValidateImportFile();

        expect(result.isCanceled, isTrue);
        expect(result.isReady, isFalse);
      });

      test('returns invalid when file fails validation', () async {
        filePicker.pickResult = PickedFileData(
          name: 'bad.json',
          bytes: Uint8List.fromList(utf8.encode('{not json')),
        );

        final result = await service.pickAndValidateImportFile();

        expect(result.isReady, isFalse);
        expect(result.errorMessage, contains('File is not valid JSON'));
      });

      test('returns ready with parsed data when file is valid', () async {
        final validLibrary = LibraryData(
          patterns: [Pattern(id: 'p1', name: 'P1')],
          sequences: [
            Sequence(
              id: 's1',
              name: 'S1',
              entries: [SequenceEntry(patternId: 'p1', repeats: 1)],
            ),
          ],
        );
        final jsonBytes = Uint8List.fromList(utf8.encode(validLibrary.toJsonString()));
        filePicker.pickResult = PickedFileData(
          name: 'valid.json',
          bytes: jsonBytes,
        );

        final result = await service.pickAndValidateImportFile();

        expect(result.isReady, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.patterns.length, equals(1));
        expect(result.data!.sequences.length, equals(1));
      });
    });

    group('executeImport', () {
      test('stops playback, replaces library, updates providers, and resets working states', () async {
        // Setup initial store data
        store.savedPatternLibrary = [Pattern(id: 'old_p', name: 'Old Pattern')];
        store.savedSequenceLibrary = [Sequence(id: 'old_s', name: 'Old Sequence')];

        // Seed sequencer and sequence controllers
        await container.read(patternLibraryProvider.notifier).loadFromStore();
        await container.read(sequenceLibraryProvider.notifier).loadFromStore();
        await container.read(sequencerControllerProvider.notifier).loadPattern(
          Pattern(id: 'working_p', name: 'Working Pattern', tempoBpm: 150),
        );
        container.read(sequenceControllerProvider.notifier).setSequence(
          Sequence(id: 'active_s', name: 'Active Sequence'),
        );

        final newPattern = Pattern(id: 'new_p', name: 'New Pattern', tempoBpm: 120);
        final newSequence = Sequence(
          id: 'new_s',
          name: 'New Sequence',
          entries: [SequenceEntry(patternId: 'new_p', repeats: 2)],
        );
        final importData = LibraryData(
          patterns: [newPattern],
          sequences: [newSequence],
        );

        final result = await service.executeImport(importData);

        expect(result.isSuccess, isTrue);
        expect(result.patternCount, equals(1));
        expect(result.sequenceCount, equals(1));

        // Verify store was replaced
        expect(store.replaceAllCalls, equals(1));
        expect(store.savedPatternLibrary.length, equals(1));
        expect(store.savedPatternLibrary.first.id, equals('new_p'));
        expect(store.savedSequenceLibrary.length, equals(1));
        expect(store.savedSequenceLibrary.first.id, equals('new_s'));

        // Verify library providers refreshed
        final patternList = container.read(patternLibraryProvider);
        expect(patternList.length, equals(1));
        expect(patternList.first.id, equals('new_p'));

        final sequenceList = container.read(sequenceLibraryProvider);
        expect(sequenceList.length, equals(1));
        expect(sequenceList.first.id, equals('new_s'));

        // Verify sequencer and sequence controllers were reset to empty defaults
        final sequencerState = container.read(sequencerControllerProvider);
        expect(sequencerState.pattern, equals(Pattern.empty()));

        final sequenceState = container.read(sequenceControllerProvider);
        expect(sequenceState.sequence.id, isEmpty);
        expect(sequenceState.sequence.entries, isEmpty);
      });
    });
  });
}
