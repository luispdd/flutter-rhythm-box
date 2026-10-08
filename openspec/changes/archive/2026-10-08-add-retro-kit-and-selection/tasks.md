## 1. Sound Kit Asset and Repository Setup

- [x] 1.1 Create `assets/kits/retro-8bit.json` configured with the 8 chiptune voice configurations specified in SPEC-3 §9.1, and verify validity in `test/domain/kit_test.dart`.
- [x] 1.2 Update `AssetKitRepository` default asset paths to load `retro-8bit.json` alongside `classic-synth.json`, and verify discovery and silent fallback in `test/persistence/kit_repository_test.dart`.

## 2. Data Model Extensions

- [x] 2.1 Add `kitId` field to `Pattern` defaulting to `'classic-synth'`, and verify round-trip and backward compatibility without `kitId` in `test/domain/pattern_test.dart`.
- [x] 2.2 Add `kitId` field to `Sequence` defaulting to `'classic-synth'`, and verify round-trip and backward compatibility without `kitId` in `test/domain/sequence_test.dart`.

## 3. Audio Rendering and Controller Integration

- [x] 3.1 Update `SequencerController` to resolve the active `Kit` from `KitRepository` and support live loop boundary swapping when switching kits during playback, verifying in `test/ui/sequencer_controller_test.dart`.
- [x] 3.2 Update `SequenceController` and `PatternRenderer` to render all sequence entries using the sequence's configured `Kit`, overriding individual pattern kits, and verify in `test/synth/pattern_renderer_test.dart`.

## 4. User Interface and Kit Selection

- [x] 4.1 Update `StepGrid` and `StepPlayhead` to accept voice labels from the active kit and display them in track rows, verifying with widget tests in `test/ui/step_grid_test.dart`.
- [x] 4.2 Add the kit selector dropdown to the top AppBar of `SequencerScreen` (to the left of the Pattern Library icon), verifying UI selection and label updates in `test/ui/sequencer_screen_test.dart`.
- [x] 4.3 Add the kit selector dropdown to the top AppBar of `SequencesScreen` (to the left of the New Sequence icon), verifying sequence kit updates in `test/ui/sequences_screen_test.dart`.

## 5. End-to-End Verification and Benchmarks

- [x] 5.1 Run static analysis (`flutter analyze`) and test suite (`flutter test`) verifying zero failures.
- [x] 5.2 Perform CLI playback and swap checks (`flutter build linux --debug` and bundle checks) verifying seamless kit swapping at loop boundaries.
