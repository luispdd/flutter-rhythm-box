import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/persistence/settings_store.dart';

/// In-memory fake implementation of [SettingsStore] for unit testing.
class FakeSettingsStore implements SettingsStore {
  MetronomeSettings? savedSettings;
  Tempo? savedTempo;

  int saveMetronomeSettingsCalls = 0;
  int loadMetronomeSettingsCalls = 0;
  int saveTempoCalls = 0;
  int loadTempoCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> saveMetronomeSettings(MetronomeSettings settings) async {
    saveMetronomeSettingsCalls++;
    savedSettings = settings;
  }

  @override
  Future<MetronomeSettings?> loadMetronomeSettings() async {
    loadMetronomeSettingsCalls++;
    return savedSettings;
  }

  @override
  Future<void> saveTempo(Tempo tempo) async {
    saveTempoCalls++;
    savedTempo = tempo;
  }

  @override
  Future<Tempo?> loadTempo() async {
    loadTempoCalls++;
    return savedTempo;
  }

  @override
  Future<void> saveTempoBpm(int bpm) async {
    await saveTempo(Tempo(bpm));
  }

  @override
  Future<int?> loadTempoBpm() async {
    final tempo = await loadTempo();
    return tempo?.bpm;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    savedSettings = null;
    savedTempo = null;
  }
}
