# Voice Synthesis Specification

## Purpose

Defines how Rhythm Box describes and renders its synthesized sounds: the voice parameter set, the fixed default voice ladder, and the deterministic PCM output of single voices and pattern mixes.

## Requirements

### Requirement: Voice parameter set
A voice SHALL be described by a waveform (sine, triangle, square or noise), start and end frequency in Hz, decay length in ms, gain, and optional high-pass and low-pass cutoff in Hz, and SHALL round-trip through JSON without loss.

#### Scenario: JSON round-trip
- **WHEN** a voice is serialized to JSON and deserialized again
- **THEN** every field equals the original, including absent (null) filters

#### Scenario: Unknown waveform rejected
- **WHEN** JSON with a waveform name outside the four supported values is deserialized
- **THEN** deserialization fails with a descriptive error

### Requirement: Default voice ladder
The system SHALL provide exactly 8 default voices, index 0 lowest and index 7 highest, with the parameters of the specified ladder (sine 150 to 45 Hz / 260 ms down to noise high-passed at 7000 Hz / 40 ms), defined in one place.

#### Scenario: Ladder size and order
- **WHEN** the default ladder is read
- **THEN** it contains 8 voices, and track 0 is a sine sweeping 150 Hz to 45 Hz with 260 ms decay, and track 7 is noise with a 7000 Hz high-pass and 40 ms decay

### Requirement: Voice rendering shape
A rendered voice SHALL sweep exponentially from start to end frequency, start with an attack of 1 to 2 ms, and decay exponentially over the decay length. Noise voices SHALL ignore the frequencies and apply the optional filters.

#### Scenario: Attack avoids a click
- **WHEN** any voice is rendered
- **THEN** the first sample is 0 and the peak is reached within 2 ms

#### Scenario: Decay length
- **WHEN** a voice with decay 100 ms is rendered
- **THEN** the amplitude after 500 ms is below 1 percent of the peak

#### Scenario: High-pass on noise
- **WHEN** a noise voice with a 7000 Hz high-pass is rendered
- **THEN** the energy below 1000 Hz is at least 20 dB lower than the energy above 7000 Hz

### Requirement: Deterministic output
Rendering the same input SHALL produce byte-identical PCM, including for noise voices.

#### Scenario: Repeated render of noise
- **WHEN** the same pattern containing noise tracks is rendered twice
- **THEN** both PCM buffers are identical

### Requirement: Loop length and onset placement
Pattern and metronome loops SHALL use `samplesPerStep = 44100 * 60 / bpm / 4`, place step `i` at `round(i * samplesPerStep)`, and have length `round(stepCount * samplesPerStep)`. A metronome loop SHALL be one bar of `beatsPerBar` beats of `44100 * 60 / bpm` samples each, with the same rounding rule.

#### Scenario: Whole-sample step length
- **WHEN** a 16-step pattern is rendered at 120 BPM
- **THEN** the buffer length is exactly 88200 samples and each step onset is at multiples of 5512.5 rounded

#### Scenario: Fractional step length does not accumulate
- **WHEN** a 16-step pattern is rendered at 130 BPM
- **THEN** the buffer length equals `round(16 * 44100 * 60 / 130 / 4)` and each onset equals `round(i * 44100 * 60 / 130 / 4)`

#### Scenario: Metronome bar length
- **WHEN** a metronome bar of 7 beats is rendered at 100 BPM
- **THEN** the buffer length equals `round(7 * 44100 * 60 / 100)`

### Requirement: Mixing never clips harshly
Mixing overlapping voices SHALL apply per-voice gain and a soft limiter so that every output sample stays inside the valid 16-bit range.

#### Scenario: All tracks active
- **WHEN** a pattern with all 8 tracks active on every step is rendered
- **THEN** every sample is within -32768 to 32767 and no run of more than 3 consecutive samples sits at a clipped extreme

### Requirement: Metronome click shape
The metronome renderer SHALL produce clicks using the configured waveform, pitch and decay, with beat 1 at the accent pitch when the accent is on.

#### Scenario: Accent on
- **WHEN** a metronome bar is rendered with accent on and pitch 1000 Hz
- **THEN** beat 1 has a dominant frequency near 1500 Hz and the remaining beats near 1000 Hz

#### Scenario: Accent off
- **WHEN** the accent is off
- **THEN** all beats have the same dominant frequency
