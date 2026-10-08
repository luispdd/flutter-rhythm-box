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

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- **Linux**: Standard Flutter Linux desktop prerequisites (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libasound2-dev`).
- **Android**: Android SDK (minimum SDK 21, target SDK 34) and Java 17+.
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
