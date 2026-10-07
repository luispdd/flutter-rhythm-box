## Why

The whole project depends on one assumption: a pre-rendered PCM loop played by `flutter_soloud`, with buffers swapped at the loop boundary, is steady enough for practice (no Dart timers involved). Nothing else should be built until this is measured on a real Android device and on Linux.

## What Changes

- Create the Flutter project (Android and Linux only) with `flutter_soloud` and Riverpod as dependencies.
- Build a minimal spike app with:
  - a 4-step, 16th-note pattern looping at 120 BPM on a single voice (one hit every 125 ms),
  - a metronome loop at 120 BPM (one click every 500 ms),
  - a swap to a different tempo/pattern at the loop boundary while playing.
- Add `tools/analyze_timing.py`: reads a WAV recording, detects onsets, and reports inter-onset interval mean, standard deviation, maximum deviation from nominal, and cumulative drift.
- Run 5-minute recordings on a real Android device and on Linux, and report the numbers with a pass/fail statement.
- Document the chosen looping and swapping mechanism and why, in `design.md`.

## Capabilities

### New Capabilities
- `loop-timing`: measurable timing guarantees for gapless looped playback and boundary swapping, plus the analysis tool that verifies them.

### Modified Capabilities
<!-- None: no existing specs. -->

## Non-goals

- Production UI, persistence, pattern saving, settings, or the full 8-voice ladder.
- Web support.
- Screen-off playback (deferred to M6).
- A native (Rust/Oboe) engine or any timer-based scheduler as a workaround. If the criteria fail, stop and report the measured numbers.

## Impact

- New: Flutter project scaffold (`android/`, `linux/`, `lib/`, `pubspec.yaml`), `tools/analyze_timing.py`.
- Dependencies: `flutter_soloud`, `flutter_riverpod`.
- Gates all later milestones (M1 to M6).
