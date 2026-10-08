import 'package:flutter/foundation.dart';
import 'package:rhythm_box/domain/tempo.dart';

/// Sequencer pattern data representing 8 tracks of 16 stored steps.
///
/// An adjustable active [stepCount] (4 to 16, default 16) determines how many
/// of the 16 stored steps are played in a loop. Track 0 corresponds to the lowest voice.
///
/// Instances are immutable; modifications such as [toggleStep], [clear], and
/// [setStepCount] return new instances without mutating the original.
@immutable
class Pattern {
  /// Total number of voice tracks in a pattern.
  static const int trackCount = 8;

  /// Stored step capacity per track.
  static const int stepsPerTrack = 16;

  /// Minimum allowed active step count.
  static const int minStepCount = 4;

  /// Maximum allowed active step count.
  static const int maxStepCount = 16;

  /// Default active step count for new patterns.
  static const int defaultStepCount = 16;

  /// Default tempo in BPM for new patterns.
  static const int defaultTempoBpm = Tempo.defaultBpm;

  /// Unique identifier for this pattern.
  final String id;

  /// Human-readable pattern name.
  final String name;

  /// Pattern playback tempo in whole BPM, clamped between 30 and 300.
  final int tempoBpm;

  /// Active step count for the loop, clamped between 4 and 16.
  final int stepCount;

  /// 8 tracks of 16 boolean steps each.
  final List<List<bool>> tracks;

  /// Default schema version for serialized patterns.
  static const int defaultSchemaVersion = 1;

  /// Schema version for serialization compatibility.
  final int schemaVersion;

  /// Creates a [Pattern] instance.
  ///
  /// If [tracks] is omitted, an empty grid of 8 tracks with 16 steps set to `false` is created.
  /// When provided, [tracks] must contain exactly 8 tracks of 16 booleans each.
  Pattern({
    this.id = '',
    this.name = '',
    int tempoBpm = defaultTempoBpm,
    int stepCount = defaultStepCount,
    this.schemaVersion = defaultSchemaVersion,
    List<List<bool>>? tracks,
  })  : tempoBpm = Tempo.clampBpm(tempoBpm),
        stepCount = clampStepCount(stepCount),
        tracks = _normalizeTracks(tracks);

  /// Creates a new empty [Pattern] with 8 tracks of 16 inactive steps.
  factory Pattern.empty({
    String id = '',
    String name = 'New Pattern',
    int tempoBpm = defaultTempoBpm,
    int stepCount = defaultStepCount,
    int schemaVersion = defaultSchemaVersion,
  }) {
    return Pattern(
      id: id,
      name: name,
      tempoBpm: tempoBpm,
      stepCount: stepCount,
      schemaVersion: schemaVersion,
    );
  }

  /// Clamps an integer step count to the valid range [4, 16].
  static int clampStepCount(int value) => value.clamp(minStepCount, maxStepCount);

  /// Normalizes and deep-copies track lists into unmodifiable structures.
  static List<List<bool>> _normalizeTracks(List<List<bool>>? tracks) {
    if (tracks == null) {
      return List<List<bool>>.unmodifiable(
        List.generate(
          trackCount,
          (_) => List<bool>.unmodifiable(List<bool>.filled(stepsPerTrack, false)),
        ),
      );
    }

    if (tracks.length != trackCount) {
      throw ArgumentError.value(
        tracks.length,
        'tracks',
        'Pattern must have exactly $trackCount tracks, found ${tracks.length}.',
      );
    }

    return List<List<bool>>.unmodifiable(
      tracks.map((track) {
        if (track.length != stepsPerTrack) {
          throw ArgumentError.value(
            track.length,
            'tracks',
            'Each track must have exactly $stepsPerTrack steps, found ${track.length}.',
          );
        }
        return List<bool>.unmodifiable(List<bool>.from(track));
      }),
    );
  }

  /// Returns whether a given step is active.
  bool isStepOn(int trackIndex, int stepIndex) {
    RangeError.checkValueInInterval(trackIndex, 0, trackCount - 1, 'trackIndex');
    RangeError.checkValueInInterval(stepIndex, 0, stepsPerTrack - 1, 'stepIndex');
    return tracks[trackIndex][stepIndex];
  }

  /// Toggles the step at [trackIndex] and [stepIndex], returning a new [Pattern].
  ///
  /// The original instance is not modified.
  Pattern toggleStep(int trackIndex, int stepIndex) {
    RangeError.checkValueInInterval(trackIndex, 0, trackCount - 1, 'trackIndex');
    RangeError.checkValueInInterval(stepIndex, 0, stepsPerTrack - 1, 'stepIndex');

    final updatedTracks = [
      for (int t = 0; t < trackCount; t++)
        [
          for (int s = 0; s < stepsPerTrack; s++)
            if (t == trackIndex && s == stepIndex)
              !tracks[t][s]
            else
              tracks[t][s],
        ],
    ];

    return copyWith(tracks: updatedTracks);
  }

  /// Alias for [toggleStep].
  Pattern toggle(int trackIndex, int stepIndex) =>
      toggleStep(trackIndex, stepIndex);

  /// Clears all 8x16 steps (sets them to `false`), preserving metadata
  /// ([id], [name], [tempoBpm], [stepCount]).
  Pattern clear() {
    return copyWith(
      tracks: List.generate(
        trackCount,
        (_) => List.filled(stepsPerTrack, false),
      ),
    );
  }

  /// Updates the active [stepCount] clamped to [minStepCount]..[maxStepCount],
  /// preserving all stored steps across shrink-and-grow operations.
  Pattern setStepCount(int newStepCount) {
    return copyWith(stepCount: clampStepCount(newStepCount));
  }

  /// Returns a copy of this [Pattern] with updated fields.
  Pattern copyWith({
    String? id,
    String? name,
    int? tempoBpm,
    int? stepCount,
    int? schemaVersion,
    List<List<bool>>? tracks,
  }) {
    return Pattern(
      id: id ?? this.id,
      name: name ?? this.name,
      tempoBpm: tempoBpm ?? this.tempoBpm,
      stepCount: stepCount ?? this.stepCount,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      tracks: tracks ?? this.tracks,
    );
  }

  /// Serializes this [Pattern] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'tempoBpm': tempoBpm,
        'stepCount': stepCount,
        'tracks': tracks.map((track) => List<bool>.from(track)).toList(),
      };

  /// Deserializes a [Pattern] from a JSON map.
  ///
  /// Throws an [ArgumentError] if any required fields are missing or invalid,
  /// or if [tracks] does not contain exactly 8 tracks of 16 booleans.
  factory Pattern.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String) {
      throw ArgumentError.value(
        idRaw,
        'id',
        'Missing or invalid "id" property in Pattern JSON.',
      );
    }

    final nameRaw = json['name'];
    if (nameRaw is! String) {
      throw ArgumentError.value(
        nameRaw,
        'name',
        'Missing or invalid "name" property in Pattern JSON.',
      );
    }

    final tempoRaw = json['tempoBpm'];
    if (tempoRaw is! num) {
      throw ArgumentError.value(
        tempoRaw,
        'tempoBpm',
        'Missing or invalid "tempoBpm" property in Pattern JSON.',
      );
    }

    final stepCountRaw = json['stepCount'];
    if (stepCountRaw is! num) {
      throw ArgumentError.value(
        stepCountRaw,
        'stepCount',
        'Missing or invalid "stepCount" property in Pattern JSON.',
      );
    }

    final tracksRaw = json['tracks'];
    if (tracksRaw is! List) {
      throw ArgumentError.value(
        tracksRaw,
        'tracks',
        'Missing or invalid "tracks" property in Pattern JSON.',
      );
    }

    if (tracksRaw.length != trackCount) {
      throw ArgumentError.value(
        tracksRaw.length,
        'tracks',
        'Expected exactly $trackCount tracks in Pattern JSON, but found ${tracksRaw.length}.',
      );
    }

    final parsedTracks = <List<bool>>[];
    for (int t = 0; t < trackCount; t++) {
      final trackRow = tracksRaw[t];
      if (trackRow is! List) {
        throw ArgumentError.value(
          trackRow,
          'tracks[$t]',
          'Track $t must be a List in Pattern JSON.',
        );
      }
      if (trackRow.length != stepsPerTrack) {
        throw ArgumentError.value(
          trackRow.length,
          'tracks[$t]',
          'Track $t must have exactly $stepsPerTrack steps in Pattern JSON, but found ${trackRow.length}.',
        );
      }
      final steps = <bool>[];
      for (int s = 0; s < stepsPerTrack; s++) {
        final stepVal = trackRow[s];
        if (stepVal is! bool) {
          throw ArgumentError.value(
            stepVal,
            'tracks[$t][$s]',
            'Step at track $t, step $s must be a boolean in Pattern JSON, found $stepVal.',
          );
        }
        steps.add(stepVal);
      }
      parsedTracks.add(steps);
    }

    final schemaVersionRaw = json['schemaVersion'];
    final schemaVersion =
        schemaVersionRaw is num ? schemaVersionRaw.toInt() : defaultSchemaVersion;

    return Pattern(
      id: idRaw,
      name: nameRaw,
      tempoBpm: tempoRaw.toInt(),
      stepCount: stepCountRaw.toInt(),
      schemaVersion: schemaVersion,
      tracks: parsedTracks,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Pattern || runtimeType != other.runtimeType) return false;
    if (other.id != id ||
        other.name != name ||
        other.tempoBpm != tempoBpm ||
        other.stepCount != stepCount ||
        other.schemaVersion != schemaVersion) {
      return false;
    }
    for (int t = 0; t < trackCount; t++) {
      for (int s = 0; s < stepsPerTrack; s++) {
        if (tracks[t][s] != other.tracks[t][s]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    var tracksHash = 0;
    for (final track in tracks) {
      tracksHash = Object.hash(tracksHash, Object.hashAll(track));
    }
    return Object.hash(id, name, tempoBpm, stepCount, schemaVersion, tracksHash);
  }

  @override
  String toString() =>
      'Pattern(id: $id, name: "$name", tempoBpm: $tempoBpm, stepCount: $stepCount, schemaVersion: $schemaVersion)';
}
