import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sequence.dart';
import '../persistence/settings_store.dart';

/// Riverpod [Notifier] managing the library of saved [Sequence]s.
///
/// Holds a list of saved sequences, loads them initially from the
/// [SettingsStore], and provides methods to save, rename, and delete
/// sequences, as well as cascading removals of deleted pattern references.
class SequenceLibraryNotifier extends Notifier<List<Sequence>> {
  @override
  List<Sequence> build() {
    _loadInitialLibrary();
    return const [];
  }

  Future<void> _loadInitialLibrary() async {
    try {
      final store = ref.read(settingsStoreProvider);
      final library = await store.loadSequenceLibrary();
      state = List.unmodifiable(library);
    } catch (_) {
      // settingsStoreProvider may not be overridden or store access failed.
    }
  }

  /// Explicitly loads the persisted sequence library from [SettingsStore] and updates [state].
  Future<void> loadFromStore() => _loadInitialLibrary();

  /// Saves a new sequence to the library. If a sequence with the same ID exists,
  /// it is replaced. Persists the updated library.
  Future<void> saveSequence(Sequence sequence) async {
    final newList = List<Sequence>.from(state);
    final index = newList.indexWhere((s) => s.id == sequence.id);
    if (index >= 0) {
      newList[index] = sequence;
    } else {
      newList.add(sequence);
    }
    state = List.unmodifiable(newList);
    await _saveToStore(state);
  }

  /// Renames an existing sequence in the library.
  Future<void> renameSequence(String id, String newName) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index < 0) return;

    final newList = List<Sequence>.from(state);
    newList[index] = newList[index].copyWith(name: newName);
    state = List.unmodifiable(newList);
    await _saveToStore(state);
  }

  /// Deletes a sequence from the library by its [id].
  Future<void> deleteSequence(String id) async {
    final newList = state.where((s) => s.id != id).toList();
    if (newList.length == state.length) return;

    state = List.unmodifiable(newList);
    await _saveToStore(state);
  }

  /// Returns all sequences that contain at least one entry referencing [patternId].
  List<Sequence> sequencesReferencingPattern(String patternId) {
    return state
        .where((seq) => seq.entries.any((e) => e.patternId == patternId))
        .toList();
  }

  /// Cascading removal: removes all entries referencing [patternId] from every sequence.
  Future<void> removePatternReferences(String patternId) async {
    var changed = false;
    final updatedList = <Sequence>[];

    for (final seq in state) {
      final filteredEntries = seq.entries
          .where((entry) => entry.patternId != patternId)
          .toList();
      if (filteredEntries.length != seq.entries.length) {
        changed = true;
        updatedList.add(seq.copyWith(entries: filteredEntries));
      } else {
        updatedList.add(seq);
      }
    }

    if (changed) {
      state = List.unmodifiable(updatedList);
      await _saveToStore(state);
    }
  }

  Future<void> _saveToStore(List<Sequence> sequences) async {
    try {
      final store = ref.read(settingsStoreProvider);
      await store.saveSequenceLibrary(sequences);
    } catch (_) {
      // Store not overridden or storage unavailable.
    }
  }
}

/// Global provider for the sequence library list.
final sequenceLibraryProvider =
    NotifierProvider<SequenceLibraryNotifier, List<Sequence>>(
        SequenceLibraryNotifier.new);
