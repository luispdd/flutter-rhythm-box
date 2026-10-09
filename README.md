# Rhythm amigo (`rhythm_box`)

A high-precision, low-jitter metronome, step sequencer, and pattern arrangement engine built with Flutter and [SoLoud](https://soloud-audio.com/) via `flutter_soloud`.

---

## Features

- **Accurate Metronome**:
  - Configurable beats per bar (1–16) and accent toggle on beat 1.
  - Tonal waveforms: Sine, Triangle, Square.
  - Fine-grained pitch (Hz) and decay time (ms) controls.
  - Wide tempo range (30–300 BPM) with tap tempo and continuous hold-to-repeat steppers.

- **16-Step Grid Sequencer**:
  - Multi-track polyphonic drum synthesis (Kick, Snare, Closed Hat, Open Hat).
  - Configurable active step lengths (1–16).
  - Real-time step toggling during playback with sample-accurate loop boundary swaps.
  - Working pattern persistence and safety confirmation dialog when clearing patterns.

- **Pattern Library & Sequences**:
  - Save, load, rename, and delete custom patterns.
  - Sequence arranger: chain patterns into structured compositions with customizable repeats per pattern.
  - Loop mode (continuous loop vs. play-once).
  - Referential integrity protection: alerts when deleting a pattern that is actively referenced in a sequence.

- **Sample-Accurate Boundary Swapping**:
  - Zero-jitter audio transitions anchored strictly to the SoLoud native mixer clock.
  - "Latest swap wins" arbitration avoiding race conditions during rapid user adjustments.

- **Resilient Persistence & Clean Lifecycle**:
  - Versioned JSON serialization (`schemaVersion`) with fallback handling for missing versions.
  - Corrupted data tolerance: skips corrupted library items without losing valid entries or crashing.
  - Application lifecycle management: cleanly disposes of native audio engine resources on app termination (`AppLifecycleState.detached`).
  - Audio engine initialization error handling with retry capability in the UI.

---

## Sound Kits & JSON Format

Rhythm Box uses data-driven sound kits defined in pure JSON files (bundled in `assets/kits/`). Each kit specifies exactly 8 synthesis voices corresponding to tracks 0 (lowest voice, bottom row of grid) through 7 (highest voice, top row of grid).

### Top-Level Kit Fields

| Field | Type | Description |
|---|---|---|
| `schemaVersion` | Integer | Version of the kit format (currently `1`). |
| `id` | String | Unique identifier (e.g. `"classic-synth"`, `"retro-8bit"`). Non-empty string. |
| `name` | String | Human-readable name displayed in kit selector menus. Non-empty string. |
| `builtIn` | Boolean | `true` for built-in application kits, `false` for user-defined kits (default `false`). |
| `voices` | Array | Exactly 8 voice configuration objects for tracks 0 to 7. |

### Voice Parameters & Valid Ranges

Each of the 8 voice objects in `voices` supports the following properties:

| Parameter | Type | Valid Range / Allowed Values | Description |
|---|---|---|---|
| `label` | String | Optional (e.g. `"Kick"`, `"Snare"`) | Track label displayed in the sequencer step grid. Defaults to `"Trk N"`. |
| `waveform` | String | `"sine"`, `"triangle"`, `"square"`, `"pulse"`, `"noise"`, `"lfsrNoise"` | Oscillator/generator type. |
| `startFreqHz` | Number | `0.0` to `22050.0` Hz (default `0.0`) | Starting frequency for pitch sweeps. |
| `endFreqHz` | Number | `0.0` to `22050.0` Hz (default `0.0`) | Ending frequency for pitch sweeps. |
| `decayMs` | Number | `> 0.0` and `<= 10000.0` ms | Exponential amplitude decay time. |
| `gain` | Number | `0.0` to `2.0` (default `1.0`) | Linear voice output gain factor. |
| `highpassHz` | Number | Optional, `0.0` to `22050.0` Hz | High-pass filter cutoff frequency. |
| `lowpassHz` | Number | Optional, `0.0` to `22050.0` Hz | Low-pass filter cutoff frequency. |
| `dutyCycle` | Number | Optional, `0.05` to `0.95` (default `0.5`) | Pulse wave duty cycle (used with `"pulse"`). |
| `lfsrClockHz` | Number | Optional, `100.0` to `48000.0` Hz | Clock rate for chiptune LFSR noise (used with `"lfsrNoise"`). |
| `lfsrShort` | Boolean | Optional, `true` or `false` (default `false`) | Short 7-bit / 93-step periodic mode for metallic LFSR tones. |
| `pitchSteps` | Object | Optional | Discrete stepped frequency sequences (e.g. arpeggios, coin blips). |
| `pitchSteps.semitones` | Array | Array of integers | Semitone offsets relative to `startFreqHz` (e.g. `[0, 5]`). |
| `pitchSteps.stepMs` | Number | `> 0.0` ms | Duration in milliseconds for each step. |
| `bitDepth` | Integer | Optional, `2` to `16` | Bit-crush quantization depth (`null` = disabled). |
| `downsampleHz` | Number | Optional, `1000.0` to `44100.0` Hz | Sample rate reduction rate (`null` = disabled). |

### Creating a New Kit

To create a new kit:

1. **Duplicate an existing kit:** Copy an existing file in `assets/kits/` (e.g. `cp assets/kits/retro-8bit.json assets/kits/my-kit.json`).
2. **Update identity:** Change the `id` to a unique identifier (e.g. `"my-kit"`) and `name` to your preferred title (e.g. `"My Custom Kit"`). Set `"builtIn": false`.
3. **Configure the 8 voices:** Adjust voice parameters for tracks 0 through 7. Ensure the `voices` array contains **exactly 8 voices** and all parameter values stay within their valid ranges.
4. **Register the kit:**
   - **Bundled asset kit:** Ensure the file path is listed under `flutter.assets` in `pubspec.yaml` and registered in `AssetKitRepository`.
   - **User kits folder:** If the external user kits folder is supported, save the `.json` file into the application's user kits directory; the repository discovers and loads it on boot.

---

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- **Linux**: Standard Flutter Linux desktop prerequisites (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libasound2-dev`).
- **Android**: Android SDK (minimum SDK 21, target SDK 36) and Java 17+.
- **Python** (for timing analysis): Python 3.9+ with `numpy` and `scipy`.

---

## Getting Started

### 1. Fetch Dependencies

```bash
flutter pub get
```

### 2. Run Tests and Verification

```bash
# Static analysis
flutter analyze

# Unit and widget test suite
flutter test

# OpenSpec change validation
openspec validate --all
```

---

## Building and Running

### Linux Desktop

Run directly with Flutter:
```bash
flutter run -d linux
```

Build a standalone Linux debug or release bundle:
```bash
# Debug bundle
flutter build linux --debug

# Release bundle
flutter build linux --release
```
The executable bundle will be located at:
`build/linux/x64/<mode>/bundle/rhythm_box`

#### CLI Audio Playback Modes (Linux)

The Linux binary can also be launched directly from the command line for automated headless testing:
```bash
# Run sequencer loop for 30 seconds
./build/linux/x64/debug/bundle/rhythm_box sequencer 30

# Run metronome loop for 30 seconds
./build/linux/x64/debug/bundle/rhythm_box metronome 30

# Test dynamic boundary swap at second 15 of a 30-second run
./build/linux/x64/debug/bundle/rhythm_box swap 15 30

# Run sequence playback for 30 seconds
./build/linux/x64/debug/bundle/rhythm_box sequence 30
```

---

### Android

Run on a connected device or running Android emulator:
```bash
flutter run -d <device_id>
```

Build a release APK (`com.example.rhythmbox`):
```bash
flutter build apk --release
```
The output APK is generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Timing & Audio Benchmark Tools

This repository contains comprehensive timing and jitter analysis tools located in `tools/`:

### 1. Timing Analysis Script (`analyze_timing.py`)

Analyzes recorded WAV files by detecting onset peaks and computing interval errors, drift, and jitter against ideal grid timings:

```bash
python3 tools/analyze_timing.py path/to/recording.wav --bpm 120 --steps-per-beat 4
```

Optional flags:
- `--swap-time <sec>`: Evaluates boundary swap interval continuity across dynamic changes.
- `--json`: Outputs structured metrics in JSON format.
- `--self-test`: Runs synthetic accuracy tests verifying the timing detector itself.

### 2. Full Linux Benchmark (`run_full_benchmarks_linux.py`)

Captures Linux audio output via PipeWire (`pw-record`), runs metronome, sequencer, swap, and sequence benchmarks, and evaluates them with `analyze_timing.py`:

```bash
python3 tools/run_full_benchmarks_linux.py
```

### 3. Android Benchmark (`run_swap_benchmark_android.py`)

Automates Android emulator audio capture and boundary swap verification:

```bash
python3 tools/run_swap_benchmark_android.py
```

---

## Moving Libraries Between Devices (Export & Import)

Rhythm Box lets you back up and transfer your entire library of saved patterns and sequences between devices (e.g. between Linux and Android) via a single UTF-8 JSON file.

### How to Export

1. Open the **Metronome** screen.
2. Tap the **Export Library** button in the top-right app bar (upload icon).
3. If your library has saved patterns or sequences, a file save dialog opens (default filename: `rhythm-box-library-YYYY-MM-DD.json`). Choose your destination to save the file. (If your library is empty, an informational message is shown).

### How to Import

1. Open the **Metronome** screen on the target device.
2. Tap the **Import Library** button in the top-right app bar (download icon).
3. Select the exported `.json` library file.
4. Rhythm Box validates the file and displays a confirmation dialog showing the number of patterns and sequences to be imported.
5. Tap **Replace All** to execute the import. All audio playback stops immediately, the existing library is replaced with the file's contents, and the Sequencer and Sequences editors reset to a clean default state ready to load your imported patterns.

### What is Included & What is Not

- **Included:** All saved **patterns** (grid steps, tempos, step counts, kit references) and all saved **sequences** (sequence entries, repeat counts, loop settings, kit references).
- **Not Included:** Global tempo, metronome settings (pitch, decay, beats per bar, waveform), unsaved sequencer working pattern state, and sound kits (built-in kits ship directly with the app).
- **Full Replacement:** Import **replaces everything**. Existing patterns and sequences on the device are deleted and substituted by the file's contents without merging.

---

## Project Structure

```
lib/
├── audio/            # AudioEngine abstraction and SoLoud implementation
├── domain/           # Core domain models (Pattern, Sequence, MetronomeSettings, Voice, Tempo)
├── persistence/      # SettingsStore interface and SharedPreferences implementation
├── synth/            # Audio synthesizers, WAV PCM encoders, and renderers
└── ui/               # Screens, controllers, widgets, and lifecycle management
tools/                # Python audio analysis scripts and benchmark runners
test/                 # Comprehensive unit and widget test suite
```
