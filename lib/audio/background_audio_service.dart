import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service managing communication with the native Android foreground playback service
/// via [MethodChannel].
class BackgroundAudioService {
  final MethodChannel _channel;
  final bool _isSupported;
  final List<VoidCallback> _stopListeners = [];

  static const String channelName = 'com.example.rhythmbox/playback';

  BackgroundAudioService({
    MethodChannel? channel,
    bool? isSupported,
  })  : _channel = channel ?? const MethodChannel(channelName),
        _isSupported = isSupported ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
    } catch (_) {
      // Safely ignore when running in headless unit tests without initialized binary messenger.
    }
  }

  /// Whether the current platform supports the native foreground playback service.
  bool get isSupported => _isSupported;

  /// Registers a listener callback invoked when the user taps "Stop" on the notification.
  void addStopListener(VoidCallback listener) {
    _stopListeners.add(listener);
  }

  /// Unregisters a previously registered stop listener.
  void removeStopListener(VoidCallback listener) {
    _stopListeners.remove(listener);
  }

  /// Starts the native foreground service to keep playback alive in the background.
  Future<void> start() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod('startService');
    } on MissingPluginException {
      // Ignored if channel is unimplemented on current target
    } catch (e) {
      debugPrint('BackgroundAudioService.start failed: $e');
    }
  }

  /// Stops the native foreground service and dismisses the notification.
  Future<void> stop() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod('stopService');
    } on MissingPluginException {
      // Ignored if channel is unimplemented on current target
    } catch (e) {
      debugPrint('BackgroundAudioService.stop failed: $e');
    }
  }

  /// Handles incoming calls from the native platform.
  @visibleForTesting
  Future<dynamic> handleMethodCallForTesting(MethodCall call) => _handleMethodCall(call);

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onNotificationStop') {
      for (final listener in List<VoidCallback>.from(_stopListeners)) {
        listener();
      }
    }
    return null;
  }

  /// Cleans up listeners and removes method call handler.
  void dispose() {
    try {
      _channel.setMethodCallHandler(null);
    } catch (_) {}
    _stopListeners.clear();
  }
}

/// Global provider for [BackgroundAudioService].
final backgroundAudioServiceProvider = Provider<BackgroundAudioService>((ref) {
  final service = BackgroundAudioService();
  ref.onDispose(service.dispose);
  return service;
});
