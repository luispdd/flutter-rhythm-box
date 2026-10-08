import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/metronome_settings.dart';
import '../domain/pattern.dart';
import '../domain/sequence.dart';
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

  /// Storage key for persisted working pattern JSON string.
  static const String workingPatternKey = 'working_pattern';

  /// Storage key for persisted pattern library JSON string.
  static const String patternLibraryKey = 'pattern_library';

  /// Storage key for persisted sequence library JSON string.
  static const String sequenceLibraryKey = 'sequence_library';

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
  Future<void> saveWorkingPattern(Pattern pattern) async {
    final jsonString = jsonEncode(pattern.toJson());
    await _prefs.setString(workingPatternKey, jsonString);
  }

  @override
  Future<Pattern?> loadWorkingPattern() async {
    final raw = _prefs.getString(workingPatternKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Pattern.fromJson(decoded);
      } else if (decoded is Map) {
        return Pattern.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePatternLibrary(List<Pattern> patterns) async {
    final jsonList = patterns.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(patternLibraryKey, jsonString);
  }

  @override
  Future<List<Pattern>> loadPatternLibrary() async {
    final raw = _prefs.getString(patternLibraryKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => Pattern.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSequenceLibrary(List<Sequence> sequences) async {
    final jsonList = sequences.map((s) => s.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(sequenceLibraryKey, jsonString);
  }

  @override
  Future<List<Sequence>> loadSequenceLibrary() async {
    final raw = _prefs.getString(sequenceLibraryKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => Sequence.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
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
    await _prefs.remove(workingPatternKey);
    await _prefs.remove(patternLibraryKey);
    await _prefs.remove(sequenceLibraryKey);
  }
}
