import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library_data.dart';
import '../domain/library_validator.dart';
import '../domain/pattern.dart';
import '../domain/sequence.dart';
import '../persistence/settings_store.dart';
import '../ui/metronome_controller.dart';
import '../ui/pattern_library_notifier.dart';
import '../ui/sequence_controller.dart';
import '../ui/sequence_library_notifier.dart';
import '../ui/sequencer_controller.dart';
import 'file_picker_service.dart';

/// Result of an export library operation.
@immutable
class ExportResult {
  final bool isSuccess;
  final bool isEmpty;
  final bool isCanceled;
  final String? errorMessage;
  final int patternCount;
  final int sequenceCount;
  final String? filePath;

  const ExportResult.success({
    required this.patternCount,
    required this.sequenceCount,
    this.filePath,
  })  : isSuccess = true,
        isEmpty = false,
        isCanceled = false,
        errorMessage = null;

  const ExportResult.empty()
      : isSuccess = false,
        isEmpty = true,
        isCanceled = false,
        errorMessage = null,
        patternCount = 0,
        sequenceCount = 0,
        filePath = null;

  const ExportResult.canceled()
      : isSuccess = false,
        isEmpty = false,
        isCanceled = true,
        errorMessage = null,
        patternCount = 0,
        sequenceCount = 0,
        filePath = null;

  const ExportResult.error(this.errorMessage)
      : isSuccess = false,
        isEmpty = false,
        isCanceled = false,
        patternCount = 0,
        sequenceCount = 0,
        filePath = null;
}

/// Result of picking and validating an import file before user confirmation.
@immutable
class PrepareImportResult {
  final bool isReady;
  final bool isCanceled;
  final String? errorMessage;
  final LibraryData? data;

  const PrepareImportResult.ready(this.data)
      : isReady = true,
        isCanceled = false,
        errorMessage = null;

  const PrepareImportResult.canceled()
      : isReady = false,
        isCanceled = true,
        errorMessage = null,
        data = null;

  const PrepareImportResult.invalid(this.errorMessage)
      : isReady = false,
        isCanceled = false,
        data = null;
}

/// Result of executing an atomic library replacement.
@immutable
class ImportExecutionResult {
  final bool isSuccess;
  final String? errorMessage;
  final int patternCount;
  final int sequenceCount;

  const ImportExecutionResult.success({
    required this.patternCount,
    required this.sequenceCount,
  })  : isSuccess = true,
        errorMessage = null;

  const ImportExecutionResult.error(this.errorMessage)
      : isSuccess = false,
        patternCount = 0,
        sequenceCount = 0;
}

/// Service that coordinates library export and import operations.
class LibraryImportExportService {
  final Ref _ref;

  LibraryImportExportService(this._ref);

  FilePickerService get _filePicker => _ref.read(filePickerServiceProvider);
  SettingsStore get _store => _ref.read(settingsStoreProvider);

  /// Generates the suggested default file name: `rhythm-box-library-YYYY-MM-DD.json`.
  static String formatDefaultFileName([DateTime? now]) {
    final d = now ?? DateTime.now();
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'rhythm-box-library-$year-$month-$day.json';
  }

  /// Exports all saved patterns and sequences to a JSON file.
  Future<ExportResult> exportLibrary() async {
    try {
      final patterns = await _store.loadPatternLibrary();
      final sequences = await _store.loadSequenceLibrary();

      if (patterns.isEmpty && sequences.isEmpty) {
        return const ExportResult.empty();
      }

      final libraryData = LibraryData(
        patterns: patterns,
        sequences: sequences,
      );

      final jsonString = libraryData.toJsonString(pretty: true);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final defaultFileName = formatDefaultFileName();

      final savedPath = await _filePicker.saveFile(
        suggestedFileName: defaultFileName,
        bytes: bytes,
        dialogTitle: 'Export Library',
      );

      if (savedPath == null) {
        return const ExportResult.canceled();
      }

      return ExportResult.success(
        patternCount: patterns.length,
        sequenceCount: sequences.length,
        filePath: savedPath,
      );
    } catch (e) {
      return ExportResult.error('Export failed: $e');
    }
  }

  /// Prompts the user to pick a library JSON file and validates its contents.
  Future<PrepareImportResult> pickAndValidateImportFile() async {
    try {
      final picked = await _filePicker.pickJsonFile(
        dialogTitle: 'Select Library File to Import',
      );

      if (picked == null) {
        return const PrepareImportResult.canceled();
      }

      final jsonString = utf8.decode(picked.bytes, allowMalformed: true);
      final validationResult = LibraryValidator.validateJsonString(
        jsonString,
        byteLength: picked.bytes.length,
      );

      if (!validationResult.isValid) {
        return PrepareImportResult.invalid(
          validationResult.errorMessage ?? 'Invalid library file.',
        );
      }

      return PrepareImportResult.ready(validationResult.data);
    } catch (e) {
      return PrepareImportResult.invalid('Error reading library file: $e');
    }
  }

  /// Atomically replaces the current library with [data].
  ///
  /// Stops playback across all controllers, writes [data] to storage,
  /// refreshes library notifiers, and resets Sequencer and Sequences controllers.
  Future<ImportExecutionResult> executeImport(LibraryData data) async {
    try {
      // 1. Cease all active audio playback
      await _ref.read(metronomeControllerProvider.notifier).stop();
      await _ref.read(sequencerControllerProvider.notifier).stop();
      await _ref.read(sequenceControllerProvider.notifier).stop();

      // 2. Atomically replace stored patterns and sequences
      await _store.replaceAll(data.patterns, data.sequences);

      // 3. Refresh library notifiers from storage
      await _ref.read(patternLibraryProvider.notifier).loadFromStore();
      await _ref.read(sequenceLibraryProvider.notifier).loadFromStore();

      // 4. Reset working states so entering other tabs starts clean
      await _ref.read(sequencerControllerProvider.notifier).loadPattern(Pattern.empty());
      _ref.read(sequenceControllerProvider.notifier).setSequence(Sequence.empty());

      return ImportExecutionResult.success(
        patternCount: data.patterns.length,
        sequenceCount: data.sequences.length,
      );
    } catch (e) {
      return ImportExecutionResult.error('Import failed: $e');
    }
  }
}

/// Global provider for [LibraryImportExportService].
final libraryImportExportServiceProvider =
    Provider<LibraryImportExportService>((ref) {
  return LibraryImportExportService(ref);
});
