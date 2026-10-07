import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/metronome_settings.dart';
import '../domain/tempo.dart';

/// Abstract storage interface for persisting application settings.
///
/// Decouples persistence mechanisms (such as [SharedPreferences])
/// from the state management and domain layers.
abstract interface class SettingsStore {
  /// Persists the given [settings] to storage.
  Future<void> saveMetronomeSettings(MetronomeSettings settings);

  /// Loads the persisted [MetronomeSettings] from storage, or returns `null`
  /// if no settings have been saved yet or if deserialization fails.
  Future<MetronomeSettings?> loadMetronomeSettings();

  /// Persists the given [tempo] to storage.
  Future<void> saveTempo(Tempo tempo);

  /// Loads the persisted [Tempo] from storage, or returns `null`
  /// if no tempo has been saved yet or if deserialization fails.
  Future<Tempo?> loadTempo();

  /// Convenience method to save tempo by integer BPM.
  Future<void> saveTempoBpm(int bpm);

  /// Convenience method to load persisted tempo BPM, or returns `null`
  /// if no tempo has been saved yet.
  Future<int?> loadTempoBpm();

  /// Clears all persisted settings.
  Future<void> clear();
}

/// Provider exposing the active [SettingsStore] instance.
///
/// Must be overridden with an initialized store instance
/// (e.g. [SharedPreferencesSettingsStore]) in `main.dart` or tests.
final settingsStoreProvider = Provider<SettingsStore>((ref) {
  throw UnimplementedError(
    'settingsStoreProvider must be overridden with an initialized SettingsStore instance.',
  );
});
