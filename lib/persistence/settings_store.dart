import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/metronome_settings.dart';
import '../domain/pattern.dart';
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

  /// Persists the given working [Pattern] to storage.
  Future<void> saveWorkingPattern(Pattern pattern);

  /// Loads the persisted working [Pattern] from storage, or returns `null`
  /// if no pattern has been saved yet or if deserialization fails.
  Future<Pattern?> loadWorkingPattern();

  /// Persists a list of [Pattern]s representing the saved pattern library.
  Future<void> savePatternLibrary(List<Pattern> patterns);

  /// Loads the persisted list of [Pattern]s for the library, or returns
  /// an empty list if no library has been saved or if deserialization fails.
  Future<List<Pattern>> loadPatternLibrary();

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
