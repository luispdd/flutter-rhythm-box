import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../domain/audio_buffer.dart';
import 'audio_engine.dart';

/// Implementation of [AudioEngine] using `flutter_soloud`.
///
/// Implements Candidate 1 from Design D3:
/// - Loop a single handle (`looping: true`).
/// - Swap by scheduling the new buffer to start at the old loop's end
///   using the engine's own clock (`stopScheduled` & `playScheduled`).
/// - Audio timing is strictly driven by SoLoud's internal mixer clock;
///   no Dart timers trigger sound onsets.
class SoLoudAudioEngine implements AudioEngine {
  final SoLoud _soloud;
  int _bufferCounter = 0;

  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  SoundHandle? _previousHandle;
  AudioBuffer? _currentBuffer;

  AudioSource? _pendingRetireSource;

  bool _isInitialized = false;
  bool _isPlaying = false;

  Timer? _positionTimer;
  final StreamController<Duration> _positionStreamController =
      StreamController<Duration>.broadcast();

  SoLoudAudioEngine({SoLoud? soloud}) : _soloud = soloud ?? SoLoud.instance;

  Duration? _currentLoopAnchorEngineTime;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<Duration> get positionStream => _positionStreamController.stream;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    await stop();
    _positionTimer?.cancel();
    await _positionStreamController.close();
    if (_isInitialized) {
      _soloud.deinit();
      _isInitialized = false;
    }
  }

  @override
  Future<void> startLoop(AudioBuffer buffer) async {
    await init();

    if (_isPlaying) {
      await stop();
    }

    final soundId = 'loop_${_bufferCounter++}';
    final source = await _soloud.loadMem(soundId, buffer.wavBytes);

    // Anchor start to engine clock with a small lead margin (20 ms)
    final startTime = _soloud.getEngineTime() + const Duration(milliseconds: 20);
    final handle = _soloud.playScheduled(source, startTime, looping: true);

    _currentLoopAnchorEngineTime = startTime;
    _currentSource = source;
    _currentHandle = handle;
    _currentBuffer = buffer;
    _isPlaying = true;

    _startPositionReporting();
  }

  @override
  Future<void> swapLoopAtBoundary(AudioBuffer nextBuffer) async {
    if (!_isPlaying || _currentHandle == null || _currentBuffer == null || _currentLoopAnchorEngineTime == null) {
      await startLoop(nextBuffer);
      return;
    }

    final nextSoundId = 'loop_${_bufferCounter++}';
    final nextSource = await _soloud.loadMem(nextSoundId, nextBuffer.wavBytes);

    // Compute boundary strictly on SoLoud's engine clock anchor
    final now = _soloud.getEngineTime();
    final elapsedUs = (now - _currentLoopAnchorEngineTime!).inMicroseconds;
    final loopDurUs = _currentBuffer!.duration.inMicroseconds;

    // Determine the next integer loop cycle with at least 30 ms lead time
    const leadMarginUs = 30000;
    final cycles = ((elapsedUs + leadMarginUs) / loopDurUs).ceil();
    final boundaryEngineTime =
        _currentLoopAnchorEngineTime! + Duration(microseconds: cycles * loopDurUs);

    // Stop current handle sample-accurately at boundaryEngineTime
    _soloud.stopScheduled(_currentHandle!, boundaryEngineTime);

    // Start next handle sample-accurately at boundaryEngineTime
    final nextHandle = _soloud.playScheduled(
      nextSource,
      boundaryEngineTime,
      looping: true,
    );

    // Update anchor to the new boundary
    _currentLoopAnchorEngineTime = boundaryEngineTime;

    // Retire old audio source
    if (_pendingRetireSource != null) {
      try {
        await _soloud.disposeSource(_pendingRetireSource!);
      } catch (_) {}
    }
    _pendingRetireSource = _currentSource;

    _previousHandle = _currentHandle;
    _currentSource = nextSource;
    _currentHandle = nextHandle;
    _currentBuffer = nextBuffer;
  }

  @override
  Future<void> stop() async {
    _positionTimer?.cancel();
    _positionTimer = null;

    if (_currentHandle != null) {
      try {
        await _soloud.stop(_currentHandle!);
      } catch (_) {}
      _currentHandle = null;
    }

    if (_previousHandle != null) {
      try {
        await _soloud.stop(_previousHandle!);
      } catch (_) {}
      _previousHandle = null;
    }

    if (_currentSource != null) {
      try {
        await _soloud.disposeSource(_currentSource!);
      } catch (_) {}
      _currentSource = null;
    }

    if (_pendingRetireSource != null) {
      try {
        await _soloud.disposeSource(_pendingRetireSource!);
      } catch (_) {}
      _pendingRetireSource = null;
    }

    _currentBuffer = null;
    _currentLoopAnchorEngineTime = null;
    _isPlaying = false;
  }

  void _startPositionReporting() {
    _positionTimer?.cancel();
    // Position reporting is solely for visual/diagnostic feedback.
    // It never triggers sound generation or audio events.
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isPlaying || _currentHandle == null) return;
      try {
        final pos = _soloud.getPosition(_currentHandle!);
        if (!_positionStreamController.isClosed) {
          _positionStreamController.add(pos);
        }
      } catch (_) {}
    });
  }
}
