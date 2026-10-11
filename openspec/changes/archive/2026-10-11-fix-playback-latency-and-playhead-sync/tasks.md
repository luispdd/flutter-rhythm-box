## 1. Audio Engine Keep-Alive and Startup Pre-roll

- [x] 1.1 Configure `setAudioDeviceIdleTimeout(null)` in `SoLoudAudioEngine._initInternal` to keep the audio output active in the foreground, and increase cold-start lead margin in `startLoop` to 60 ms. Verify with `flutter analyze`.
- [x] 1.2 Verify engine start and dispose lifecycle behavior with unit tests in `test/audio/`.

## 2. Master-Engine-Clock Position Stream

- [x] 2.1 Refactor `SoLoudAudioEngine._startPositionReporting` to compute position directly from master engine time and audible loop anchor `(_soloud.getEngineTime() - _audibleAnchorTime) % loopDur` rather than polling voice handles. Verify with `flutter analyze`.
- [x] 2.2 Verify that `positionStream` maintains monotonic continuity and does not reset to zero or freeze across scheduled buffer swaps during playback.

## 3. Sequencer Live Edit Scheduling & Persistence

- [x] 3.1 In `SequencerController._updatePattern`, dispatch `saveWorkingPattern` asynchronously in the background (`unawaited`) with error logging so disk I/O does not delay `_restartPlayback`. Verify with `test/ui/sequencer_controller_test.dart`.
- [x] 3.2 In `SoLoudAudioEngine._swapLoopAtBoundaryInternal`, sample engine clock time `now` after `loadMem` finishes to prevent boundary margin exhaustion. Verify with `flutter analyze`.

## 4. End-to-End Validation

- [x] 4.1 Run full project static analysis (`flutter analyze`) and test suite (`flutter test`) to verify regressions and test suite integrity.
- [x] 4.2 Validate OpenSpec change compliance using `openspec validate --all`.
