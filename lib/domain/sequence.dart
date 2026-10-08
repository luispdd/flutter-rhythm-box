import 'package:flutter/foundation.dart';

/// A single entry within a [Sequence], referencing a pattern and how many times
/// it should repeat before advancing.
@immutable
class SequenceEntry {
  /// Minimum allowed repeats for an entry.
  static const int minRepeats = 1;

  /// Maximum allowed repeats for an entry.
  static const int maxRepeats = 99;

  /// Default repeats for a new entry.
  static const int defaultRepeats = 1;

  /// The ID of the referenced pattern.
  final String patternId;

  /// Number of times the pattern repeats (1 to 99).
  final int repeats;

  /// Creates a [SequenceEntry].
  ///
  /// [repeats] is clamped to [minRepeats]..[maxRepeats].
  SequenceEntry({
    required this.patternId,
    int repeats = defaultRepeats,
  }) : repeats = clampRepeats(repeats);

  /// Clamps an integer repeat count to the valid range [1, 99].
  static int clampRepeats(int value) => value.clamp(minRepeats, maxRepeats);

  /// Returns a copy of this entry with optional updated fields.
  SequenceEntry copyWith({
    String? patternId,
    int? repeats,
  }) {
    return SequenceEntry(
      patternId: patternId ?? this.patternId,
      repeats: repeats ?? this.repeats,
    );
  }

  /// Converts this [SequenceEntry] into a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'patternId': patternId,
        'repeats': repeats,
      };

  /// Deserializes a [SequenceEntry] from a JSON map.
  factory SequenceEntry.fromJson(Map<String, dynamic> json) {
    final patternIdRaw = json['patternId'];
    if (patternIdRaw is! String) {
      throw ArgumentError.value(
        patternIdRaw,
        'patternId',
        'Missing or invalid "patternId" property in SequenceEntry JSON.',
      );
    }

    final repeatsRaw = json['repeats'];
    if (repeatsRaw is! num) {
      throw ArgumentError.value(
        repeatsRaw,
        'repeats',
        'Missing or invalid "repeats" property in SequenceEntry JSON.',
      );
    }

    return SequenceEntry(
      patternId: patternIdRaw,
      repeats: repeatsRaw.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceEntry &&
          runtimeType == other.runtimeType &&
          patternId == other.patternId &&
          repeats == other.repeats;

  @override
  int get hashCode => Object.hash(patternId, repeats);

  @override
  String toString() => 'SequenceEntry(patternId: $patternId, repeats: $repeats)';
}

/// An ordered sequence of pattern references and playback configuration.
@immutable
class Sequence {
  /// Unique identifier for this sequence.
  final String id;

  /// Human-readable sequence name.
  final String name;

  /// Whether playback loops indefinitely or stops after one full run.
  final bool loop;

  /// Ordered list of pattern references.
  final List<SequenceEntry> entries;

  /// Creates a [Sequence] instance.
  Sequence({
    this.id = '',
    this.name = '',
    this.loop = true,
    List<SequenceEntry>? entries,
  }) : entries = List<SequenceEntry>.unmodifiable(entries ?? const []);

  /// Creates a new empty [Sequence].
  factory Sequence.empty({
    String id = '',
    String name = 'New Sequence',
    bool loop = true,
  }) {
    return Sequence(
      id: id,
      name: name,
      loop: loop,
      entries: const [],
    );
  }

  /// Convenience getter matching boolean naming conventions.
  bool get isLooping => loop;

  /// Returns a copy of this sequence with optional updated fields.
  Sequence copyWith({
    String? id,
    String? name,
    bool? loop,
    List<SequenceEntry>? entries,
  }) {
    return Sequence(
      id: id ?? this.id,
      name: name ?? this.name,
      loop: loop ?? this.loop,
      entries: entries ?? this.entries,
    );
  }

  /// Converts this [Sequence] into a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'loop': loop,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  /// Deserializes a [Sequence] from a JSON map.
  factory Sequence.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String) {
      throw ArgumentError.value(
        idRaw,
        'id',
        'Missing or invalid "id" property in Sequence JSON.',
      );
    }

    final nameRaw = json['name'];
    if (nameRaw is! String) {
      throw ArgumentError.value(
        nameRaw,
        'name',
        'Missing or invalid "name" property in Sequence JSON.',
      );
    }

    final loopRaw = json['loop'] ?? json['isLooping'];
    if (loopRaw is! bool) {
      throw ArgumentError.value(
        loopRaw,
        'loop',
        'Missing or invalid "loop" property in Sequence JSON.',
      );
    }

    final entriesRaw = json['entries'];
    if (entriesRaw is! List) {
      throw ArgumentError.value(
        entriesRaw,
        'entries',
        'Missing or invalid "entries" property in Sequence JSON.',
      );
    }

    final parsedEntries = entriesRaw
        .map((e) => SequenceEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return Sequence(
      id: idRaw,
      name: nameRaw,
      loop: loopRaw,
      entries: parsedEntries,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sequence &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          loop == other.loop &&
          listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        loop,
        Object.hashAll(entries),
      );

  @override
  String toString() =>
      'Sequence(id: $id, name: $name, loop: $loop, entries: $entries)';
}
