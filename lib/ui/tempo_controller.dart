import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tempo.dart';

/// Riverpod [Notifier] managing the global tempo in whole beats per minute (BPM).
///
/// Follows Design D3 and the shared-tempo specification:
/// - Default tempo is 120 BPM.
/// - Valid tempo range is strictly clamped to [Tempo.minBpm] (30) .. [Tempo.maxBpm] (300).
/// - Changing the tempo notifies all listeners.
class TempoNotifier extends Notifier<int> {
  @override
  int build() => Tempo.defaultBpm;

  /// Sets the tempo in BPM, clamping to [Tempo.minBpm]..[Tempo.maxBpm].
  void setBpm(int bpm) {
    state = Tempo.clampBpm(bpm);
  }

  /// Increments tempo by [amount] BPM, clamped to [Tempo.maxBpm].
  void increment([int amount = 1]) {
    state = Tempo.clampBpm(state + amount);
  }

  /// Decrements tempo by [amount] BPM, clamped to [Tempo.minBpm].
  void decrement([int amount = 1]) {
    state = Tempo.clampBpm(state - amount);
  }
}

/// Global provider for the shared tempo in BPM.
final tempoProvider = NotifierProvider<TempoNotifier, int>(TempoNotifier.new);
