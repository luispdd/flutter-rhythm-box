import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/metronome_settings.dart';
import '../domain/tempo.dart';
import 'settings_store.dart';

/// Implementation of [SettingsStore] that persists settings using [SharedPreferences].
///
/// Serializes domain entities ([MetronomeSettings], [Tempo]) into JSON strings
/// and stores them under dedicated preference keys.
class SharedPreferencesSettingsStore implements SettingsStore {
  /// Storage key for persisted metronome settings JSON string.
  static const String metronomeSettingsKey = 'metronome_settings';

  /// Storage key for persisted global tempo JSON string.
  static const String tempoKey = 'global_tempo';

  final SharedPreferences _prefs;

  /// Creates a [SharedPreferencesSettingsStore] backed by [_prefs].
  const SharedPreferencesSettingsStore(this._prefs);

  /// Initializes a new [SharedPreferencesSettingsStore] instance by fetching
  /// the underlying [SharedPreferences] singleton.
  static Future<SharedPreferencesSettingsStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesSettingsStore(prefs);
  }

  @override
  Future<void> saveMetronomeSettings(MetronomeSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(metronomeSettingsKey, jsonString);
  }

  @override
  Future<MetronomeSettings?> loadMetronomeSettings() async {
    final raw = _prefs.getString(metronomeSettingsKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return MetronomeSettings.fromJson(decoded);
      } else if (decoded is Map) {
        return MetronomeSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTempo(Tempo tempo) async {
    final jsonString = jsonEncode(tempo.toJson());
    await _prefs.setString(tempoKey, jsonString);
  }

  @override
  Future<Tempo?> loadTempo() async {
    final raw = _prefs.getString(tempoKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Tempo.fromJson(decoded);
      } else if (decoded is Map) {
        return Tempo.fromJson(Map<String, dynamic>.from(decoded));
      } else if (decoded is num) {
        return Tempo(decoded.toInt());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTempoBpm(int bpm) => saveTempo(Tempo(bpm));

  @override
  Future<int?> loadTempoBpm() async {
    final tempo = await loadTempo();
    return tempo?.bpm;
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(metronomeSettingsKey);
    await _prefs.remove(tempoKey);
  }
}
