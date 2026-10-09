## 1. Dependencies and Core Storage

- [x] 1.1 Add `file_picker` package to `pubspec.yaml` and verify dependency installation succeeds via `flutter pub get`
- [x] 1.2 Add `replaceAll(List<Pattern> patterns, List<Sequence> sequences)` to `SettingsStore` interface and implement in `SharedPreferencesSettingsStore`, verified via unit tests in `test/persistence/settings_store_test.dart`

## 2. Library Envelope Model and Validation

- [x] 2.1 Create `LibraryData` envelope model in `lib/domain/library_data.dart` supporting serialization and deserialization, verified via unit tests in `test/domain/library_data_test.dart`
- [x] 2.2 Implement `LibraryValidator` in `lib/domain/library_validator.dart` checking format envelope, version, model constraints, duplicate IDs, and sequence referential integrity, verified via unit tests in `test/domain/library_validator_test.dart`

## 3. File Picker Abstraction and Import/Export Service

- [x] 3.1 Implement `FilePickerService` interface in `lib/services/file_picker_service.dart` wrapping `file_picker` with mockable methods for saving and picking files, verified via unit tests in `test/services/file_picker_service_test.dart`
- [x] 3.2 Implement `LibraryImportExportService` coordinating file selection, validation, stopping audio playback across controllers, replacing storage, and resetting active controllers, verified via unit tests in `test/services/library_import_export_service_test.dart`

## 4. UI Integration in Metronome Screen

- [x] 4.1 Add Export and Import actions to the `MetronomeScreen` AppBar, displaying "Nothing to export" for empty libraries or triggering file save for non-empty libraries, verified via widget tests in `test/ui/metronome_screen_test.dart`
- [x] 4.2 Add import confirmation dialog to `MetronomeScreen` displaying item counts, executing replacement and resetting Sequencer and Sequences controllers on confirmation, or canceling cleanly, verified via widget tests in `test/ui/metronome_screen_test.dart`

## 5. Documentation and Verification

- [x] 5.1 Update `README.md` with a section on moving libraries between devices, detailing export/import behavior and what is included, verified by reviewing documentation
- [x] 5.2 Run complete verification suite (`flutter analyze` and `flutter test`) to ensure zero regressions across audio timing and UI tests
