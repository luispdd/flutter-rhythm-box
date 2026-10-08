## 1. Persistence & Data Resilience

- [x] 1.1 Update `Pattern`, `Sequence` (if implemented), and `MetronomeSettings` models to serialize/deserialize a `schemaVersion` field (defaulting to 1). Verify via unit tests that missing fields map to version 1.
- [x] 1.2 Modify `SharedPreferencesSettingsStore` to wrap all JSON decoding in `try/catch`. If parsing fails, it should log the error and return a default/empty state instead of throwing. Verify via a unit test with corrupt JSON strings.
- [x] 1.3 Add a generic error state to `SettingsStore` or expose exceptions to Riverpod notifiers, so UI can show a `SnackBar` if saving fails. Verify manually by forcing a write error.
- [x] 1.4 Update the `HomeTabController` (or similar navigation state) to save and restore the last selected tab index. Verify manually by changing tabs and restarting the app.

## 2. Audio Engine Lifecycle

- [x] 2.1 Update `main.dart` (or create a top-level `LifecycleManager` widget) to implement `WidgetsBindingObserver`. Override `didChangeAppLifecycleState` to call `AudioEngine.dispose()` when the state is `detached`. Verify on Linux/Android that resources are released cleanly on close.
- [x] 2.2 Wrap `SoLoud` initialization in a `try/catch` block. If it fails, bubble the error up to the UI to show a clear warning message rather than a silent failure. Verify by temporarily forcing an init failure.

## 3. UI Polish

- [x] 3.1 Update the `PatternLibraryScreen` (and Sequence screen if implemented) to display a friendly "No patterns yet" message when the list is empty. Verify visually.
- [x] 3.2 Add a confirmation dialog to the "Clear" button in the `SequencerScreen` to prevent accidental loss of the working pattern. Verify visually.

## 4. Build Configuration & Documentation

- [x] 4.1 Update Android build files (`android/app/build.gradle` and `AndroidManifest.xml`) to set the `applicationId` to `com.example.rhythmbox` and the application label to "Rhythm amigo". Set `minSdk` and `targetSdk` appropriately (e.g. 21 and 34). Verify by building the APK.
- [x] 4.2 Add a basic launcher icon for Android (replace the default Flutter logo with a simple colored square or text icon if possible, or leave as default but rename to "Rhythm amigo"). Verify visually on an Android device/emulator.
- [x] 4.3 Create a `README.md` in the project root. Include instructions on what the app is, how to build/run it on Android and Linux, and how to run the Python timing analysis script. Verify the markdown renders correctly.
