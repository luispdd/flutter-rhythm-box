## 1. Project setup

- [x] 1.1 Run `flutter create` for platforms android and linux only; verify `flutter analyze` is clean and the default app launches on Linux
- [x] 1.2 Add `flutter_soloud` and `flutter_riverpod`; verify `flutter pub get` succeeds and a trivial soloud init runs on Linux
- [x] 1.3 Create the `lib/domain`, `lib/synth`, `lib/audio`, `lib/ui` and `tools/` folders; verify they exist and the app still builds

## 2. Timing measurement tool (before feature work)

- [x] 2.1 Write `tools/analyze_timing.py`: WAV in, onset detection, report of IOI mean, std, max deviation from nominal, and cumulative drift; verify with a synthetic WAV of known intervals (including a deliberately jittered one) that numbers match expectations
- [x] 2.2 Add a swap-boundary check (interval across a known swap time) and verify on a synthetic WAV

## 3. Renderer and engine

- [x] 3.1 Implement the minimal pure-Dart renderer (single click voice, `stepsPerBeat = 4`, rounding rule from design D2) and verify with a unit test that loop length and onset indices match for 120 BPM x 4 steps and for a fractional step length
- [x] 3.2 Define the `AudioEngine` interface (`startLoop`, `swapLoopAtBoundary`, `stop`, optional position stream) and verify it compiles with no Flutter or UI imports
- [x] 3.3 Implement it with `flutter_soloud` using candidate 1 from design D3; verify a looped buffer plays on Linux

## 4. Spike app

- [ ] 4.1 Build a minimal UI: sequencer start/stop, metronome start/stop, button to swap tempo/pattern; verify both loops play on Linux and swap while playing
- [ ] 4.2 Confirm by code search that no `Timer`, `Future.delayed` or periodic scheduler triggers any sound

## 5. Measurement and report

- [ ] 5.1 Record 5 minutes of each loop (sequencer and metronome) on Linux and run the analyzer; save the numbers
- [ ] 5.2 Build and run on a real Android device; record 5 minutes of each loop (speaker or wired headphones) and run the analyzer; save the numbers
- [ ] 5.3 Record a swap test on each platform and verify the boundary interval and that no click, gap or doubled hit is audible
- [ ] 5.4 If a candidate mechanism fails, try the next candidate from D3 and re-measure; if all fail, stop and report the numbers
- [ ] 5.5 Write the results (numbers, chosen mechanism and why, pass/fail per criterion) into `design.md` and report to the user
