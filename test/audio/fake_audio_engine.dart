import 'dart:async';

import 'package:rhythm_box/audio/audio_engine.dart';
import 'package:rhythm_box/domain/audio_buffer.dart';

/// Test double implementing [AudioEngine] for headless unit and widget testing.
///
/// Records all calls to start, swap, and stop, and models the engine contract
/// for loop boundaries and "latest swap wins" behavior.
class FakeAudioEngine implements AudioEngine {
  bool isInitialized = false;
  bool isDisposed = false;
  bool _isPlaying = false;

  int startLoopCalls = 0;
  int swapLoopCalls = 0;
  int stopCalls = 0;

  final List<AudioBuffer> startedBuffers = [];
  final List<AudioBuffer> swappedBuffers = [];

  AudioBuffer? audibleBuffer;
  AudioBuffer? pendingBuffer;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  AudioBuffer? get lastStartedBuffer =>
      startedBuffers.isNotEmpty ? startedBuffers.last : null;

  AudioBuffer? get lastSwappedBuffer =>
      swappedBuffers.isNotEmpty ? swappedBuffers.last : null;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  void emitPosition(Duration position) {
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
  }

  @override
  Future<void> init() async {
    isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    await stop();
    isDisposed = true;
    await _positionController.close();
  }

  @override
  Future<void> startLoop(AudioBuffer buffer) async {
    await init();
    if (_isPlaying) {
      await stop();
    }
    _isPlaying = true;
    startLoopCalls++;
    startedBuffers.add(buffer);
    audibleBuffer = buffer;
    pendingBuffer = null;
  }

  @override
  Future<void> swapLoopAtBoundary(AudioBuffer nextBuffer) async {
    if (!_isPlaying) {
      await startLoop(nextBuffer);
      return;
    }
    swapLoopCalls++;
    swappedBuffers.add(nextBuffer);
    // Latest swap wins: replaces any previously pending buffer.
    // The currently audible loop continues unaffected until the boundary.
    pendingBuffer = nextBuffer;
  }

  /// Simulates reaching the next loop boundary, promoting [pendingBuffer]
  /// to [audibleBuffer].
  void triggerBoundary() {
    if (!_isPlaying) return;
    if (pendingBuffer != null) {
      audibleBuffer = pendingBuffer;
      pendingBuffer = null;
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    stopCalls++;
    audibleBuffer = null;
    pendingBuffer = null;
  }
}
