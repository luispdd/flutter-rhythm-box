## Context

See `proposal.md` for motivation. Rhythm Box currently uses a hardcoded 8-voice list (`defaultVoices` in `lib/domain/voice.dart`) and renders voices in `VoiceRenderer` using sine, triangle, square, or PRNG white noise. To support retro sound sets, we need data-driven sound kits and extended synthesis primitives.

## Goals / Non-Goals

**Goals:**
- Define `Kit` model and JSON schema representing exactly 8 tracks.
- Implement `KitRepository` loading and strictly validating bundled assets.
- Extend `VoiceRenderer` with `pulse`, `lfsrNoise`, `pitchSteps`, `bitDepth`, and `downsampleHz`.
- Retain sample-for-sample determinism and verify against pre-refactor golden buffers.

**Non-Goals:**
- UI kit picker or track label changes on screen (Milestone 9).
- User kit creation, editing, or loading from external document directories.
- Changes to `MetronomeSettings` or metronome renderer.

## Decisions

### D1: DSP Pipeline Order
The rendering pipeline inside `VoiceRenderer` processes samples in the following order:
$$\text{Oscillator/Generator} \longrightarrow \text{Downsample (downsampleHz)} \longrightarrow \text{Bit Crush (bitDepth)} \longrightarrow \text{Filters (HP/LP)} \longrightarrow \text{Envelope \& Gain} \longrightarrow \text{Soft Limiter}$$

*Rationale:*
- Downsampling (sample-and-hold) and bit crushing quantize the raw waveform. Placing them before the digital one-pole highpass/lowpass filters mimics the analog reconstruction and filtering circuitry of vintage sound hardware (e.g., filtering out harsh low-frequency quantization noise from bit-crushed hats).
- The downsample and bit crush operations are bypassed when their respective parameters are null, preserving exact behavior for legacy voices.
- *Alternatives considered:* Applying bit crush after the envelope. Rejected because quantizing an exponentially decaying tail introduces audible stepping and cutoff artifacts.

### D2: NES LFSR Emulation
`lfsrNoise` emulates the 15-bit Linear Feedback Shift Register from the NES APU noise generator:
- Shift register: 15-bit unsigned integer initialized to `1`.
- Clocked at `lfsrClockHz` (e.g., 16000 or 32000 Hz).
- Taps:
  - Long mode (`lfsrShort = false`): `feedback = (reg & 1) ^ ((reg >> 1) & 1)`
  - Short mode (`lfsrShort = true`): `feedback = (reg & 1) ^ ((reg >> 6) & 1)` (produces a periodic 93-step metallic sequence)
- Shift: `reg = (reg >> 1) | (feedback << 14)`.
- Output: bipolar signal where `(reg & 1) == 0 ? 1.0 : -1.0`.
- Resampling: Sample-and-hold to 44.1 kHz via time mapping `step = floor(t * lfsrClockHz)`.

### D3: Stepped Pitch Behavior
When `pitchSteps` is provided (`semitones`, `stepMs`):
- For elapsed time $t$ in seconds, step index $k = \lfloor (t \times 1000) / \text{stepMs} \rfloor$.
- If $k < \text{semitones.length}$, the frequency is $\text{startFreqHz} \times 2^{\text{semitones}[k] / 12}$.
- If $k \ge \text{semitones.length}$, the frequency clamps to the final semitone offset ($\text{semitones.last}$) and holds that pitch until the decay envelope finishes.
- *Alternatives considered:* Modulo cycling. Rejected because vintage game blips and arpeggios (coins, jumps) typically resolve to a resting pitch rather than looping indefinitely.

### D4: Pulse Waveform Implementation
- Waveform `Waveform.pulse`:
- Period $T = 1 / f(t)$. Normalized phase $u = (\text{phase} / 2\pi) \pmod{1.0}$.
- Output is $+1.0$ when $u < \text{dutyCycle}$ (clamped between 0.05 and 0.95, default 0.5), else $-1.0$.
- Phase starts at 0.0, and smooth onset click prevention is handled naturally by the 1.5 ms linear attack envelope.

### D5: Bit Depth Quantization Formula
- Uniform quantization to $2^{\text{bitDepth}}$ levels:
  $$\text{levels} = 2^{\text{bitDepth}}$$
  $$\text{step} = \frac{2.0}{\text{levels} - 1}$$
  $$\text{quantized} = \left(\text{round}\left(\frac{x + 1.0}{\text{step}}\right) \times \text{step}\right) - 1.0$$
- Valid bit depth ranges from 2 (4 levels) to 16 (65536 levels).

### D6: Deterministic Seed Derivation
For noise and LFSR voices, the seed is derived deterministically from the kit identifier and track index:
$$\text{seed} = (\text{kitId.hashCode} \land 0x7FFFFFFF) \oplus (\text{trackIndex} \times 31337)$$
For backward compatibility with tests using `defaultSeedForTrack(trackIndex)`, when `kitId == 'classic-synth'`, the seed strictly evaluates to `0x12345678 ^ (trackIndex * 31337)`.

### D7: Kit Repository & Asset Bundling
- `KitRepository` interface defines `Future<List<Kit>> getKits()`, `Future<Kit> getKit(String id)`, and `Kit get defaultKit`.
- `AssetKitRepository` loads JSON files bundled under `assets/kits/`.
- `pubspec.yaml` registers the `assets/kits/` directory.
- `defaultVoices` constant is retained in `voice.dart` as a fallback ensuring headless unit tests execute without requiring Flutter asset bundle mocks.

## Risks / Trade-offs

- **[Headless test asset binding]** → Tests running via `flutter test` without Flutter engine bindings cannot call `rootBundle.loadString()`.
  *Mitigation:* `KitRepository` will offer a synchronous / in-memory factory constructor `KitRepository.fromList(...)` and keep `classic-synth` available in-memory for testing.
- **[Validation strictness]** → Corrupted or invalid custom JSON kits could crash initialization.
  *Mitigation:* Validate during parsing (`schemaVersion`, exactly 8 voices, parameter bounds). If invalid, log an error, ignore the kit, and never allow it into the available list.
