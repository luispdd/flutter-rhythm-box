# AGENTS.md

## Operational Pitfalls & Gotchas

- Dart package name is `rhythm_box`; repo dir `flutter-rhythm-box` is not a valid package name. Re-run `flutter create` only with `--project-name rhythm_box --platforms=android,linux`.
- `flutter pub add` takes ~20s (flutter_soloud pulls native build hooks). Wait for it to finish before `flutter build`, otherwise: `ERROR: File modified during build. Build must be rerun.`
- In `run_command`, wrap `bash -c` scripts in single quotes. Double quotes expand `$d`/`$?` before bash runs (empty `mkdir` operands).
- Git does not track empty dirs; keep `.gitkeep` in placeholder folders (`lib/domain|synth|audio|ui`, `tools/`).
- Python scripts in `tools/`: invoke as `python3 tools/<script>.py` or set `PYTHONPATH=tools`; `test_analyze_timing.py` handles `sys.path`.
- When testing throwaways with `flutter build linux --debug -t lib/<tmp>.dart`, re-run `flutter build linux --debug` afterward so the bundle binary in `build/.../rhythm_box` restores `lib/main.dart`.
- `SoLoud.instance.loadMem` requires encoded audio container bytes (e.g. 44-byte RIFF/WAVE header + 16-bit PCM), not raw unheadered PCM.
- Boundary swap via SoLoud engine clock: compute boundary from `getEngineTime()` + remaining loop duration (use `inMicroseconds`, as Dart `Duration` lacks `%`), then pass the identical engine `Duration` to both `stopScheduled(oldHandle, boundary)` and `playScheduled(newSource, boundary, looping: true)`.
- Immediate `stop()` during scheduled boundary swap: store `_previousHandle = _currentHandle` when scheduling a swap and stop both handles in `stop()`, otherwise the retiring handle plays until the boundary.
- Headless `flutter test` cannot invoke native SoLoud FFI: keep `AudioEngine` abstracted behind an interface and inject a fake/mock via Riverpod override (`audioEngineProvider.overrideWithValue(...)`).
- Widget tests on scrollable views: default test canvas is 800x600; tapping elements below 600px fails hit-testing unless resized (`tester.view.physicalSize = const Size(1200, 1600)` + `addTearDown(tester.view.resetPhysicalSize)`) or navigated with `tester.ensureVisible`.
- OpenSpec validation CLI: bare `openspec validate` prompts interactively and hangs subshells; always invoke with `--all` or `--no-interactive` (e.g. `openspec validate --all`).

## Verification Commands

- Spec validation: `openspec validate --all`
- Static check: `flutter analyze`
- Unit and widget tests: `flutter test`
- Linux build: `flutter build linux --debug`; binary: `build/linux/x64/debug/bundle/rhythm_box`
- Headless launch check: `timeout 8 <binary>`; exit 124 = ran until killed (OK).
- Throwaway runtime check (e.g. soloud init): temp `lib/*_tmp.dart` with `main()` that prints a marker then `exit(0)`; run `flutter build linux --debug -t lib/<file>.dart`, run binary, grep marker, delete the file.
- Timing analyzer test: `python3 tools/test_analyze_timing.py` or `python3 tools/analyze_timing.py --self-test`
- Timing analysis on WAV: `python3 tools/analyze_timing.py <recording.wav> --bpm 120 [--steps-per-beat 4] [--swap-time <sec>] [--json]`; exit code 0 = passed criteria, 2 = failed.

