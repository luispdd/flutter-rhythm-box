## MODIFIED Requirements

### Requirement: Voice parameter set
A voice SHALL be described by a waveform (`sine`, `triangle`, `square`, `pulse`, `noise`, `lfsrNoise`), start and end frequency in Hz, decay length in ms, gain, track label string, optional high-pass and low-pass cutoff in Hz, optional pulse duty cycle, optional LFSR parameters (`lfsrClockHz`, `lfsrShort`), optional stepped pitch (`pitchSteps` with `semitones` and `stepMs`), optional bit depth (`bitDepth` 2–16), and optional downsampling rate (`downsampleHz`), and SHALL round-trip through JSON without loss.

#### Scenario: JSON round-trip
- **WHEN** a voice is serialized to JSON and deserialized again
- **THEN** every field equals the original, including absent (null) filters and new optional parameters

#### Scenario: Unknown waveform rejected
- **WHEN** JSON with a waveform name outside the six supported values is deserialized
- **THEN** deserialization fails with a descriptive error

#### Scenario: Missing optional parameters default safely
- **WHEN** a voice JSON containing only legacy fields is deserialized
- **THEN** all new fields evaluate to null/defaults and rendering behaves identically to the pre-kit voice

### Requirement: Default voice ladder
The system SHALL provide a default voice ladder of exactly 8 voices corresponding to the `classic-synth` built-in kit, indexed 0 (lowest) to 7 (highest), labeled `Kick`, `Low tom`, `Mid perc`, `High perc`, `Low synth`, `High synth`, `Snare`, and `Hat`.

#### Scenario: Ladder size and order
- **WHEN** the default ladder is read
- **THEN** it contains 8 voices, and track 0 is a sine sweeping 150 Hz to 45 Hz with 260 ms decay, and track 7 is noise with a 7000 Hz high-pass and 40 ms decay

#### Scenario: Ladder labels
- **WHEN** the `classic-synth` ladder voice labels are inspected
- **THEN** tracks 0 through 7 have labels `Kick`, `Low tom`, `Mid perc`, `High perc`, `Low synth`, `High synth`, `Snare`, and `Hat`

### Requirement: Voice rendering shape
A rendered voice SHALL sweep exponentially from start to end frequency (or step through `pitchSteps` when defined), apply downsampling and bit crushing when configured, filter through optional high-pass and low-pass stages, and shape amplitude with an attack of 1 to 2 ms and exponential decay.

#### Scenario: Attack avoids a click
- **WHEN** any voice is rendered
- **THEN** the first sample is 0 and the peak is reached within 2 ms

#### Scenario: Decay length
- **WHEN** a voice with decay 100 ms is rendered
- **THEN** the amplitude after 500 ms is below 1 percent of the peak

#### Scenario: High-pass on noise
- **WHEN** a noise voice with a 7000 Hz high-pass is rendered
- **THEN** the energy below 1000 Hz is at least 20 dB lower than the energy above 7000 Hz

#### Scenario: Pulse wave duty cycle
- **WHEN** a pulse voice with duty cycle 0.25 is rendered over multiple periods
- **THEN** the fraction of positive samples matches 0.25 within a 2% tolerance and initial onset contains no discontinuity click

#### Scenario: LFSR noise generation
- **WHEN** an `lfsrNoise` voice is rendered with `lfsrShort = true`
- **THEN** the noise output exhibits periodic repetition of exactly 93 shift-register clock steps resampled to 44.1 kHz

#### Scenario: Pitch steps frequency shifting
- **WHEN** a voice with `startFreqHz = 440`, `pitchSteps.semitones = [0, 5]`, and `pitchSteps.stepMs = 60` is rendered
- **THEN** the dominant frequency is near 440 Hz during the first 60 ms and shifts by 5 semitones (near 587.3 Hz) for the second 60 ms, holding the final pitch thereafter

#### Scenario: Bit depth quantization and filter order
- **WHEN** a voice is rendered with `bitDepth = 4` and a high-pass cutoff of 5000 Hz
- **THEN** output amplitude levels before filtering are quantized to 16 discrete states, and energy below 1000 Hz after filtering is suppressed by at least 18 dB

### Requirement: Deterministic output
Rendering the same input SHALL produce byte-identical PCM, including for noise voices.

#### Scenario: Repeated render of noise
- **WHEN** the same pattern containing noise tracks is rendered twice
- **THEN** both PCM buffers are identical

#### Scenario: Deterministic LFSR and noise output
- **WHEN** an LFSR or noise voice with identical kit ID and track index is rendered multiple times
- **THEN** every rendered buffer is byte-for-byte identical
