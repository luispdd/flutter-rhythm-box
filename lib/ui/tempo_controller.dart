import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tempo.dart';
import '../persistence/settings_store.dart';

/// Riverpod [Notifier] managing the global tempo in whole beats per minute (BPM).
///
/// Follows Design D3 and the shared-tempo specification:
/// - Default tempo is 120 BPM.
/// - Valid tempo range is strictly clamped to [Tempo.minBpm] (30) .. [Tempo.maxBpm] (300).
/// - Changing the tempo notifies all listeners.
/// - Automatically initializes from and persists to [SettingsStore].
class TempoNotifier extends Notifier<int> {
  @override
  int build() {
    _loadInitialTempo();
    return Tempo.defaultBpm;
  }

  Future<void> _loadInitialTempo() async {
    try {
      final store = ref.read(settingsStoreProvider);
      final savedBpm = await store.loadTempoBpm();
      if (savedBpm != null) {
        state = Tempo.clampBpm(savedBpm);
      }
    } catch (_) {
      // settingsStoreProvider may not be overridden or store access failed.
    }
  }

  /// Explicitly loads the persisted tempo from [SettingsStore] and updates [state].
  Future<void> loadFromStore() => _loadInitialTempo();

  /// Sets the tempo in BPM, clamping to [Tempo.minBpm]..[Tempo.maxBpm],
  /// and persists the new value to [SettingsStore].
  Future<void> setBpm(int bpm) async {
    state = Tempo.clampBpm(bpm);
    await _saveToStore(state);
  }

  /// Increments tempo by [amount] BPM, clamped to [Tempo.maxBpm],
  /// and persists the new value to [SettingsStore].
  Future<void> increment([int amount = 1]) async {
    state = Tempo.clampBpm(state + amount);
    await _saveToStore(state);
  }

  /// Decrements tempo by [amount] BPM, clamped to [Tempo.minBpm],
  /// and persists the new value to [SettingsStore].
  Future<void> decrement([int amount = 1]) async {
    state = Tempo.clampBpm(state - amount);
    await _saveToStore(state);
  }

  Future<void> _saveToStore(int bpm) async {
    try {
      final store = ref.read(settingsStoreProvider);
      await store.saveTempoBpm(bpm);
    } catch (_) {
      // Store not overridden or storage unavailable.
    }
  }
}

/// Global provider for the shared tempo in BPM.
final tempoProvider = NotifierProvider<TempoNotifier, int>(TempoNotifier.new);
