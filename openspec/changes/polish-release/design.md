## Context

See proposal.md - Why. With the core features functional, we need to add robust error handling, UI polish, and state restoration to prepare the app for release.

## Goals / Non-Goals

**Goals:**
- Implement global error handling for file I/O and JSON parsing without crashing.
- Add `schemaVersion` to all persistent JSON models.
- Persist UI state (last selected tab) across sessions.
- Implement a `WidgetsBindingObserver` to manage audio engine lifecycle on app shutdown.
- Configure Android and Linux release build settings.

**Non-Goals:**
- Background audio playback (deferred to M7).
- Advanced automated error reporting (e.g., Crashlytics).

## Decisions

- **Error Handling Strategy**: File I/O operations in `SharedPreferencesSettingsStore` will be wrapped in `try/catch` blocks. The methods will return nullable or default values on read failure, and Riverpod notifiers will capture exceptions to expose error states (e.g., via a `ScaffoldMessenger` Key) for UI display.
- **Data Versioning**: A `schemaVersion` (default 1) will be added to the JSON serialization of `Pattern`, `Sequence`, and `MetronomeSettings`. This will allow future changes to the data format to be migrated safely.
- **Lifecycle Management**: A top-level widget (e.g., `LifecycleManager`) will implement `WidgetsBindingObserver` and listen to `AppLifecycleState.detached` to invoke `AudioEngine.dispose()`.
- **Release Configuration**: We will set the `applicationId` to `com.example.rhythmbox` (default/placeholder) and app name to "Rhythm amigo". We will skip the local keystore generation as requested by the user, relying on the default signing setup.

## Risks / Trade-offs

- **[Risk] State Loss on Corrupt Files** → If `settings.json` is partially corrupt, `jsonDecode` will fail.
  - **Mitigation**: We currently store everything in a single string in SharedPreferences. If parsing fails, the entire settings block might be lost. We will catch the `FormatException` and avoid overwriting the corrupt data on the next save if possible, but the primary mitigation is showing a UI warning.
- **[Risk] Lifecycle Events on Desktop** → Flutter's desktop lifecycle events can sometimes behave differently than mobile.
  - **Mitigation**: Test the `AppLifecycleState.detached` event explicitly on the Linux build to ensure audio resources are released.
