import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global key to show SnackBars across screens without requiring local BuildContext.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Helper to detect when [settingsStoreProvider] was not overridden in tests.
bool isStoreUnimplemented(Object e) =>
    e is UnimplementedError || e.toString().contains('UnimplementedError');

/// Riverpod [Notifier] holding the latest app/storage error message, if any.
class AppErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? message) {
    state = message;
  }

  void clear() {
    state = null;
  }
}

/// Global provider for the latest app error message.
final appErrorProvider =
    NotifierProvider<AppErrorNotifier, String?>(AppErrorNotifier.new);

/// Displays a floating SnackBar at the root ScaffoldMessenger level.
void showAppSnackBar(String message, {bool isError = true}) {
  try {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (_) {
    // Binding not initialized (e.g. headless unit tests) or messenger unavailable.
  }
}

/// Riverpod [Notifier] holding the latest audio engine error message, if any.
class AudioErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? message) {
    state = message;
  }

  void clear() {
    state = null;
  }
}

/// Global provider for audio engine initialization or playback errors.
final audioErrorProvider =
    NotifierProvider<AudioErrorNotifier, String?>(AudioErrorNotifier.new);

