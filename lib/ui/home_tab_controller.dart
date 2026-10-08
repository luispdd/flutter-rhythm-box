import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/settings_store.dart';
import 'app_error.dart';

/// Riverpod [Notifier] managing the active home tab index and persisting it across sessions.
class HomeTabController extends Notifier<int> {
  @override
  int build() {
    _loadFromStore();
    return 0;
  }

  Future<void> _loadFromStore() async {
    try {
      final store = ref.read(settingsStoreProvider);
      final saved = await store.loadSelectedTabIndex();
      if (saved != null) {
        state = saved.clamp(0, 2);
      }
    } catch (_) {
      // Store may not be overridden; keep default index 0.
    }
  }

  /// Updates the active tab index and saves it to [SettingsStore].
  Future<void> setIndex(int index) async {
    final clamped = index.clamp(0, 2);
    state = clamped;
    try {
      final store = ref.read(settingsStoreProvider);
      await store.saveSelectedTabIndex(clamped);
    } catch (e) {
      if (!isStoreUnimplemented(e)) {
        ref.read(appErrorProvider.notifier).setError('Failed to save selected tab: $e');
        showAppSnackBar('Failed to save selected tab');
      }
    }
  }

  /// Explicitly loads the tab index from [SettingsStore] and updates [state].
  Future<void> loadFromStore() => _loadFromStore();
}

/// Global provider for the active home tab index.
final homeTabControllerProvider =
    NotifierProvider<HomeTabController, int>(HomeTabController.new);
