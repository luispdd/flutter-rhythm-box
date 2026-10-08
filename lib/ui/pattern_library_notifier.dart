import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pattern.dart';
import '../persistence/settings_store.dart';
import 'app_error.dart';
import 'sequence_library_notifier.dart';

/// Riverpod [Notifier] managing the library of saved [Pattern]s.
///
/// Holds a list of saved patterns, loads them initially from the
/// [SettingsStore], and provides methods to save, rename, and delete
/// patterns in the library.
class PatternLibraryNotifier extends Notifier<List<Pattern>> {
  @override
  List<Pattern> build() {
    _loadInitialLibrary();
    return const [];
  }

  Future<void> _loadInitialLibrary() async {
    try {
      final store = ref.read(settingsStoreProvider);
      final library = await store.loadPatternLibrary();
      state = List.unmodifiable(library);
    } catch (_) {
      // settingsStoreProvider may not be overridden or store access failed.
    }
  }

  /// Explicitly loads the persisted pattern library from [SettingsStore] and updates [state].
  Future<void> loadFromStore() => _loadInitialLibrary();

  /// Saves a new pattern to the library. If a pattern with the same ID exists,
  /// it is replaced. Persists the updated library.
  Future<void> savePattern(Pattern pattern) async {
    final newList = List<Pattern>.from(state);
    final index = newList.indexWhere((p) => p.id == pattern.id);
    if (index >= 0) {
      newList[index] = pattern;
    } else {
      newList.add(pattern);
    }
    state = List.unmodifiable(newList);
    await _saveToStore(state);
  }

  /// Renames an existing pattern in the library.
  Future<void> renamePattern(String id, String newName) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index < 0) return;

    final newList = List<Pattern>.from(state);
    newList[index] = newList[index].copyWith(name: newName);
    state = List.unmodifiable(newList);
    await _saveToStore(state);
  }

  /// Deletes a pattern from the library by its [id] and cascades the deletion
  /// by removing references from any saved sequences.
  Future<void> deletePattern(String id) async {
    final newList = state.where((p) => p.id != id).toList();
    if (newList.length == state.length) return;

    state = List.unmodifiable(newList);
    await _saveToStore(state);

    try {
      await ref.read(sequenceLibraryProvider.notifier).removePatternReferences(id);
    } catch (_) {
      // Sequence library provider may not be initialized or available.
    }
  }

  Future<void> _saveToStore(List<Pattern> patterns) async {
    try {
      final store = ref.read(settingsStoreProvider);
      await store.savePatternLibrary(patterns);
    } catch (e) {
      if (!isStoreUnimplemented(e)) {
        ref.read(appErrorProvider.notifier).setError('Failed to save pattern library: $e');
        showAppSnackBar('Failed to save pattern library');
      }
    }
  }
}

/// Global provider for the pattern library list.
final patternLibraryProvider =
    NotifierProvider<PatternLibraryNotifier, List<Pattern>>(
        PatternLibraryNotifier.new);
