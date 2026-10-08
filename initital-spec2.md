# Rhythm Box — Specification, Phase 2

Continuation of the personal-use Rhythm Box project (metronome + 8-track step sequencer, all-synth sounds, Flutter + `flutter_soloud`).

**Already implemented (do not redo):** the timing spike, core (models, synth renderer, audio engine, global tempo), the metronome, the pattern sequencer, and pattern save/load/rename/delete (milestones 0–4 of the first spec).

**This document covers three remaining milestones:**

| # | Milestone | Priority |
|---|---|---|
| 5 | Sequences of patterns (new feature) | MUST |
| 6 | Polish and release builds (Android + Linux) | MUST |
| 7 | Playback with the screen off (Android) | SHOULD |

Use this file as source material for OpenSpec: create **one change per milestone** (suggested names `add-sequences`, `polish-release`, `add-background-playback`), following OpenSpec's default file conventions. Record non-trivial decisions in each change's `design.md`.

---

## 0. Ground rules

1. **Read before coding.** Read the existing code, the OpenSpec specs and changes already archived/created, and the spike's `design.md` (it records the looping/boundary-swap mechanism chosen for `flutter_soloud`). Follow existing conventions and reuse the existing layers (domain models, synth renderer, `AudioEngine` interface, storage, UI). Do not restructure working code unless a requirement here needs it.
2. **Core timing principle still applies (MUST).** No Dart timer, `Future.delayed`, `Timer.periodic`, or UI-thread scheduler may decide when a sound starts. Timing comes from the audio side: render buffers and play them as gapless loops, applying changes at loop boundaries.
3. **Timing regression stops the work.** If any change makes the timing criteria in section 5.7 fail, stop and report the measured numbers instead of working around it with timers.
4. Prefer few dependencies; ask before adding any large one.
5. Keep audio logic out of widgets.

---

## 5. Milestone 5 — Sequences of patterns ("sequences of sequences") — MUST

### 5.1 Concept
A **sequence** is an ordered list of entries. Each entry references a pattern from the pattern library plus a repeat count. Playback is strictly sequential, nothing overlaps: the first entry plays its repeats, then the second, and so on.

Example: `[Pattern A × 2, Pattern B × 4, Pattern C × 1]` plays A, A, B, B, B, B, C.

### 5.2 Behavior
- Each entry plays with the referenced pattern's **own tempo, step count and step data**. The global tempo is not applied during sequence playback.
- Repeat count per entry: **1–99**. The same pattern may appear in several entries.
- Playback mode: **play once** (stops after the last entry) or **loop** (restarts from the first entry with no gap). Default: loop. The mode is saved with the sequence.
- Own **Play/Stop** button. Starting the metronome, the pattern sequencer, or a sequence stops whichever of the others is playing (one at a time).
- A sequence with no entries (or with no playable entries) cannot be played; show a clear message.

### 5.3 Editor (UI)
- A new screen/tab for sequences, alongside the Metronome and Sequencer screens, listing saved sequences.
- Sequence editor: add an entry (pick from the pattern library), remove an entry, reorder entries (drag or up/down buttons), change an entry's repeat count, toggle play once/loop.
- Show each entry's pattern name, tempo, step count and repeat count.
- Highlight the entry currently playing. This may be approximate and must be derived from the audio engine's position if available; it must never drive audio.
- Edits while a sequence plays apply the next time the sequence restarts (in play-once mode the current pass is unaffected).

### 5.4 Persistence and references
- **Save, load, rename, delete** sequences. A saved sequence stores **only references** (pattern ids and repeat counts), never copies of pattern data. Same storage approach as patterns (one JSON file per sequence unless the existing store does otherwise).
- Editing a pattern in the library changes every sequence that uses it. **Verify** that saving over an existing pattern overwrites it in place keeping its `id`; if the current implementation creates a new id (or has no overwrite), fix that as part of this milestone, since references depend on stable ids. Saving as a new pattern must still be possible.
- Deleting a pattern that is used by one or more sequences: show a warning listing the affected sequences; if confirmed, remove those entries from them.
- Loading a sequence that references a pattern that no longer exists (e.g. a corrupted or manually edited store): do not crash. Skip or flag the entry visibly and let the user remove it.

Data model (extend the domain layer; keep it pure Dart):

```json
{
  "id": "uuid",
  "name": "Verse groove",
  "loop": true,
  "entries": [
    { "patternId": "uuid-of-pattern-a", "repeats": 2 },
    { "patternId": "uuid-of-pattern-b", "repeats": 4 },
    { "patternId": "uuid-of-pattern-c", "repeats": 1 }
  ]
}
```

### 5.5 Rendering
- Extend the synth renderer so it can render a whole sequence: render each entry's pattern loop at that pattern's own tempo (using the existing pattern rendering and its sample-rounding rule) and concatenate the repeats in order into one buffer. Play it once or as a gapless loop through the existing `AudioEngine` interface.
- Because each pattern loop length is rounded the same way, transitions between entries land on exact sample boundaries.
- Memory: a long sequence is large (about 5 MB per minute at 44.1 kHz mono 16-bit). Warn or cap the total length (e.g. 10 minutes). If the spike's `design.md` chose a per-entry buffer queue instead of single-buffer looping, use that mechanism and note it in this change's `design.md`; otherwise decide here whether to queue per-entry buffers or render one large buffer.
- Rendering should not block the UI noticeably; if rendering a long sequence takes noticeable time, do it off the UI thread (e.g. an isolate) and show a brief busy state.

### 5.6 Tests
- Unit tests for sequence rendering: total length equals the sum, over entries, of that pattern's loop length times its repeats (each at its own tempo); onsets land at the expected sample indices; the loop seam is exact; output is deterministic and within the valid sample range.
- Unit tests for sequence JSON round-trip, for reordering/removing entries, and for deleting a referenced pattern.
- Widget tests for the main editor flows are nice to have.

### 5.7 Timing acceptance (reuse the spike's measurement tool)
Using the timing analysis tooling created in the spike, on a **real Android device** (speaker or wired headphones) and on Linux, record 5 minutes of a sequence loop containing at least two patterns with **different tempos**, e.g. `[A × 2, B × 4]`. Targets (report the actual numbers):

- Inter-onset interval standard deviation **< 1 ms** within each pattern.
- Maximum deviation from the expected interval **< 3 ms**, including **across entry transitions** and across the **sequence loop seam**.
- Cumulative drift over 5 minutes **< 5 ms** relative to the expected total sequence length.
- No audible click, gap, or doubled hit at transitions or at the loop seam.

### 5.8 Definition of done (milestone 5)
All behaviors above work; tests pass; timing numbers are reported; sequences survive an app restart; the existing metronome, sequencer, and pattern features still meet their previous timing criteria.

---

## 6. Milestone 6 — Polish and release builds — MUST

### 6.1 Persistence of last state
Restore on startup (if not already done): last-used global tempo, metronome settings, the sequencer's working pattern (including unsaved edits), and the last-selected tab. Optionally restore the last-opened sequence.

### 6.2 Error handling
- Corrupted, missing, or unreadable JSON files for patterns, sequences, or settings: do not crash; skip the bad file, keep the rest, and show a short message. Never delete a file automatically because it failed to parse.
- Storage write failures (disk full, permissions): show an error and keep the in-memory state.
- Audio engine initialization failure or loss of the audio device: show a clear message and stop playback cleanly; allow retrying.
- Add a `schemaVersion` field to stored JSON (patterns, sequences, settings) if not already present, and read older files tolerantly (missing `schemaVersion` = version 1).
- Dispose the audio engine and release resources on app shutdown; stop playback when the app is closed.

### 6.3 UX basics
- Empty states for the pattern library and sequence list, with a short hint.
- Confirmation dialogs for destructive actions (delete pattern, delete sequence, clear pattern).
- Consistent, readable controls on small phone screens and on a desktop window; support both portrait and landscape on Android.
- Keep the UI simple; this is a personal tool, not a design exercise.

### 6.4 Android release build
- Set a proper application id, app name, version, and a simple launcher icon.
- Create a release signing configuration for **personal use** (a local keystore kept out of version control) and produce a release APK (an app bundle only if Play distribution is wanted later).
- Check that the release build (not only debug) meets the timing criteria on a real device. Release and debug builds can differ.
- Set sensible `minSdk`/`targetSdk` and verify that the app installs and runs on the owner's device.

### 6.5 Linux build
- Produce a release build for Linux desktop (`flutter build linux`) and document how to run it and its system requirements (e.g. audio backend, required packages).
- Verify audio playback and the timing criteria on Linux.

### 6.6 Documentation
- A short `README.md`: what the app is, how to build and run on Android and Linux, how to run the tests, and how to run the timing analysis.

### 6.7 Definition of done (milestone 6)
Release builds for Android and Linux install and run; all features from milestones 1–5 work in the release builds; corrupted-data and error cases are handled without crashes; the README exists; the timing criteria still pass on both platforms.

---

## 7. Milestone 7 — Playback with the screen off (Android) — SHOULD

Goal: the metronome, the pattern sequencer, and sequences keep playing steadily when the screen turns off or the app goes to the background, so the app can be used while playing an instrument with the phone locked or in a pocket.

### 7.1 Requirements
- Run playback inside an **Android foreground service** with the media-playback service type, with a persistent notification showing what is playing and a **Stop** control (play/pause is nice to have).
- Declare the required permissions and service type in the manifest (foreground service and media-playback foreground service permissions; on Android 13+ request the notification permission at an appropriate moment and handle denial gracefully with an explanation).
- Handle **audio focus**: request it when playback starts; define the behavior when it is lost (an incoming call or another app starts audio). Default: stop playback on permanent loss, pause or lower the volume on transient loss and resume afterwards if reasonable. Record the choice in `design.md`.
- Handle headphone unplugging or Bluetooth disconnection (stop or pause rather than suddenly blaring from the speaker; default: pause).
- Stopping playback (from the app or the notification) must stop the service and remove the notification, leaving no background work running.
- Consider a partial wake lock only if testing shows the CPU sleeping interferes with playback; do not add it by default.
- Evaluate existing Flutter packages for the foreground-service/notification part (e.g. `audio_service`, `flutter_foreground_task`) versus a small piece of native Kotlin; choose the lightest option that works and note the reasoning in `design.md`. Ask before adding a large dependency.
- Linux: nothing to do for this milestone.

### 7.2 Constraints
- The core timing principle still applies. The foreground service only keeps the process alive; it must not introduce a timer-based scheduler. The audio loop continues to be played by the audio engine.
- If the Android system suspends or throttles the Dart isolate in the background, the audio must keep playing without it. If playing a loop requires Dart to keep feeding buffers, record that limitation. For a looping single buffer or a pre-rendered sequence it should not be needed, but verify it.

### 7.3 Acceptance
On a real Android device, for each of the metronome, a pattern, and a sequence:
- Playback continues for at least **10 minutes** with the screen off, and with another app in the foreground.
- The timing criteria from section 5.7 hold during screen-off playback (record 5 minutes and report the numbers).
- The notification Stop control works, the service stops, and the notification disappears.
- Behavior on audio-focus loss and headphone disconnection matches what was chosen in `design.md`.
- Release build tested as well as debug.

If the device's battery-optimization settings prevent steady playback, document the needed setting in the README (do not work around it with hacks).

---

## 8. Out of scope (do not implement)
- Live finger drumming or any low-latency input.
- Sample import, editable voices, swing, velocity, effects, MIDI, audio/MIDI export.
- Overlapping sections, nested sequences, per-entry tempo overrides.
- Voice/rhythm recognition.
- A web version.
- Cloud sync, accounts.

## 9. Assumptions (note any deviation in `design.md`)
- Only one of metronome / pattern sequencer / sequence plays at a time.
- Sequences loop by default; the loop/once choice is saved per sequence.
- Deleting a referenced pattern removes its entries from sequences after confirmation.
- Sequence edits take effect when the sequence next restarts.
- Total sequence length is capped (about 10 minutes) to bound memory.
- Release signing is for personal sideloading only.

## 10. Working agreements
- Work milestone by milestone and report after each one, with measured timing numbers where the milestone requires them.
- Keep the OpenSpec specs and changes up to date as you go.
- Ask when a requirement conflicts with the existing implementation in a way that cannot be resolved with the simplest option; otherwise choose the simplest option and record it.
