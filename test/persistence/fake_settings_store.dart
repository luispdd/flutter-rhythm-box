import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/persistence/settings_store.dart';

/// In-memory fake implementation of [SettingsStore] for unit testing.
class FakeSettingsStore implements SettingsStore {
  MetronomeSettings? savedSettings;
  Tempo? savedTempo;
  Pattern? savedPattern;

  int saveMetronomeSettingsCalls = 0;
  int loadMetronomeSettingsCalls = 0;
  int saveTempoCalls = 0;
  int loadTempoCalls = 0;
  int saveWorkingPatternCalls = 0;
  int loadWorkingPatternCalls = 0;
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
    savedPattern = null;
    savedPatternLibrary = [];
    savedSequenceLibrary = [];
  }

  List<Pattern> savedPatternLibrary = [];
  int savePatternLibraryCalls = 0;
  int loadPatternLibraryCalls = 0;

  @override
  Future<void> savePatternLibrary(List<Pattern> patterns) async {
    savePatternLibraryCalls++;
    savedPatternLibrary = List.from(patterns);
  }

  @override
  Future<List<Pattern>> loadPatternLibrary() async {
    loadPatternLibraryCalls++;
    return List.from(savedPatternLibrary);
  }

  List<Sequence> savedSequenceLibrary = [];
  int saveSequenceLibraryCalls = 0;
  int loadSequenceLibraryCalls = 0;

  @override
  Future<void> saveSequenceLibrary(List<Sequence> sequences) async {
    saveSequenceLibraryCalls++;
    savedSequenceLibrary = List.from(sequences);
  }

  @override
  Future<List<Sequence>> loadSequenceLibrary() async {
    loadSequenceLibraryCalls++;
    return List.from(savedSequenceLibrary);
  }

  @override
  Future<void> saveWorkingPattern(Pattern pattern) async {
    saveWorkingPatternCalls++;
    savedPattern = pattern;
  }

  @override
  Future<Pattern?> loadWorkingPattern() async {
    loadWorkingPatternCalls++;
    return savedPattern;
  }

  int? savedTabIndex;
  int saveSelectedTabIndexCalls = 0;
  int loadSelectedTabIndexCalls = 0;

  @override
  Future<void> saveSelectedTabIndex(int index) async {
    saveSelectedTabIndexCalls++;
    savedTabIndex = index;
  }

  @override
  Future<int?> loadSelectedTabIndex() async {
    loadSelectedTabIndexCalls++;
    return savedTabIndex;
  }

  @override
  String? lastError;
}
