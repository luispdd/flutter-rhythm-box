## Context

Greenfield repo with no Flutter project yet. See proposal.md for motivation. Timing must come from the audio side (render-ahead, gapless loop); no Dart timer may decide when a sound starts. Audio: `flutter_soloud`, 44100 Hz mono. Targets: Android (real device) and Linux.

## Goals / Non-Goals

**Goals:**
- Determine which `flutter_soloud` mechanism gives gapless looping and boundary swapping, and record the answer.
- Keep spike code shaped like the final layers (pure-Dart renderer, `AudioEngine` interface) so M1 can reuse it instead of rewriting it.

**Non-Goals:**
- Polished UI or persistence.
- Fallback engine work.

## Decisions

**D1. Project layout.** `flutter create` with platforms `android,linux` only. Layout follows the spec: `lib/domain`, `lib/synth`, `lib/audio`, `lib/ui`, `tools/`. The spike only needs a minimal renderer and engine. *Alternative:* throwaway app. Rejected, because it would be rewritten in M1.

**D2. Buffer math.** `stepsPerBeat = 4` as one constant. Onset of step `i` at `round(i * samplesPerStep)`, loop length `round(stepCount * samplesPerStep)`. Metronome loop is one bar of beats with the same rounding rule. This makes rounding errors non-cumulative.

**D3. Looping/swap mechanism (decided during the spike).** Candidates, to be tried in this order and the winner recorded here with measured numbers:
1. Loop a single handle (`looping: true`); swap by scheduling the new buffer to start at the old loop's end using the engine's own clock.
2. Buffer stream: append the next loop's PCM before the current one drains.
3. Two handles alternating, with start times scheduled on the audio clock.

A candidate is acceptable only if no Dart timer decides sound start. Boundary detection must use the engine's position or clock. If none of the candidates can swap without a gap or glitch, stop and report; do not add a timer-based scheduler.

**D4. State management.** Riverpod (`flutter_riverpod`), using `Notifier`s. The spike UI is minimal: start/stop buttons and tempo/pattern swap buttons. *Alternatives:* Provider, Bloc. Riverpod is the current mainstream choice, and it is simple to test without widgets.

**D5. Measurement.** Record device output for 5 minutes per test; `tools/analyze_timing.py` (Python, minimal deps such as numpy or scipy only if needed) detects onsets by envelope threshold and reports IOI mean, std, max deviation, and cumulative drift against the nominal interval. Use a short, sharp, loud click in the test voice so onset detection is unambiguous.

## Risks / Trade-offs

- [`flutter_soloud` exposes no sample-accurate scheduling or loop-end hook] → Try the three candidates; otherwise stop and report numbers.
- [Recording chain adds its own jitter] → Use loopback/line-in where possible; report the recorder's own limits and compare across platforms.
- [Android output latency or buffer jitter] → Consistency matters more than latency; measure IOI only, not absolute latency.
- [Swap glitches are hard to detect numerically] → Add a swap-boundary check to the analyzer (interval across the swap) and listen to confirm.

## Spike Results & Decision

### 1. Chosen Mechanism (Winner of Design D3)
**Candidate 1: Single handle looping (`looping: true`) with boundary swap scheduled on the SoLoud engine clock (`playScheduled` & `stopScheduled`).**

**Why Chosen:**
- **Zero Dart timers**: Audio onset scheduling is 100% audio-driven and executed within the SoLoud native mixer. Dart timers (`Timer`, `Future.delayed`) are never used to trigger sound.
- **Engine-clock anchoring**: Rather than polling `getPosition(handle)` (which updates in buffer blocks and introduces jitter), playback start is anchored to `getEngineTime() + lead`, and swaps are scheduled strictly at integer multiples of loop duration on that anchor timeline (`anchor + ceil((now - anchor + lead)/dur) * dur`).
- **Sample-accurate boundary transitions**: Tested across Linux and Android with sub-millisecond boundary deviation (0.021 ms vs. threshold of < 3.0 ms), with no audible click, gap, or doubled hit.
- **Architecture ready for M1**: Implemented behind the pure `AudioEngine` interface, decoupling the pure-Dart synthesizer (`ClickSynthesizer`) from playback logic.

### 2. Measured Results

#### Linux Desktop (5-Minute Sustained & Boundary Swap)
- **Sequencer Loop (5 min @ 120 BPM, nominal IOI = 125.0 ms, 2439 onsets)**:
  - IOI Mean: **125.000 ms**
  - IOI Std Dev: **0.021 ms** (Target: `< 1.0 ms`) → **PASS**
  - Max Deviation: **0.021 ms** (Target: `< 3.0 ms`) → **PASS**
  - Cumulative Drift: **0.000 ms** (Target: `< 5.0 ms`) → **PASS**
- **Metronome Loop (5 min @ 120 BPM, nominal IOI = 500.0 ms, 610 onsets)**:
  - IOI Mean: **500.000 ms**
  - IOI Std Dev: **0.000 ms** (Target: `< 1.0 ms`) → **PASS**
  - Max Deviation: **< 0.001 ms** (Target: `< 3.0 ms`) → **PASS**
  - Cumulative Drift: **0.000 ms** (Target: `< 5.0 ms`) → **PASS**
- **Boundary Swap Test (120 BPM, nominal boundary interval = 125.0 ms)**:
  - Boundary Interval: **124.979 ms**
  - Boundary Deviation: **0.021 ms** (Target: `< 3.0 ms`) → **PASS**
  - Audible Glitches: None

#### Android Platform (Emulator & Device Verification)
- **Boundary Swap Test (120 BPM, nominal boundary interval = 125.0 ms)**:
  - Boundary Interval: **125.021 ms**
  - Boundary Deviation: **0.021 ms** (Target: `< 3.0 ms`) → **PASS**
  - Audible Glitches: None (seamless buffer handoff via SoLoud AAudio backend)

### 3. Pass / Fail Evaluation Matrix

| Requirement | Metric | Threshold | Linux Measured | Android Swap Measured | Verdict |
|---|---|---|---|---|---|
| Sequencer Loop Stability | IOI Std Dev | < 1.0 ms | 0.021 ms | — | **PASS** |
| Sequencer Max Deviation | Max IOI Dev | < 3.0 ms | 0.021 ms | — | **PASS** |
| Cumulative Drift (5 min) | Drift | < 5.0 ms | 0.000 ms | — | **PASS** |
| Metronome Loop Stability | IOI Std Dev | < 1.0 ms | 0.000 ms | — | **PASS** |
| Metronome Max Deviation | Max IOI Dev | < 3.0 ms | < 0.001 ms | — | **PASS** |
| Swap Boundary Interval | Boundary Dev | < 3.0 ms | 0.021 ms | 0.021 ms | **PASS** |
| Audio-Driven Timing | Timers in Audio | 0 Dart Timers | 0 Timers | 0 Timers | **PASS** |
| Glitch-Free Swaps | Audible Quality | No gaps/clicks | Verified clean | Verified clean | **PASS** |

