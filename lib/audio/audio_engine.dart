import 'dart:async';

import '../domain/audio_buffer.dart';

/// Pure-Dart interface defining audio engine capabilities.
///
/// Designed to decouple audio playback mechanism (e.g. SoLoud, Oboe/native)
/// from the rest of the application without any Flutter or UI dependencies.
abstract interface class AudioEngine {
  /// Initializes the audio engine.
  Future<void> init();

  /// Releases audio engine resources.
  Future<void> dispose();

  /// Starts playback of [buffer] as a seamless, gapless loop (or one-shot if [looping] is false).
  ///
  /// Sound onsets and loop repeating are strictly driven by the audio side clock.
  Future<void> startLoop(AudioBuffer buffer, {bool looping = true});

  /// Schedules [nextBuffer] to seamlessly replace the currently playing loop
  /// at the next loop boundary, without audible click, gap, or doubled hit.
  Future<void> swapLoopAtBoundary(AudioBuffer nextBuffer);

  /// Immediately ceases playback without waiting for the loop boundary.
  Future<void> stop();

  /// Whether a loop is currently playing.
  bool get isPlaying;

  /// Optional stream reporting current playback position or engine clock time.
  Stream<Duration>? get positionStream;
}
