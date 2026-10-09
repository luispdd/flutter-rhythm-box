import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'pattern.dart';
import 'sequence.dart';

/// Top-level envelope model for exporting and importing the Rhythm Box library.
///
/// Encapsulates all saved [patterns] and [sequences] along with metadata
/// such as [format], [formatVersion], [exportedAt], and [appVersion].
@immutable
class LibraryData {
  /// Expected envelope format identifier.
  static const String expectedFormat = 'rhythm-box-library';

  /// Current envelope schema version.
  static const int currentFormatVersion = 1;

  /// Default application version string when none is provided.
  static const String defaultAppVersion = '1.0.0';

  /// Format identifier string (must equal [expectedFormat]).
  final String format;

  /// Envelope format version number.
  final int formatVersion;

  /// ISO-8601 timestamp representing when the file was exported.
  final String exportedAt;

  /// Application version that exported the file.
  final String appVersion;

  /// Saved patterns contained in the library.
  final List<Pattern> patterns;

  /// Saved sequences contained in the library.
  final List<Sequence> sequences;

  /// Creates a [LibraryData] envelope instance.
  LibraryData({
    this.format = expectedFormat,
    this.formatVersion = currentFormatVersion,
    String? exportedAt,
    this.appVersion = defaultAppVersion,
    List<Pattern>? patterns,
    List<Sequence>? sequences,
  })  : exportedAt = exportedAt ?? DateTime.now().toUtc().toIso8601String(),
        patterns = List<Pattern>.unmodifiable(patterns ?? const []),
        sequences = List<Sequence>.unmodifiable(sequences ?? const []);

  /// Serializes this [LibraryData] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'format': format,
        'formatVersion': formatVersion,
        'exportedAt': exportedAt,
        'appVersion': appVersion,
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'sequences': sequences.map((s) => s.toJson()).toList(),
      };

  /// Serializes this [LibraryData] to a JSON string.
  ///
  /// Formats with 2-space indentation by default for human readability.
  String toJsonString({bool pretty = true}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Deserializes a [LibraryData] instance from a JSON map.
  ///
  /// Throws [FormatException] or [ArgumentError] if the structure or envelope is invalid.
  factory LibraryData.fromJson(Map<String, dynamic> json) {
    final formatRaw = json['format'];
    if (formatRaw is! String) {
      throw const FormatException('Missing or invalid "format" in library envelope.');
    }

    final versionRaw = json['formatVersion'];
    if (versionRaw is! num) {
      throw const FormatException('Missing or invalid "formatVersion" in library envelope.');
    }

    final exportedAtRaw = json['exportedAt'] as String? ?? '';
    final appVersionRaw = json['appVersion'] as String? ?? defaultAppVersion;

    final patternsRaw = json['patterns'];
    if (patternsRaw is! List) {
      throw const FormatException('Missing or invalid "patterns" list in library envelope.');
    }

    final sequencesRaw = json['sequences'];
    if (sequencesRaw is! List) {
      throw const FormatException('Missing or invalid "sequences" list in library envelope.');
    }

    final parsedPatterns = <Pattern>[];
    for (final item in patternsRaw) {
      if (item is Map<String, dynamic>) {
        parsedPatterns.add(Pattern.fromJson(item));
      } else if (item is Map) {
        parsedPatterns.add(Pattern.fromJson(Map<String, dynamic>.from(item)));
      } else {
        throw const FormatException('Invalid pattern entry in library envelope.');
      }
    }

    final parsedSequences = <Sequence>[];
    for (final item in sequencesRaw) {
      if (item is Map<String, dynamic>) {
        parsedSequences.add(Sequence.fromJson(item));
      } else if (item is Map) {
        parsedSequences.add(Sequence.fromJson(Map<String, dynamic>.from(item)));
      } else {
        throw const FormatException('Invalid sequence entry in library envelope.');
      }
    }

    return LibraryData(
      format: formatRaw,
      formatVersion: versionRaw.toInt(),
      exportedAt: exportedAtRaw,
      appVersion: appVersionRaw,
      patterns: parsedPatterns,
      sequences: parsedSequences,
    );
  }

  /// Deserializes a [LibraryData] instance from a JSON string.
  factory LibraryData.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      if (decoded is Map) {
        return LibraryData.fromJson(Map<String, dynamic>.from(decoded));
      }
      throw const FormatException('Library JSON root must be an object.');
    }
    return LibraryData.fromJson(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryData &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          formatVersion == other.formatVersion &&
          exportedAt == other.exportedAt &&
          appVersion == other.appVersion &&
          listEquals(patterns, other.patterns) &&
          listEquals(sequences, other.sequences);

  @override
  int get hashCode => Object.hash(
        format,
        formatVersion,
        exportedAt,
        appVersion,
        Object.hashAll(patterns),
        Object.hashAll(sequences),
      );
}
