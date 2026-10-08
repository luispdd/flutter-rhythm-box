# Rhythm Box — Specification, Phase 3: Sound Kits

Continuation of the personal-use Rhythm Box project (Flutter + `flutter_soloud`, all-synth sounds, render-ahead looping).

**Goal:** replace the single hard-coded set of 8 synth voices with **sound kits**: named, fully parametrized sets of 8 voices, selectable in the app. Ship two kits: the **current sound set** (unchanged) and a new **retro 8-bit (NES-style) kit**.

**Prerequisites:** the pattern sequencer and pattern library (first spec, milestones 0–4) and sequences of patterns (`SPEC-2.md`, milestone 5). If sequences are not finished yet, do this work after them.

Use this file as source material for OpenSpec: one change per milestone below (suggested names `add-kit-model`, `add-retro-kit-and-selection`). Record non-trivial decisions in each change's `design.md`.

---

## 0. Ground rules

1. **Read before coding.** Read the existing code, the OpenSpec specs, and the previous changes' `design.md` files. Reuse the existing layers (domain models, synth renderer, `AudioEngine` interface, storage, UI). Do not restructure working code unless a requirement here needs it.
2. **Core timing principle still applies (MUST).** No Dart timer or UI-thread scheduler may start sounds. Kits only change *what is rendered*; playback stays render-ahead and gapless, with changes swapped in at the loop boundary.
3. **The current sound must not change.** Existing patterns and sequences must sound exactly as before after migration.
4. Prefer few dependencies. Keep audio logic out of widgets.

---

## 8. Milestone 8 — Kit model and renderer extensions

### 8.1 Kit definition (data-driven, MUST)
A **kit** is a named list of exactly **8 voices** (track 0 = lowest, track 7 = highest). Kits are defined as data, not code, so they are easy to edit and duplicate: duplicating a kit means copying its JSON and changing `id` and `name`.

```json
{
  "schemaVersion": 1,
  "id": "retro-8bit",
  "name": "Retro 8-bit",
  "builtIn": true,
  "voices": [
    {
      "label": "Kick",
      "waveform": "triangle",
      "startFreqHz": 150,
      "endFreqHz": 45,
      "decayMs": 140,
      "gain": 0.9,
      "bitDepth": 4
    }
  ]
}
```

(The `voices` array always contains 8 entries; the example shows one.)

- Built-in kits live as JSON files in `assets/kits/` and are loaded at startup. Ids are stable strings and never change once released.
- A `KitRepository` abstraction (list kits, get kit by id, default kit) isolates where kits come from, so user-defined kits can be added later without touching the renderer or UI.
- **Validation (MUST):** a kit must have exactly 8 voices and valid parameter ranges. Invalid values are rejected or clamped with a clear error message; an invalid kit must never crash the app or be listed as selectable. Document the allowed range of every parameter in code comments or in the README.
- *(SHOULD)* Also load kit JSON files from a `kits/` folder in the app documents directory, validated the same way, listed as read-only kits. This makes duplicating a kit as simple as copying a file (mostly useful on Linux). Skip this if it adds notable complexity and note the decision in `design.md`.

### 8.2 Voice parameters
Keep the existing parameters and add the new ones below. All new parameters are **optional**; when absent, the voice renders exactly as before.

| Parameter | Type / values | Meaning |
|---|---|---|
| `label` | string | Name shown on the track row (new, shown in the grid). |
| `waveform` | `sine`, `triangle`, `square`, `pulse`, `noise`, `lfsrNoise` | `pulse` and `lfsrNoise` are new. |
| `startFreqHz`, `endFreqHz` | number | Pitch sweep over the voice length (existing). |
| `dutyCycle` | 0.05–0.95, typical 0.125, 0.25, 0.5 | Only for `pulse`: fraction of each period the wave is high. |
| `lfsrClockHz` | e.g. 2000–48000 | Only for `lfsrNoise`: shift-register clock rate (higher = brighter). |
| `lfsrShort` | bool | Only for `lfsrNoise`: short (metallic, repeating, 7-bit style) vs long (15-bit style) sequence. |
| `pitchSteps` | `{ "semitones": [0, 5], "stepMs": 60 }` | Optional stepped pitch (coin blips, arpeggios). Overrides the continuous sweep; frequencies are `startFreqHz` shifted by each semitone offset, each held for `stepMs`. |
| `bitDepth` | 2–16, null/absent = off | Quantizes the amplitude to `2^bitDepth` levels (bit crush). |
| `downsampleHz` | e.g. 4000–44100, absent = off | Sample-and-hold at this rate (sample-rate reduction). |
| `attackMs`, `decayMs`, `gain` | numbers | Envelope and level (existing; attack stays very short by default). |
| `highpassHz`, `lowpassHz` | numbers or null | Optional filters (existing). |

### 8.3 Renderer requirements
- **Deterministic output (MUST):** rendering the same voice twice gives identical samples. Noise-based voices use a fixed seed derived from the kit id and track index, never a random seed per render (otherwise every re-render would change the sound).
- `pulse`: a naive-quality pulse is acceptable. Aliasing is part of the retro sound, but there must be no clicks at the start of a voice.
- `lfsrNoise`: emulate a linear-feedback shift register (15-bit, with the short mode using the NES-style shorter tap) clocked at `lfsrClockHz`, output as ±1 amplitude and resampled by sample-and-hold to the output rate.
- Apply bit crush and downsampling after waveform generation and before the envelope/limiter stage, unless `design.md` documents a better order.
- Keep the per-voice gain and soft limiter so overlapping voices never clip harshly.
- Voices that exist today must render **sample-for-sample identically** (see tests).

### 8.4 Default kit migration (MUST)
- Convert the current hard-coded 8-voice ladder into a built-in kit with id `classic-synth` (name "Classic synth"), keeping its existing parameter values exactly. It is the default kit.
- Existing saved patterns (and sequences) have no kit information: treat a missing kit as `classic-synth`. Do not rewrite old files just to add the field.

### 8.5 Tests
- **Regression:** for the `classic-synth` kit, the rendered buffer for a set of test patterns at several tempos equals the output of the pre-kit renderer sample-for-sample (store golden hashes or buffers captured before the refactor).
- `pulse`: the fraction of high samples over many periods matches `dutyCycle` within a small tolerance.
- `lfsrNoise`: deterministic (same seed, same output), and the short mode repeats with the expected short period.
- `pitchSteps`: the estimated frequency in each step window matches the expected semitone-shifted frequency (within tolerance).
- `bitDepth`: the number of distinct amplitude levels is at most `2^bitDepth` (before the envelope is applied, or measured accordingly).
- Samples always stay within the valid range; no non-finite values.
- Kit JSON: round-trip, validation of an invalid kit (wrong voice count, out-of-range values), unknown optional fields ignored safely.

### 8.6 Definition of done (milestone 8)
The app behaves identically to before with the `classic-synth` kit, voices are loaded from kit data, the new parameters render correctly, and all tests pass, including the regression golden tests.

---

## 9. Milestone 9 — Retro kit, kit selection, and kits in sequences

### 9.1 Retro 8-bit kit (MUST)
Add a built-in kit `retro-8bit` ("Retro 8-bit"). The values below are **starting values to tune by ear** and must live only in the kit's JSON. Track 0 is the lowest-pitched voice.

| Track | Label | Waveform | Pitch (Hz) | Other parameters | Decay | Gain |
|---|---|---|---|---|---|---|
| 0 | Kick | triangle | 150 → 45 | `bitDepth` 4 | 140 ms | 0.9 |
| 1 | Low tom | pulse (duty 0.25) | 180 → 70 | | 160 ms | 0.5 |
| 2 | Laser | pulse (duty 0.125) | 900 → 120 | fast downward sweep | 120 ms | 0.4 |
| 3 | Snare | lfsrNoise (long) | – | `lfsrClockHz` 16000, highpass 800 Hz | 120 ms | 0.6 |
| 4 | Coin | pulse (duty 0.5) | base 988 | `pitchSteps` semitones [0, 5], 60 ms each | 280 ms | 0.35 |
| 5 | Power-up | pulse (duty 0.25) | base 523 | `pitchSteps` semitones [0, 4, 7, 12], 45 ms each | 220 ms | 0.3 |
| 6 | Closed hat | lfsrNoise (short) | – | `lfsrClockHz` 32000, highpass 3000 Hz | 35 ms | 0.4 |
| 7 | Open hat | lfsrNoise (short) | – | `lfsrClockHz` 32000, highpass 5000 Hz, `bitDepth` 6 | 160 ms | 0.35 |

The kit should sound cohesive as a drum kit with a few game-effect sounds, and no single voice should be much louder than the others.

### 9.2 Kit selection in the pattern sequencer (MUST)
- A kit selector (dropdown or picker) on the sequencer screen lists the available kits and the current one is shown.
- Track rows show the voice `label` from the selected kit.
- Changing the kit re-renders the loop and swaps it in at the next loop boundary, with no click or gap. Stopped playback just re-renders.
- A pattern **stores a `kitId`**. Saving a pattern saves the kit currently selected; loading a pattern selects its kit. A pattern whose `kitId` no longer exists falls back to `classic-synth` with a brief notice.
- *(SHOULD)* Tapping a track's label plays a short preview of that voice, so kits can be auditioned and tuned quickly. A preview does not have to be rhythm-accurate and must not use a timer to schedule anything.

### 9.3 Kits in sequences (MUST)
- A **sequence stores a single `kitId`**, selected once in the sequence editor with the same kit selector. **Every pattern in the sequence is rendered with that kit**, ignoring the `kitId` stored in each pattern. The kit never has to be changed per pattern during playback.
- Sequence JSON gains the field `"kitId"` (missing = `classic-synth`):

```json
{
  "id": "uuid",
  "name": "Verse groove",
  "loop": true,
  "kitId": "retro-8bit",
  "entries": [
    { "patternId": "uuid-of-pattern-a", "repeats": 2 },
    { "patternId": "uuid-of-pattern-b", "repeats": 4 }
  ]
}
```

- The sequence editor shows the selected kit. Changing it while the sequence plays takes effect at the next sequence restart, like other sequence edits.
- If the sequence's `kitId` does not exist, fall back to `classic-synth` with a notice.

### 9.4 The metronome is unaffected
The metronome keeps its own adjustable click settings and does not use kits.

### 9.5 Persistence
- The last selected kit in the sequencer screen is restored on startup (as part of the existing last-state restoration).
- Patterns and sequences are written with the new `kitId` fields; reading older files without them must work (treated as `classic-synth`).

### 9.6 Tests
- Pattern and sequence JSON round-trip with and without `kitId`; missing or unknown ids fall back correctly.
- Rendering a sequence uses the sequence's kit for all entries (compare against rendering each pattern individually with that kit, concatenated).
- Total sequence length and onset positions are identical regardless of kit (kits change sound only, not timing).
- Widget tests for the kit selector are nice to have.

### 9.7 Timing acceptance
Using the existing timing analysis tooling, on a real Android device and on Linux, record 5 minutes each of: (a) a pattern with the retro kit, (b) a sequence with the retro kit, (c) a switch from one kit to the other while playing. Targets, reporting actual numbers:
- Inter-onset interval standard deviation **< 1 ms**, maximum deviation **< 3 ms**, drift over 5 minutes **< 5 ms**.
- No audible click, gap, or doubled hit when the kit is switched at the loop boundary.
- Rendering after a kit change does not stall the UI noticeably (if it does, render off the UI thread).

### 9.8 Definition of done (milestone 9)
Both kits are selectable; the retro kit sounds as described and is cohesive; kit choice is saved with patterns and sequences; all older data still loads and sounds as before; tests pass; timing numbers are reported.

---

## 10. Documentation
Add a short section to the `README.md` explaining the kit JSON format: every parameter, its valid range, and how to create a new kit by duplicating an existing kit file, changing `id` and `name`, and adding it (to `assets/kits/` or, if implemented, the user kits folder).

## 11. Out of scope (do not implement)
- An in-app kit editor or an in-app "duplicate kit" action (the data format must make it easy to add later).
- Different kits per pattern inside a sequence.
- Importing audio samples, import/export of kits through the UI, or sharing kits.
- Kits for the metronome.
- More than the two kits above.

## 12. Assumptions (note any deviation in `design.md`)
- Patterns store a `kitId` and sequences store their own, which overrides the patterns' kits during sequence playback.
- A kit always has exactly 8 voices.
- The retro kit values are placeholders to be tuned by listening.
- Kit data is read at startup; changing kit files requires restarting the app.

## 13. Working agreements
- Work milestone by milestone and report after each one, with the golden/regression results for milestone 8 and measured timing numbers for milestone 9.
- Keep the OpenSpec specs and changes up to date as you go.
- When a requirement conflicts with the existing implementation in a way that cannot be resolved with the simplest option, ask; otherwise choose the simplest option and record it.
