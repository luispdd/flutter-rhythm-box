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

  AudioSource? _audibleSource;
  SoundHandle? _audibleHandle;
  AudioBuffer? _audibleBuffer;
  Duration? _audibleAnchorTime;

  AudioSource? _pendingSource;
  SoundHandle? _pendingHandle;
  AudioBuffer? _pendingBuffer;
  Duration? _pendingBoundaryTime;

  AudioSource? _retiringAudibleSource;

  bool _isInitialized = false;
  bool _isPlaying = false;

  Future<void>? _activeOperation;

  Timer? _positionTimer;
  final StreamController<Duration> _positionStreamController =
      StreamController<Duration>.broadcast();

  SoLoudAudioEngine({SoLoud? soloud}) : _soloud = soloud ?? SoLoud.instance;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<Duration> get positionStream => _positionStreamController.stream;

  Future<T> _enqueueOperation<T>(Future<T> Function() operation) async {
    final previousOperation = _activeOperation;
    final completer = Completer<void>();
    _activeOperation = completer.future;

    if (previousOperation != null) {
      try {
        await previousOperation;
      } catch (_) {}
    }

    try {
      return await operation();
    } finally {
      completer.complete();
      if (_activeOperation == completer.future) {
        _activeOperation = null;
      }
    }
  }

  @override
  Future<void> init() => _enqueueOperation(_initInternal);

  Future<void> _initInternal() async {
    if (_isInitialized) return;
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }
    _isInitialized = true;
  }

  @override
  Future<void> dispose() => _enqueueOperation(_disposeInternal);

  Future<void> _disposeInternal() async {
    await _stopInternal();
    _positionTimer?.cancel();
    await _positionStreamController.close();
    if (_isInitialized) {
      _soloud.deinit();
      _isInitialized = false;
    }
  }

  @override
  Future<void> startLoop(AudioBuffer buffer) => _enqueueOperation(() => _startLoopInternal(buffer));

  Future<void> _startLoopInternal(AudioBuffer buffer) async {
    await _initInternal();

    if (_isPlaying) {
      await _stopInternal();
    }

    final soundId = 'loop_${_bufferCounter++}';
    final source = await _soloud.loadMem(soundId, buffer.wavBytes);

    // Anchor start to engine clock with a small lead margin (20 ms)
    final startTime = _soloud.getEngineTime() + const Duration(milliseconds: 20);
    final handle = _soloud.playScheduled(source, startTime, looping: true);

    _audibleAnchorTime = startTime;
    _audibleSource = source;
    _audibleHandle = handle;
    _audibleBuffer = buffer;
    _isPlaying = true;

    _startPositionReporting();
  }

  Future<void> _promotePendingIfBoundaryPassed() async {
    final pendingBoundary = _pendingBoundaryTime;
    if (pendingBoundary != null && _soloud.getEngineTime() >= pendingBoundary) {
      if (_retiringAudibleSource != null) {
        try {
          await _soloud.disposeSource(_retiringAudibleSource!);
        } catch (_) {}
        _retiringAudibleSource = null;
      }
      _audibleSource = _pendingSource;
      _audibleHandle = _pendingHandle;
      _audibleBuffer = _pendingBuffer;
      _audibleAnchorTime = pendingBoundary;

      _pendingSource = null;
      _pendingHandle = null;
      _pendingBuffer = null;
      _pendingBoundaryTime = null;
    }
  }

  @override
  Future<void> swapLoopAtBoundary(AudioBuffer nextBuffer) => _enqueueOperation(() => _swapLoopAtBoundaryInternal(nextBuffer));

  Future<void> _swapLoopAtBoundaryInternal(AudioBuffer nextBuffer) async {
    if (!_isPlaying ||
        _audibleHandle == null ||
        _audibleBuffer == null ||
        _audibleAnchorTime == null) {
      await _startLoopInternal(nextBuffer);
      return;
    }

    // Check if the previous pending boundary already passed
    await _promotePendingIfBoundaryPassed();

    final now = _soloud.getEngineTime();
    const leadMarginUs = 30000; // 30 ms lead time

    // If a swap is already pending before its boundary, cancel it immediately.
    // Latest swap wins: intermediate pending buffers are never heard.
    // The currently audible loop continues uninterrupted until the boundary.
    if (_pendingHandle != null) {
      try {
        await _soloud.stop(_pendingHandle!);
      } catch (_) {}
      _pendingHandle = null;
    }
    if (_pendingSource != null) {
      try {
        await _soloud.disposeSource(_pendingSource!);
      } catch (_) {}
      _pendingSource = null;
    }

    final nextSoundId = 'loop_${_bufferCounter++}';
    final nextSource = await _soloud.loadMem(nextSoundId, nextBuffer.wavBytes);

    Duration boundaryEngineTime;
    if (_pendingBoundaryTime != null &&
        (_pendingBoundaryTime! - now).inMicroseconds >= leadMarginUs) {
      // Reuse the established boundary time for the current cycle
      boundaryEngineTime = _pendingBoundaryTime!;
    } else {
      // Compute boundary strictly from the audible loop's anchor timeline
      final elapsedUs = (now - _audibleAnchorTime!).inMicroseconds;
      final loopDurUs = _audibleBuffer!.duration.inMicroseconds;
      final cycles = ((elapsedUs + leadMarginUs) / loopDurUs).ceil();
      boundaryEngineTime =
          _audibleAnchorTime! + Duration(microseconds: cycles * loopDurUs);

      // Stop audible handle at the boundary
      _soloud.stopScheduled(_audibleHandle!, boundaryEngineTime);
      _retiringAudibleSource = _audibleSource;
    }

    // Schedule next handle to play cleanly at boundaryEngineTime
    final nextHandle = _soloud.playScheduled(
      nextSource,
      boundaryEngineTime,
      looping: true,
    );

    _pendingSource = nextSource;
    _pendingHandle = nextHandle;
    _pendingBuffer = nextBuffer;
    _pendingBoundaryTime = boundaryEngineTime;
  }

  @override
  Future<void> stop() => _enqueueOperation(_stopInternal);

  Future<void> _stopInternal() async {
    _positionTimer?.cancel();
    _positionTimer = null;

    if (_audibleHandle != null) {
      try {
        await _soloud.stop(_audibleHandle!);
      } catch (_) {}
      _audibleHandle = null;
    }

    if (_pendingHandle != null) {
      try {
        await _soloud.stop(_pendingHandle!);
      } catch (_) {}
      _pendingHandle = null;
    }

    final sourcesToDispose = <AudioSource>{
      ?_audibleSource,
      ?_retiringAudibleSource,
      ?_pendingSource,
    };
    for (final src in sourcesToDispose) {
      try {
        await _soloud.disposeSource(src);
      } catch (_) {}
    }

    _audibleSource = null;
    _retiringAudibleSource = null;
    _pendingSource = null;

    _audibleBuffer = null;
    _audibleAnchorTime = null;
    _pendingBuffer = null;
    _pendingBoundaryTime = null;
    _isPlaying = false;
  }

  void _startPositionReporting() {
    _positionTimer?.cancel();
    // Position reporting is solely for visual/diagnostic feedback.
    // It never triggers sound generation or audio events.
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isPlaying) return;
      unawaited(_promotePendingIfBoundaryPassed());
      final handle = _audibleHandle;
      if (handle == null) return;
      try {
        final pos = _soloud.getPosition(handle);
        if (!_positionStreamController.isClosed) {
          _positionStreamController.add(pos);
        }
      } catch (_) {}
    });
  }
}
