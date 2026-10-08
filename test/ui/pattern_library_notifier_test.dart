import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';

import '../persistence/fake_settings_store.dart';

void main() {
  group('PatternLibraryNotifier', () {
    late FakeSettingsStore fakeStore;
    late ProviderContainer container;

    setUp(() {
      fakeStore = FakeSettingsStore();
      container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(fakeStore),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with empty library if store has no patterns', () async {
      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      final state = container.read(patternLibraryProvider);
      expect(state, isEmpty);
    });

    test('initializes with loaded patterns from store', () async {
      final initialPatterns = [
        Pattern.empty(id: '1', name: 'Beat 1'),
        Pattern.empty(id: '2', name: 'Beat 2'),
      ];
      fakeStore.savedPatternLibrary = initialPatterns;

      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      final state = container.read(patternLibraryProvider);
      expect(state, equals(initialPatterns));
    });

    test('savePattern adds a new pattern and saves to store', () async {
      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      final newPattern = Pattern.empty(id: '1', name: 'New Beat');
      await notifier.savePattern(newPattern);

      final state = container.read(patternLibraryProvider);
      expect(state, hasLength(1));
      expect(state.first, equals(newPattern));

      expect(fakeStore.savedPatternLibrary, hasLength(1));
      expect(fakeStore.savedPatternLibrary.first, equals(newPattern));
    });

    test('savePattern replaces an existing pattern with the same id', () async {
      final existingPattern = Pattern.empty(id: '1', name: 'Old Beat');
      fakeStore.savedPatternLibrary = [existingPattern];

      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      final updatedPattern = Pattern.empty(id: '1', name: 'Updated Beat').toggle(0, 0);
      await notifier.savePattern(updatedPattern);

      final state = container.read(patternLibraryProvider);
      expect(state, hasLength(1));
      expect(state.first, equals(updatedPattern));
      expect(state.first.name, equals('Updated Beat'));

      expect(fakeStore.savedPatternLibrary, hasLength(1));
      expect(fakeStore.savedPatternLibrary.first, equals(updatedPattern));
    });

    test('renamePattern updates the pattern name and saves to store', () async {
      final pattern = Pattern.empty(id: '1', name: 'Original');
      fakeStore.savedPatternLibrary = [pattern];

      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.renamePattern('1', 'Renamed');

      final state = container.read(patternLibraryProvider);
      expect(state, hasLength(1));
      expect(state.first.name, equals('Renamed'));

      expect(fakeStore.savedPatternLibrary, hasLength(1));
      expect(fakeStore.savedPatternLibrary.first.name, equals('Renamed'));
    });

    test('renamePattern ignores unknown id', () async {
      final pattern = Pattern.empty(id: '1', name: 'Original');
      fakeStore.savedPatternLibrary = [pattern];
      fakeStore.savePatternLibraryCalls = 0; // reset

      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.renamePattern('unknown', 'Renamed');

      final state = container.read(patternLibraryProvider);
      expect(state.first.name, equals('Original'));
      expect(fakeStore.savePatternLibraryCalls, equals(0));
    });

    test('deletePattern removes the pattern and saves to store', () async {
      final p1 = Pattern.empty(id: '1', name: 'P1');
      final p2 = Pattern.empty(id: '2', name: 'P2');
      fakeStore.savedPatternLibrary = [p1, p2];

      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.deletePattern('1');

      final state = container.read(patternLibraryProvider);
      expect(state, hasLength(1));
      expect(state.first.id, equals('2'));

      expect(fakeStore.savedPatternLibrary, hasLength(1));
      expect(fakeStore.savedPatternLibrary.first.id, equals('2'));
    });

    test('deletePattern ignores unknown id', () async {
      final p1 = Pattern.empty(id: '1', name: 'P1');
      fakeStore.savedPatternLibrary = [p1];
      fakeStore.savePatternLibraryCalls = 0; // reset

      final notifier = container.read(patternLibraryProvider.notifier);
      await notifier.loadFromStore();

      await notifier.deletePattern('unknown');

      final state = container.read(patternLibraryProvider);
      expect(state, hasLength(1));
      expect(fakeStore.savePatternLibraryCalls, equals(0));
    });
  });
}
