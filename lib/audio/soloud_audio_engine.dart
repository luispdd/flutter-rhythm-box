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
  AudioBuffer? _currentBuffer;

  AudioSource? _pendingRetireSource;

  bool _isInitialized = false;
  bool _isPlaying = false;

  Timer? _positionTimer;
  final StreamController<Duration> _positionStreamController =
      StreamController<Duration>.broadcast();

  SoLoudAudioEngine({SoLoud? soloud}) : _soloud = soloud ?? SoLoud.instance;

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
    final handle = _soloud.play(source, looping: true);

    _currentSource = source;
    _currentHandle = handle;
    _currentBuffer = buffer;
    _isPlaying = true;

    _startPositionReporting();
  }

  @override
  Future<void> swapLoopAtBoundary(AudioBuffer nextBuffer) async {
    if (!_isPlaying || _currentHandle == null || _currentBuffer == null) {
      await startLoop(nextBuffer);
      return;
    }

    final nextSoundId = 'loop_${_bufferCounter++}';
    final nextSource = await _soloud.loadMem(nextSoundId, nextBuffer.wavBytes);

    // Compute boundary on SoLoud's engine clock (Design Candidate 1)
    final now = _soloud.getEngineTime();
    final curPos = _soloud.getPosition(_currentHandle!);
    final loopDurUs = _currentBuffer!.duration.inMicroseconds;
    final curPosUs = curPos.inMicroseconds;

    var remainingUs = loopDurUs - (curPosUs % loopDurUs);
    // Provide a safe lead margin (30 ms) so the schedule call lands before the boundary
    if (remainingUs < 30000) {
      remainingUs += loopDurUs;
    }
    final boundaryEngineTime = now + Duration(microseconds: remainingUs);

    // Stop current handle sample-accurately at boundaryEngineTime
    _soloud.stopScheduled(_currentHandle!, boundaryEngineTime);

    // Start next handle sample-accurately at boundaryEngineTime
    final nextHandle = _soloud.playScheduled(
      nextSource,
      boundaryEngineTime,
      looping: true,
    );

    // Retire old audio source
    if (_pendingRetireSource != null) {
      try {
        await _soloud.disposeSource(_pendingRetireSource!);
      } catch (_) {}
    }
    _pendingRetireSource = _currentSource;

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
