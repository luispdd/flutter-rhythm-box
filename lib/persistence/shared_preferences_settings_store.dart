import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  /// Storage key for persisted selected tab index.
  static const String selectedTabIndexKey = 'selected_tab_index';

  final SharedPreferences _prefs;
  String? _lastError;

  /// Creates a [SharedPreferencesSettingsStore] backed by [_prefs].
  SharedPreferencesSettingsStore(this._prefs);

  @override
  String? get lastError => _lastError;

  /// Initializes a new [SharedPreferencesSettingsStore] instance by fetching
  /// the underlying [SharedPreferences] singleton.
  static Future<SharedPreferencesSettingsStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesSettingsStore(prefs);
  }

  @override
  Future<void> saveMetronomeSettings(MetronomeSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      final ok = await _prefs.setString(metronomeSettingsKey, jsonString);
      if (!ok) {
        throw StateError('Failed to write metronome settings to storage');
      }
      _lastError = null;
    } catch (e, st) {
      _lastError = 'Error saving metronome settings: $e';
      debugPrint('$_lastError\n$st');
      rethrow;
    }
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
    } catch (e, st) {
      debugPrint('Error decoding metronome settings: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> saveTempo(Tempo tempo) async {
    try {
      final jsonString = jsonEncode(tempo.toJson());
      final ok = await _prefs.setString(tempoKey, jsonString);
      if (!ok) {
        throw StateError('Failed to write tempo to storage');
      }
      _lastError = null;
    } catch (e, st) {
      _lastError = 'Error saving tempo: $e';
      debugPrint('$_lastError\n$st');
      rethrow;
    }
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
    } catch (e, st) {
      debugPrint('Error decoding tempo: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> saveWorkingPattern(Pattern pattern) async {
    try {
      final jsonString = jsonEncode(pattern.toJson());
      final ok = await _prefs.setString(workingPatternKey, jsonString);
      if (!ok) {
        throw StateError('Failed to write working pattern to storage');
      }
      _lastError = null;
    } catch (e, st) {
      _lastError = 'Error saving working pattern: $e';
      debugPrint('$_lastError\n$st');
      rethrow;
    }
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
    } catch (e, st) {
      debugPrint('Error decoding working pattern: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> savePatternLibrary(List<Pattern> patterns) async {
    try {
      final jsonList = patterns.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final ok = await _prefs.setString(patternLibraryKey, jsonString);
      if (!ok) {
        throw StateError('Failed to write pattern library to storage');
      }
      _lastError = null;
    } catch (e, st) {
      _lastError = 'Error saving pattern library: $e';
      debugPrint('$_lastError\n$st');
      rethrow;
    }
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
        final list = <Pattern>[];
        for (final item in decoded) {
          try {
            if (item is Map) {
              list.add(Pattern.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (itemError) {
            debugPrint('Error decoding individual pattern in library: $itemError');
          }
        }
        return list;
      }
      return [];
    } catch (e, st) {
      debugPrint('Error decoding pattern library: $e\n$st');
      return [];
    }
  }

  @override
  Future<void> saveSequenceLibrary(List<Sequence> sequences) async {
    try {
      final jsonList = sequences.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final ok = await _prefs.setString(sequenceLibraryKey, jsonString);
      if (!ok) {
        throw StateError('Failed to write sequence library to storage');
      }
      _lastError = null;
    } catch (e, st) {
      _lastError = 'Error saving sequence library: $e';
      debugPrint('$_lastError\n$st');
      rethrow;
    }
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
        final list = <Sequence>[];
        for (final item in decoded) {
          try {
            if (item is Map) {
              list.add(Sequence.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (itemError) {
            debugPrint('Error decoding individual sequence in library: $itemError');
          }
        }
        return list;
      }
      return [];
    } catch (e, st) {
      debugPrint('Error decoding sequence library: $e\n$st');
      return [];
    }
  }

  @override
  Future<void> saveSelectedTabIndex(int index) async {
    try {
      final ok = await _prefs.setInt(selectedTabIndexKey, index);
      if (!ok) {
        throw StateError('Failed to write selected tab index to storage');
      }
      _lastError = null;
    } catch (e, st) {
      _lastError = 'Error saving selected tab index: $e';
      debugPrint('$_lastError\n$st');
      rethrow;
    }
  }

  @override
  Future<int?> loadSelectedTabIndex() async {
    try {
      return _prefs.getInt(selectedTabIndexKey);
    } catch (e, st) {
      _lastError = 'Error loading selected tab index: $e';
      debugPrint('$_lastError\n$st');
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
    await _prefs.remove(workingPatternKey);
    await _prefs.remove(patternLibraryKey);
    await _prefs.remove(sequenceLibraryKey);
    await _prefs.remove(selectedTabIndexKey);
    _lastError = null;
  }
}
