# Rhythm Box — Specification, Phase 4: Library Export and Import

Continuation of the personal-use Rhythm Box project (Flutter + `flutter_soloud`, all-synth sounds, render-ahead looping).

**Goal:** move the whole library (all saved patterns and all saved sequences) from one device to another by exporting it to a file and importing that file elsewhere. **Import replaces everything**: the device's existing patterns and sequences are fully deleted and substituted by the file's content. There is no merging.

**Prerequisites:** the pattern library (first spec, milestone 4) and sequences (`SPEC-2.md`, milestone 5). If sound kits (`SPEC-3.md`) are already implemented, their fields (`kitId`) travel inside the exported patterns and sequences; nothing else in this spec depends on them.

Use this file as source material for OpenSpec: one change, suggested name `add-library-import-export`. Record non-trivial decisions in its `design.md`.

---

## 0. Ground rules

1. **Read before coding.** Read the existing code, OpenSpec specs and previous changes' `design.md` files. Reuse the existing layers (domain models and their JSON serialization, pattern and sequence stores, UI). Do not restructure working code unless a requirement here needs it.
2. The core timing principle is untouched by this feature. No audio code should change. Playback must simply be **stopped** before an import.
3. **Never lose data on a failed import (MUST).** The existing library must stay completely intact unless the new library is fully validated and fully written.
4. Prefer few dependencies. Ask before adding any large one. Keep file and UI logic out of the domain and renderer layers.

---

## 10. Milestone 10 — Export and import of the library

### 10.1 What is exported (MUST)
- All saved **patterns** and all saved **sequences**, in a single file.
- Pattern and sequence objects are written exactly as the app already stores them (same JSON, including each object's own `schemaVersion`, `id`, and any `kitId`), so ids and the references from sequences to patterns stay valid.
- **Not** exported: the global tempo, metronome settings, the sequencer's unsaved working pattern, last-used state, and kits (built-in kits come with the app).

### 10.2 File format (MUST)
A single UTF-8 JSON file with an envelope:

```json
{
  "format": "rhythm-box-library",
  "formatVersion": 1,
  "exportedAt": "2026-10-08T13:41:00Z",
  "appVersion": "1.0.0",
  "patterns": [ { "...": "pattern objects as stored by the app" } ],
  "sequences": [ { "...": "sequence objects as stored by the app" } ]
}
```

- Suggested default file name: `rhythm-box-library-YYYY-MM-DD.json`.
- `format` must equal `rhythm-box-library`. `formatVersion` is the version of the envelope; the importer must reject versions newer than it knows, with a message that the file comes from a newer version of the app.
- Keep the format human-readable (pretty-printed JSON is fine). Do not compress or encrypt.

### 10.3 Export behavior (MUST)
- Provide an **Export library** action in the library area of the UI (e.g. an overflow menu on the pattern library / sequence screens).
- On **Linux**: a save-file dialog, defaulting to the suggested file name.
- On **Android**: let the user choose where to save (system file picker / Storage Access Framework). *(SHOULD)* Also offer a **Share** action through the Android share sheet, so the file can be sent to another device through a messaging app, cloud drive, email, or Bluetooth.
- If the library is empty (no patterns and no sequences), show a message ("Nothing to export") instead of writing a file.
- On success show a short confirmation (including the number of patterns and sequences exported); on failure show a clear error and change nothing.
- Evaluate lightweight packages for file picking/saving and sharing (e.g. `file_picker`, `share_plus`) versus platform code, choose the lightest that works on both platforms, and note the reasoning in `design.md`.

### 10.4 Import behavior (MUST)
1. Provide an **Import library** action next to Export. Its label or help text must make clear that it **replaces everything**.
2. The user picks a file with a file picker (filter to JSON where possible).
3. **Validate the whole file first, before touching anything** (see 10.5). If validation fails, show a clear error and stop; existing data is unchanged.
4. Show a **confirmation dialog** stating the file's content ("N patterns and M sequences") and that **all existing patterns and sequences on this device will be permanently deleted and replaced**. Confirm and Cancel buttons; Cancel changes nothing. *(SHOULD)* Include a secondary action "Export current library first" in this dialog.
5. On confirmation: **stop any playback** (metronome, pattern sequencer, sequence), then replace the library **atomically** (see 10.6).
6. After a successful import, show a confirmation message with the number of patterns and sequences imported, and refresh every screen that lists patterns or sequences.
7. After a replace, the sequencer's working pattern (its unsaved editing state) stays as it is on screen but is **detached from the library**: saving it afterwards creates a new pattern rather than overwriting an imported one. Clear the "last opened sequence". Invalidate any cached rendered buffers keyed by pattern or sequence ids.

An empty library file (0 patterns and 0 sequences) is valid and simply clears the device; the confirmation dialog must say so clearly.

### 10.5 Validation (MUST)
Reject the file, with a specific and human-readable message, if any of the following is true:
- It is not valid JSON, is not a JSON object, or exceeds a sanity limit (suggested: 10 MB).
- `format` is missing or not `rhythm-box-library`, or `formatVersion` is missing or newer than supported.
- `patterns` or `sequences` is missing or not a list.
- Any pattern or sequence fails the **same validation** the app already applies when loading its own stored files (required fields, value ranges: tempo, step counts, 8 tracks, repeat counts 1–99, etc.). Older per-item `schemaVersion`s must be accepted through the existing tolerant reading code.
- Two patterns, or two sequences, share the same `id`.
- A sequence references a `patternId` that does not exist in the file's `patterns`.

Unknown optional fields are ignored. An unknown `kitId` is **not** an error (it falls back to the default kit at playback, as defined in `SPEC-3.md`, or is simply carried along if kits are not implemented yet).

Reuse the existing model parsing and validation functions; do not duplicate validation rules.

### 10.6 Atomic replace (MUST)
After any failure, crash, or app kill during an import, **either the entire old library or the entire new library is present, never a mix or a partial one.**

- Add a `replaceAll(patterns, sequences)` operation to the storage layer (e.g. on the pattern and sequence stores, or a small library repository wrapping both).
- A suggested approach for file-based storage: write all new files into a staging directory, then switch it in place of the current directories with directory renames (atomic on the same filesystem), then delete the old data. On startup, detect and clean up leftover staging or old directories from an interrupted import (and recover the old library if the switch had not completed). Choose the mechanism that fits the existing storage and document it in `design.md`.
- Playback is already stopped; the UI is refreshed afterwards.

### 10.7 UI details
- Keep it simple: two menu entries (Export library, Import library) plus the dialogs and messages above.
- Use plain wording, e.g. dialog title "Replace all data?", body "This file contains 12 patterns and 3 sequences. Importing will permanently delete everything currently saved on this device and replace it with the contents of the file."
- Show progress or a busy indicator if the operation takes noticeable time; never block silently.

### 10.8 Tests
- **Round trip:** export a library to JSON and import it back into an empty store; the resulting patterns and sequences are deeply equal to the originals (same ids, same fields, same references).
- **Replace semantics:** importing into a store that already has different patterns and sequences leaves only the imported ones; nothing from the old data remains.
- **Validation failures** leave the existing data untouched, for each case in 10.5: malformed JSON, wrong `format`, newer `formatVersion`, missing lists, an invalid pattern, an invalid sequence, duplicate ids, a dangling `patternId`, and an oversized file.
- **Atomicity:** simulate a failure in the middle of writing the new library; the old library is fully intact afterwards. Also test the startup recovery of leftover staging directories.
- **Backward compatibility:** a file whose patterns and sequences use older per-item `schemaVersion`s (or lack `kitId`) imports correctly.
- **Empty library** exports with a message instead of a file, and importing an empty library file clears the device.
- Widget tests for the dialog flow (confirm and cancel) are nice to have.

### 10.9 Manual acceptance
Using a real Android device and the Linux build:
- Create several patterns and at least two sequences that use them (with repeats and loop settings). Export on Android, import on Linux, and compare: the lists are identical, and each sequence plays with the same total length and the same order and repeats.
- Repeat in the opposite direction (Linux to Android).
- Import a corrupted file (e.g. one with an edited-out `patterns` list): confirm the error message and that nothing changed.
- Cancel an import at the confirmation dialog: confirm nothing changed.
- Run the existing automated test suite; nothing in the audio timing tests should change.

### 10.10 Definition of done
Export and import work on Android and Linux; import fully replaces the library atomically; failed or cancelled imports never change data; all tests pass; the README has a short section explaining how to move a library between devices and what is (and is not) included.

---

## 11. Out of scope (do not implement)
- Merging libraries, selecting which items to export or import, or conflict resolution.
- Exporting or importing settings, the global tempo, metronome configuration, or kits.
- Cloud sync, automatic backups, QR codes, encryption, or compression.
- Undo of an import or a "restore previous library" feature.
- Exporting audio or MIDI.

## 12. Assumptions (note any deviation in `design.md`)
- The whole library is always exported as one file; there is no partial export.
- A file with a sequence referencing a missing pattern is rejected instead of being repaired.
- The sequencer's unsaved working pattern survives an import but is detached from the library.
- Import and export are used by one person moving data between their own devices, so no trust or security model beyond input validation is needed.

## 13. Working agreements
- Report when done, including the manual acceptance results from 10.9.
- Keep the OpenSpec specs and changes up to date as you go.
- When a requirement conflicts with the existing implementation in a way that cannot be resolved with the simplest option, ask; otherwise choose the simplest option and record it.
