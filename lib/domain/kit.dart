import 'package:flutter/foundation.dart';
import 'voice.dart';

/// Representation of a data-driven sound kit consisting of exactly 8 voice presets.
@immutable
class Kit {
  /// Expected number of tracks per kit.
  static const int trackCount = 8;

  /// Default schema version for kit JSON files.
  static const int defaultSchemaVersion = 1;

  /// Schema version for serialization compatibility.
  final int schemaVersion;

  /// Unique stable identifier (e.g. "classic-synth", "retro-8bit").
  final String id;

  /// Human-readable display name (e.g. "Classic synth").
  final String name;

  /// Whether this kit is a built-in application asset.
  final bool builtIn;

  /// Exactly 8 voice configurations for tracks 0 (lowest) to 7 (highest).
  final List<Voice> voices;

  /// Creates a [Kit] instance.
  ///
  /// Throws [ArgumentError] if [id] or [name] is empty, or if [voices] does not
  /// contain exactly [trackCount] (8) voices, or if any voice parameter is out of bounds.
  Kit({
    this.schemaVersion = defaultSchemaVersion,
    required this.id,
    required this.name,
    this.builtIn = false,
    required List<Voice> voices,
  })  : voices = List<Voice>.unmodifiable(voices) {
    validateKit(this);
  }

  /// Returns a copy of this [Kit] with updated fields.
  Kit copyWith({
    int? schemaVersion,
    String? id,
    String? name,
    bool? builtIn,
    List<Voice>? voices,
  }) {
    return Kit(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      builtIn: builtIn ?? this.builtIn,
      voices: voices ?? this.voices,
    );
  }

  /// Serializes this [Kit] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'builtIn': builtIn,
        'voices': voices.map((v) => v.toJson()).toList(),
      };

  /// Deserializes a [Kit] from a JSON map, strictly validating all fields.
  ///
  /// Throws [ArgumentError] if any required fields are missing, invalid, or out of range.
  factory Kit.fromJson(Map<String, dynamic> json) {
    final schemaVersionRaw = json['schemaVersion'];
    final schemaVersion =
        schemaVersionRaw is num ? schemaVersionRaw.toInt() : defaultSchemaVersion;

    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Kit JSON must include a non-empty string "id".');
    }

    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Kit JSON must include a non-empty string "name".');
    }

    final builtIn = json['builtIn'] == true;

    final voicesRaw = json['voices'];
    if (voicesRaw is! List) {
      throw ArgumentError.value(
        voicesRaw,
        'voices',
        'Kit JSON must include a "voices" array.',
      );
    }

    if (voicesRaw.length != trackCount) {
      throw ArgumentError.value(
        voicesRaw.length,
        'voices',
        'Kit must define exactly $trackCount voices, found ${voicesRaw.length}.',
      );
    }

    final voices = <Voice>[];
    for (var i = 0; i < voicesRaw.length; i++) {
      final voiceJson = voicesRaw[i];
      if (voiceJson is! Map<String, dynamic>) {
        throw ArgumentError.value(
          voiceJson,
          'voices[$i]',
          'Voice at index $i must be a valid JSON map.',
        );
      }
      voices.add(Voice.fromJson(voiceJson));
    }

    return Kit(
      schemaVersion: schemaVersion,
      id: id.trim(),
      name: name.trim(),
      builtIn: builtIn,
      voices: voices,
    );
  }

  /// Validates a [Kit] and its voices against allowed ranges.
  ///
  /// Throws [ArgumentError] if any rule is violated.
  static void validateKit(Kit kit) {
    if (kit.id.trim().isEmpty) {
      throw ArgumentError.value(kit.id, 'id', 'Kit ID cannot be empty.');
    }
    if (kit.name.trim().isEmpty) {
      throw ArgumentError.value(kit.name, 'name', 'Kit name cannot be empty.');
    }
    if (kit.voices.length != trackCount) {
      throw ArgumentError.value(
        kit.voices.length,
        'voices',
        'Kit must have exactly $trackCount voices.',
      );
    }

    for (var i = 0; i < kit.voices.length; i++) {
      final v = kit.voices[i];
      if (v.startFreqHz < 0.0 || v.startFreqHz > 22050.0) {
        throw ArgumentError.value(
          v.startFreqHz,
          'voices[$i].startFreqHz',
          'startFreqHz must be between 0 and 22050 Hz.',
        );
      }
      if (v.endFreqHz < 0.0 || v.endFreqHz > 22050.0) {
        throw ArgumentError.value(
          v.endFreqHz,
          'voices[$i].endFreqHz',
          'endFreqHz must be between 0 and 22050 Hz.',
        );
      }
      if (v.decayMs <= 0.0 || v.decayMs > 10000.0) {
        throw ArgumentError.value(
          v.decayMs,
          'voices[$i].decayMs',
          'decayMs must be positive and <= 10000 ms.',
        );
      }
      if (v.gain < 0.0 || v.gain > 2.0) {
        throw ArgumentError.value(
          v.gain,
          'voices[$i].gain',
          'gain must be between 0.0 and 2.0.',
        );
      }
      if (v.dutyCycle != null && (v.dutyCycle! < 0.05 || v.dutyCycle! > 0.95)) {
        throw ArgumentError.value(
          v.dutyCycle,
          'voices[$i].dutyCycle',
          'dutyCycle must be between 0.05 and 0.95.',
        );
      }
      if (v.lfsrClockHz != null && (v.lfsrClockHz! < 100.0 || v.lfsrClockHz! > 48000.0)) {
        throw ArgumentError.value(
          v.lfsrClockHz,
          'voices[$i].lfsrClockHz',
          'lfsrClockHz must be between 100 and 48000 Hz.',
        );
      }
      if (v.bitDepth != null && (v.bitDepth! < 2 || v.bitDepth! > 16)) {
        throw ArgumentError.value(
          v.bitDepth,
          'voices[$i].bitDepth',
          'bitDepth must be an integer between 2 and 16.',
        );
      }
      if (v.downsampleHz != null && (v.downsampleHz! < 1000.0 || v.downsampleHz! > 44100.0)) {
        throw ArgumentError.value(
          v.downsampleHz,
          'voices[$i].downsampleHz',
          'downsampleHz must be between 1000 and 44100 Hz.',
        );
      }
    }
  }

  /// Default `classic-synth` kit built from [defaultVoices].
  static Kit get classicSynth => Kit(
        id: 'classic-synth',
        name: 'Classic synth',
        builtIn: true,
        voices: defaultVoices,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kit &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          id == other.id &&
          name == other.name &&
          builtIn == other.builtIn &&
          listEquals(other.voices, voices);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        id,
        name,
        builtIn,
        Object.hashAll(voices),
      );

  @override
  String toString() =>
      'Kit(id: $id, name: "$name", builtIn: $builtIn, voices: ${voices.length})';
}
