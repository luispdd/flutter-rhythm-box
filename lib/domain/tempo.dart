/// Represents a tempo in whole beats per minute (BPM).
///
/// Valid tempo range is strictly clamped between [minBpm] (30) and [maxBpm] (300).
/// The default tempo is [defaultBpm] (120).
class Tempo {
  /// Minimum allowed tempo in BPM.
  static const int minBpm = 30;

  /// Maximum allowed tempo in BPM.
  static const int maxBpm = 300;

  /// Default starting tempo in BPM.
  static const int defaultBpm = 120;

  /// Tempo in whole beats per minute, clamped between [minBpm] and [maxBpm].
  final int bpm;

  /// Creates a [Tempo] instance, clamping [bpm] between [minBpm] and [maxBpm].
  const Tempo([int bpm = defaultBpm])
      : bpm = bpm < minBpm
            ? minBpm
            : (bpm > maxBpm ? maxBpm : bpm);

  /// Clamps an arbitrary integer BPM to the valid range [30, 300].
  static int clampBpm(int value) => value.clamp(minBpm, maxBpm);

  /// Convenience getter for the BPM value.
  int get value => bpm;

  /// Returns a new [Tempo] with [amount] BPM added, clamped to [maxBpm].
  Tempo increment([int amount = 1]) => Tempo(bpm + amount);

  /// Returns a new [Tempo] with [amount] BPM subtracted, clamped to [minBpm].
  Tempo decrement([int amount = 1]) => Tempo(bpm - amount);

  /// Returns a copy of this [Tempo] with an optionally updated [bpm].
  Tempo copyWith({int? bpm}) => Tempo(bpm ?? this.bpm);

  /// Serializes this [Tempo] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'bpm': bpm};

  /// Deserializes a [Tempo] from a JSON map, falling back to [defaultBpm] if missing.
  factory Tempo.fromJson(Map<String, dynamic> json) {
    final value = json['bpm'] ?? json['tempoBpm'];
    if (value is num) {
      return Tempo(value.toInt());
    }
    return const Tempo();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tempo &&
          runtimeType == other.runtimeType &&
          other.bpm == bpm;

  @override
  int get hashCode => bpm.hashCode;

  @override
  String toString() => 'Tempo($bpm BPM)';
}
