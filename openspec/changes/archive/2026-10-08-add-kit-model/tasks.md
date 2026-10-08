## 1. Golden Baseline

- [x] 1.1 Create pre-refactor golden test capturing rendered audio hashes for default patterns at 60, 120, and 180 BPM; verify with `flutter test test/synth/golden_regression_test.dart`.

## 2. Domain Models & Sound Kit Assets

- [x] 2.1 Extend `Waveform` (`pulse`, `lfsrNoise`), add `PitchSteps` model, and add optional voice parameters to `Voice` (`label`, `dutyCycle`, `lfsrClockHz`, `lfsrShort`, `pitchSteps`, `bitDepth`, `downsampleHz`); verify with `flutter test test/domain/voice_test.dart`.
- [x] 2.2 Implement `Kit` domain model with JSON serialization and strict validation (exactly 8 voices, parameter bounds clamping/rejection); verify with `flutter test test/domain/kit_test.dart`.
- [x] 2.3 Create `assets/kits/classic-synth.json`, register `assets/kits/` in `pubspec.yaml`, and implement `KitRepository` abstraction; verify with `flutter test test/persistence/kit_repository_test.dart`.

## 3. Synth Renderer DSP Extensions

- [x] 3.1 Implement pulse oscillator in `VoiceRenderer` supporting `dutyCycle` (0.05–0.95); verify duty cycle ratio and click-free attack with `flutter test test/synth/voice_renderer_test.dart`.
- [x] 3.2 Implement NES 15-bit LFSR noise in `VoiceRenderer` with long (15-bit) and short (93-step periodic) modes; verify deterministic output and periodicity with `flutter test test/synth/voice_renderer_test.dart`.
- [x] 3.3 Implement `pitchSteps` stepped frequency modulation in `VoiceRenderer` holding final pitch on completion; verify semitone frequency steps with `flutter test test/synth/voice_renderer_test.dart`.
- [x] 3.4 Implement downsampling and bit crush quantization before filtering in `VoiceRenderer`; verify discrete level count and filtered quantization noise with `flutter test test/synth/voice_renderer_test.dart`.
- [x] 3.5 Implement kit-aware deterministic noise seeding in `VoiceRenderer` and verify sample-for-sample regression equivalence against pre-refactor baseline with `flutter test test/synth/golden_regression_test.dart`.

## 4. Verification & Integration

- [x] 4.1 Integrate `Kit` and `KitRepository` with `PatternRenderer` and verify full test suite with `flutter test` and static analysis with `flutter analyze`.
