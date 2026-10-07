# AGENTS.md

## Operational Pitfalls & Gotchas

- Dart package name is `rhythm_box`; repo dir `flutter-rhythm-box` is not a valid package name. Re-run `flutter create` only with `--project-name rhythm_box --platforms=android,linux`.
- `flutter pub add` takes ~20s (flutter_soloud pulls native build hooks). Wait for it to finish before `flutter build`, otherwise: `ERROR: File modified during build. Build must be rerun.`
- In `run_command`, wrap `bash -c` scripts in single quotes. Double quotes expand `$d`/`$?` before bash runs (empty `mkdir` operands).
- Git does not track empty dirs; keep `.gitkeep` in placeholder folders (`lib/domain|synth|audio|ui`, `tools/`).
- Python scripts in `tools/`: invoke as `python3 tools/<script>.py` or set `PYTHONPATH=tools`; `test_analyze_timing.py` handles `sys.path`.
- When testing throwaways with `flutter build linux --debug -t lib/<tmp>.dart`, re-run `flutter build linux --debug` afterward so the bundle binary in `build/.../rhythm_box` restores `lib/main.dart`.
- `SoLoud.instance.loadMem` requires encoded audio container bytes (e.g. 44-byte RIFF/WAVE header + 16-bit PCM), not raw unheadered PCM.
- Boundary swap via SoLoud engine clock: do NOT compute boundary from `getPosition(handle)` + `getEngineTime()`; `getPosition` updates on buffer block chunks and lags by several milliseconds, introducing up to 15 ms swap jitter. Instead, anchor playback start to the engine clock (`anchor = getEngineTime() + lead`), start with `playScheduled(source, anchor)`, and compute boundary strictly as integer multiples on the anchor timeline (`anchor + ceil((now - anchor + lead)/dur) * dur`), then re-anchor.
- Immediate `stop()` during scheduled boundary swap: store `_previousHandle = _currentHandle` when scheduling a swap and stop both handles in `stop()`, otherwise the retiring handle plays until the boundary. Clear `_currentLoopAnchorEngineTime = null` on stop.
- Successive rapid swaps before loop boundary: cancel the pending scheduled handle and dispose only the pending source immediately (latest-wins); keep the boundary strictly anchored to the audible loop clock. Never dispose the active audible source until its boundary arrives.
- Headless `flutter test` cannot invoke native SoLoud FFI: keep `AudioEngine` abstracted behind an interface and inject a fake/mock via Riverpod override (`audioEngineProvider.overrideWithValue(...)`).
- Direct audio capture on Linux: record app playback without cables by starting unlinked with a latency buffer (`pw-record --latency 250ms --target 0 <out.wav>`), then link to the active sink monitor (`pw-link <sink_node_name>:monitor_FL pw-record:input_FL` and `FR`). Passing node ID/name directly to `--target` often mislinks to microphone inputs, and omitting `--latency` causes 32 ms (1536 samples) PipeWire recording xruns during desktop activity. For emulator capture, link directly with `pw-link qemu-system-x86_64:output_FL pw-record:input_FL` (and `FR`).
- Android toolchain & emulator: `adb` resides at `/home/fuchik0ma/Android/Sdk/platform-tools/adb` (not in system PATH). `flutter run -d <id>` only connects to running devices; launch stopped emulators first with `flutter emulators --launch <id>`. Set media volume via `adb shell cmd media_session volume --stream 3 --set 15` (`STREAM_MUSIC`).
- Widget tests on scrollable views: default test canvas is 800x600; tapping elements below 600px fails hit-testing unless resized (`tester.view.physicalSize = const Size(1200, 1600)` + `addTearDown(tester.view.resetPhysicalSize)`) or navigated with `tester.ensureVisible`.
- OpenSpec validation CLI: bare `openspec validate` prompts interactively and hangs subshells; always invoke with `--all` or `--no-interactive` (e.g. `openspec validate --all`).
- `dart:math` lacks hyperbolic functions (`tanh`): implement soft-clipping manually via $(e^{2x} - 1)/(e^{2x} + 1)$ and guard $|x| > 20$ returning $\pm 1.0$ to prevent `exp` overflow.
- Audio test peak tolerances on discrete sinusoids: discrete sampling at 44.1 kHz rarely strikes the exact continuous peak (e.g. 1 kHz sine sample peak is ~0.983); avoid over-tight assertions like `closeTo(1.0, 0.01)` and use `> 0.95`.
- DTD hot reload error `-32603`: opaque VM service `-32603` error almost always indicates a compile/analyzer error (e.g. missing import or changing a `const` constructor); run `flutter analyze` immediately to reveal the exact issue.
- Riverpod Notifier reactive swaps: do NOT use `ref.watch` inside a playback controller's `build()` to react to external state (like tempo or settings); `ref.watch` causes `build()` to re-execute and resets controller state (e.g. `isPlaying: false`). Use `ref.listen` inside `build()` to react to changes and trigger boundary swaps while preserving playback state.
- `MetronomeSettings` constructor is non-`const` (clamps ranges in constructor body); calling `const MetronomeSettings(...)` fails analyzer with `const_with_non_const`.

## Verification Commands

- Spec validation: `openspec validate --all`
- Static check: `flutter analyze`
- Unit and widget tests: `flutter test`
- Linux build: `flutter build linux --debug`; binary: `build/linux/x64/debug/bundle/rhythm_box`
- Linux CLI playback checks: `<binary> sequencer <sec>`, `<binary> metronome <sec>`, or `<binary> swap <swapSec> <totalSec>`
- Android release build: `flutter build apk --release`; APK: `build/app/outputs/flutter-apk/app-release.apk`
- Full Linux 5-minute benchmark: `python3 tools/run_full_benchmarks_linux.py`; outputs to `recordings/`
- Android swap benchmark on emulator: `python3 tools/run_swap_benchmark_android.py`; outputs to `recordings/`
- Headless launch check: `timeout 8 <binary>`; exit 124 = ran until killed (OK).
- Throwaway runtime check (e.g. soloud init): temp `lib/*_tmp.dart` with `main()` that prints a marker then `exit(0)`; run `flutter build linux --debug -t lib/<file>.dart`, run binary, grep marker, delete the file.
- Timing analyzer test: `python3 tools/test_analyze_timing.py` or `python3 tools/analyze_timing.py --self-test`
- Timing analysis on WAV: `python3 tools/analyze_timing.py <recording.wav> --bpm 120 [--steps-per-beat 4] [--swap-time <sec>] [--json]`; exit code 0 = passed criteria, 2 = failed.

