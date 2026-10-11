## Context

Current playback and edit synchronization has three interrelated friction points (see `proposal.md`):
1. First playback after idle suffers from dropped initial sound onsets on external audio sinks (like HDMI).
2. Toggling steps during playback frequently misses the immediate next loop boundary and takes 2 full loop cycles to be heard.
3. The step playhead tick becomes erratic or resets to step 0 during live step edits.

Existing constraints:
- All audio timing must remain strictly on the audio engine side (no Dart timer audio scheduling).
- `AudioEngine` must remain testable headlessly via Riverpod overrides.
- Swaps must remain gapless and click-free.

## Goals / Non-Goals

**Goals:**
- Zero dropped onsets on first playback after idle.
- Live pattern edits reliably schedule and apply at the immediate next loop boundary (cycle 1).
- Step playhead advances smoothly and continuously across live edits without jumping, freezing, or drifting.

**Non-Goals:**
- Modifying intra-loop audio synthesis (sub-step swaps remain out of scope; swaps are quantized to loop boundaries).
- Background wakelock management when the app is minimized (handled by OS lifecycle).

## Decisions

### Decision 1: Keep audio hardware awake in foreground
- **Choice**: Call `_soloud.setAudioDeviceIdleTimeout(null)` upon engine initialization, and set initial start lead margin to 60 ms.
- **Rationale**: The default 500 ms idle timeout causes ALSA/PipeWire and HDMI sinks to sleep. When playback starts, the sink takes up to several hundred milliseconds to re-acquire clock sync, muting initial onsets. Keeping the device open eliminates wake-up latency.
- **Alternatives considered**: Calling `startAudioDevice()` only on play press (still incurs hardware sync delay and delays playback onset).

### Decision 2: Anchor position stream to master engine timeline
- **Choice**: Derive `positionStream` values in `SoLoudAudioEngine` from the master engine clock:
  ```dart
  final elapsedUs = (_soloud.getEngineTime() - _audibleAnchorTime!).inMicroseconds;
  final posUs = elapsedUs % loopDurUs;
  final pos = Duration(microseconds: posUs);
  ```
- **Rationale**: `_soloud.getPosition(handle)` queries the native voice instance, which updates in discrete buffer blocks (~46 ms) and becomes invalid or resets to 0 the moment `stopScheduled` retires the handle at the boundary. Computing position from the engine timeline anchor ensures seamless, continuous, monotonic position reporting through swaps.
- **Alternatives considered**: Polling `getIsValidVoiceHandle` and attempting to interpolate across voice handles (fragile and prone to race conditions).

### Decision 3: Decouple pattern persistence from swap scheduling
- **Choice**: In `SequencerController._updatePattern`, execute `store.saveWorkingPattern(newPattern)` asynchronously in the background (`unawaited(...)`) with error handling, immediately proceeding to `_restartPlayback(pattern: newPattern)`.
- **Rationale**: Awaiting storage I/O on the UI thread blocks the event loop before audio re-synthesis even begins. This artificial delay pushes the schedule timestamp past the boundary lead margin, forcing `ceil()` to skip to the 2nd cycle.
- **Alternatives considered**: Debouncing writes (unnecessary complexity since user tap intervals are already discrete and `SharedPreferences` writes are serialized).

### Decision 4: Sample engine time after buffer loading in swap path
- **Choice**: In `_swapLoopAtBoundaryInternal`, re-sample `now = _soloud.getEngineTime()` immediately prior to calculating `cycles` and `boundaryEngineTime`, rather than before `await _soloud.loadMem(...)`.
- **Rationale**: `loadMem` takes 10–25 ms to parse and allocate native memory. If `now` is sampled prior to `loadMem`, the lead margin `leadMarginUs` is depleted by load time, causing schedule calculations to either cut too close to the boundary or push into the subsequent cycle.

## Risks / Trade-offs

- **[Risk]** Unawaited `saveWorkingPattern` errors could fail silently.
  - **Mitigation**: Add `.catchError` handler to catch and report errors through `appErrorProvider` while allowing audio rendering to proceed unimpeded.
- **[Risk]** `setAudioDeviceIdleTimeout(null)` holds audio output resources while the app is foregrounded.
  - **Mitigation**: Normal app lifecycle already disposes / stops audio on application suspension or deinit.
