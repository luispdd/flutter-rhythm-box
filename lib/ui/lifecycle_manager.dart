import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error.dart';
import 'playback_controller.dart';

/// Top-level lifecycle manager widget that monitors [AppLifecycleState].
/// Disposes the [AudioEngine] when application reaches [AppLifecycleState.detached].
class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudioEngine();
  }

  Future<void> _initializeAudioEngine() async {
    try {
      await ref.read(audioEngineProvider).init();
      ref.read(audioErrorProvider.notifier).clear();
    } catch (e) {
      final msg = 'Audio engine failed to initialize: $e';
      ref.read(audioErrorProvider.notifier).setError(msg);
      showAppSnackBar(msg);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ref.read(audioEngineProvider).dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
