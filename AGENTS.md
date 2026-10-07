# AGENTS.md

## Operational Pitfalls & Gotchas

- Dart package name is `rhythm_box`; repo dir `flutter-rhythm-box` is not a valid package name. Re-run `flutter create` only with `--project-name rhythm_box --platforms=android,linux`.
- `flutter pub add` takes ~20s (flutter_soloud pulls native build hooks). Wait for it to finish before `flutter build`, otherwise: `ERROR: File modified during build. Build must be rerun.`
- In `run_command`, wrap `bash -c` scripts in single quotes. Double quotes expand `$d`/`$?` before bash runs (empty `mkdir` operands).
- Git does not track empty dirs; keep `.gitkeep` in placeholder folders (`lib/domain|synth|audio|ui`, `tools/`).

## Verification Commands

- Static check: `flutter analyze`
- Linux build: `flutter build linux --debug`; binary: `build/linux/x64/debug/bundle/rhythm_box`
- Headless launch check: `timeout 8 <binary>`; exit 124 = ran until killed (OK).
- Throwaway runtime check (e.g. soloud init): temp `lib/*_tmp.dart` with `main()` that prints a marker then `exit(0)`; run `flutter build linux --debug -t lib/<file>.dart`, run binary, grep marker, delete the file.
