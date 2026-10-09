import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'library_data.dart';
import 'pattern.dart';
import 'sequence.dart';

/// Represents the result of validating a Rhythm Box library file.
@immutable
class LibraryValidationResult {
  /// Whether the library file is valid and safe to import.
  final bool isValid;

  /// Human-readable error message explaining why validation failed, or `null` if valid.
  final String? errorMessage;

  /// The parsed [LibraryData] if validation succeeded, or `null` if failed.
  final LibraryData? data;

  const LibraryValidationResult.success(this.data)
      : isValid = true,
        errorMessage = null;

  const LibraryValidationResult.failure(this.errorMessage)
      : isValid = false,
        data = null;
}

/// Service that validates imported library files against envelope schemas,
/// data constraints, uniqueness rules, and sequence referential integrity.
class LibraryValidator {
  /// Maximum permitted library file size in bytes (10 MB).
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Validates a library JSON string.
  ///
  /// Optionally accepts [byteLength] to reject oversized files before parsing.
  static LibraryValidationResult validateJsonString(
    String jsonString, {
    int? byteLength,
  }) {
    if (byteLength != null && byteLength > maxFileSize) {
      return const LibraryValidationResult.failure(
        'File size exceeds the maximum limit of 10 MB.',
      );
    }
    if (jsonString.length > maxFileSize) {
      return const LibraryValidationResult.failure(
        'File size exceeds the maximum limit of 10 MB.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      return LibraryValidationResult.failure('File is not valid JSON: $e');
    }

    if (decoded is! Map) {
      return const LibraryValidationResult.failure(
        'Invalid file structure: Root must be a JSON object.',
      );
    }

    final map = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded);

    return validateMap(map);
  }

  /// Validates a parsed library JSON map.
  static LibraryValidationResult validateMap(Map<String, dynamic> map) {
    // 1. Envelope format
    final formatRaw = map['format'];
    if (formatRaw is! String || formatRaw != LibraryData.expectedFormat) {
      return LibraryValidationResult.failure(
        'Invalid format: Expected "${LibraryData.expectedFormat}", found "$formatRaw".',
      );
    }

    // 2. Format version
    final versionRaw = map['formatVersion'];
    if (versionRaw is! num) {
      return const LibraryValidationResult.failure(
        'Missing or invalid "formatVersion" in envelope.',
      );
    }
    final formatVersion = versionRaw.toInt();
    if (formatVersion > LibraryData.currentFormatVersion) {
      return LibraryValidationResult.failure(
        'The file comes from a newer version of the app (formatVersion $formatVersion).',
      );
    }
    if (formatVersion < 1) {
      return const LibraryValidationResult.failure(
        'Invalid "formatVersion": must be at least 1.',
      );
    }

    // 3. Patterns and sequences lists
    final patternsRaw = map['patterns'];
    if (patternsRaw is! List) {
      return const LibraryValidationResult.failure(
        'Missing or invalid "patterns" list in library file.',
      );
    }

    final sequencesRaw = map['sequences'];
    if (sequencesRaw is! List) {
      return const LibraryValidationResult.failure(
        'Missing or invalid "sequences" list in library file.',
      );
    }

    // 4. Validate patterns & check duplicate pattern IDs
    final patterns = <Pattern>[];
    final patternIds = <String>{};

    for (int i = 0; i < patternsRaw.length; i++) {
      final item = patternsRaw[i];
      if (item is! Map) {
        return LibraryValidationResult.failure(
          'Pattern at index $i is not a valid JSON object.',
        );
      }
      final patternMap = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);

      final Pattern pattern;
      try {
        pattern = Pattern.fromJson(patternMap);
      } catch (e) {
        final name = patternMap['name'] ?? 'pattern $i';
        return LibraryValidationResult.failure('Invalid pattern "$name": $e');
      }

      if (patternIds.contains(pattern.id)) {
        return LibraryValidationResult.failure(
          'Duplicate pattern ID detected: "${pattern.id}".',
        );
      }
      patternIds.add(pattern.id);
      patterns.add(pattern);
    }

    // 5. Validate sequences, check repeat counts, & check duplicate sequence IDs
    final sequences = <Sequence>[];
    final sequenceIds = <String>{};

    for (int i = 0; i < sequencesRaw.length; i++) {
      final item = sequencesRaw[i];
      if (item is! Map) {
        return LibraryValidationResult.failure(
          'Sequence at index $i is not a valid JSON object.',
        );
      }
      final seqMap = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);

      final entriesRaw = seqMap['entries'];
      if (entriesRaw is List) {
        for (int eIdx = 0; eIdx < entriesRaw.length; eIdx++) {
          final entryJson = entriesRaw[eIdx];
          if (entryJson is Map) {
            final repeatsRaw = entryJson['repeats'];
            if (repeatsRaw is num) {
              final r = repeatsRaw.toInt();
              if (r < SequenceEntry.minRepeats || r > SequenceEntry.maxRepeats) {
                final name = seqMap['name'] ?? 'sequence $i';
                return LibraryValidationResult.failure(
                  'Sequence "$name" has invalid repeats ($r). Repeats must be between ${SequenceEntry.minRepeats} and ${SequenceEntry.maxRepeats}.',
                );
              }
            }
          }
        }
      }

      final Sequence sequence;
      try {
        sequence = Sequence.fromJson(seqMap);
      } catch (e) {
        final name = seqMap['name'] ?? 'sequence $i';
        return LibraryValidationResult.failure('Invalid sequence "$name": $e');
      }

      if (sequenceIds.contains(sequence.id)) {
        return LibraryValidationResult.failure(
          'Duplicate sequence ID detected: "${sequence.id}".',
        );
      }
      sequenceIds.add(sequence.id);

      sequences.add(sequence);
    }

    // 6. Referential integrity: sequences referencing missing patterns
    for (final sequence in sequences) {
      for (final entry in sequence.entries) {
        if (!patternIds.contains(entry.patternId)) {
          return LibraryValidationResult.failure(
            'Sequence "${sequence.name}" references missing pattern "${entry.patternId}".',
          );
        }
      }
    }

    final libraryData = LibraryData(
      format: formatRaw,
      formatVersion: formatVersion,
      exportedAt: map['exportedAt'] as String?,
      appVersion: map['appVersion'] as String? ?? LibraryData.defaultAppVersion,
      patterns: patterns,
      sequences: sequences,
    );

    return LibraryValidationResult.success(libraryData);
  }
}
