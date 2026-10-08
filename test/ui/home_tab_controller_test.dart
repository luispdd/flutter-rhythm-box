import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/app_error.dart';
import 'package:rhythm_box/ui/home_tab_controller.dart';

import '../persistence/fake_settings_store.dart';

class TestSettingsStore extends FakeSettingsStore {
  int? savedIndex;
  bool shouldThrowOnSave = false;

  @override
  Future<int?> loadSelectedTabIndex() async => savedIndex;

  @override
  Future<void> saveSelectedTabIndex(int index) async {
    if (shouldThrowOnSave) {
      throw Exception('Disk full');
    }
    savedIndex = index;
  }
}

void main() {
  group('HomeTabController', () {
    test('defaults to 0 when store has no saved index', () async {
      final store = TestSettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(homeTabControllerProvider.notifier);
      await notifier.loadFromStore();

      expect(container.read(homeTabControllerProvider), equals(0));
    });

    test('loads saved index from store and clamps to [0, 2]', () async {
      final store = TestSettingsStore()..savedIndex = 2;
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(homeTabControllerProvider.notifier);
      await notifier.loadFromStore();

      expect(container.read(homeTabControllerProvider), equals(2));
    });

    test('setIndex updates state and saves to store', () async {
      final store = TestSettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(homeTabControllerProvider.notifier);
      await notifier.setIndex(1);

      expect(container.read(homeTabControllerProvider), equals(1));
      expect(store.savedIndex, equals(1));
    });

    test('setIndex clamps values outside range', () async {
      final store = TestSettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(homeTabControllerProvider.notifier);
      await notifier.setIndex(5);

      expect(container.read(homeTabControllerProvider), equals(2));
      expect(store.savedIndex, equals(2));
    });

    test('reports error to appErrorProvider when save fails', () async {
      final store = TestSettingsStore()..shouldThrowOnSave = true;
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(homeTabControllerProvider.notifier);
      await notifier.setIndex(1);

      expect(container.read(appErrorProvider), contains('Disk full'));
    });
  });
}
