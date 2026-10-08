import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/background_audio_service.dart';
import 'app_error.dart';
import 'metronome_controller.dart';
import 'playback_controller.dart';
import 'sequence_controller.dart';
import 'sequencer_controller.dart';

/// Top-level lifecycle manager widget that monitors [AppLifecycleState]
/// and wires notifications stops from [BackgroundAudioService].
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
  late final BackgroundAudioService _backgroundAudioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudioEngine();
    _backgroundAudioService = ref.read(backgroundAudioServiceProvider);
    _backgroundAudioService.addStopListener(_handleNotificationStop);
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

  void _handleNotificationStop() {
    if (ref.read(metronomeControllerProvider).isPlaying) {
      ref.read(metronomeControllerProvider.notifier).stop();
    }
    if (ref.read(sequencerControllerProvider).isPlaying) {
      ref.read(sequencerControllerProvider.notifier).stop();
    }
    if (ref.read(sequenceControllerProvider).isPlaying) {
      ref.read(sequenceControllerProvider.notifier).stop();
    }
    if (ref.read(metronomePlaybackControllerProvider).isPlaying) {
      ref.read(metronomePlaybackControllerProvider.notifier).stop();
    }
    if (ref.read(sequencerPlaybackControllerProvider).isPlaying) {
      ref.read(sequencerPlaybackControllerProvider.notifier).stop();
    }
  }

  @override
  void dispose() {
    _backgroundAudioService.removeStopListener(_handleNotificationStop);
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
