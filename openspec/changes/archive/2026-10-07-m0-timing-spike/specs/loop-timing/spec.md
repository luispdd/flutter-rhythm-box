## Purpose

Defines the measurable timing guarantees for looped audio playback in Rhythm Box (steady tempo, clean loop boundaries, glitch-free buffer swaps) and the tool used to verify them on real devices.

## ADDED Requirements

### Requirement: Steady looped playback
The system SHALL play a looped pattern and a looped metronome bar so that sound onsets occur at the nominal interval, with timing determined by the audio side and not by Dart timers or the UI thread.

#### Scenario: Sequencer loop interval stability
- **WHEN** a 4-step pattern of 16th notes loops at 120 BPM for 5 minutes (nominal interval 125 ms)
- **THEN** the standard deviation of inter-onset intervals is below 1 ms
- **AND** the maximum deviation from the nominal interval is below 3 ms, including across loop boundaries

#### Scenario: Metronome loop interval stability
- **WHEN** the metronome loops at 120 BPM for 5 minutes (nominal interval 500 ms)
- **THEN** the standard deviation of inter-onset intervals is below 1 ms
- **AND** the maximum deviation from the nominal interval is below 3 ms

#### Scenario: No cumulative drift
- **WHEN** either loop plays for 5 minutes
- **THEN** the cumulative drift against the nominal timeline is below 5 ms

### Requirement: Swap at loop boundary
The system SHALL apply a new tempo or pattern only at the next loop boundary, without audible click, gap, or doubled hit.

#### Scenario: Tempo change while playing
- **WHEN** the tempo or pattern is changed during playback
- **THEN** the current loop completes unchanged and the new content starts at the next loop boundary
- **AND** the interval across the swap deviates from nominal by less than 3 ms
- **AND** no click, gap, or doubled hit is audible

#### Scenario: Stop is immediate
- **WHEN** playback is stopped
- **THEN** sound ceases without waiting for the loop boundary

### Requirement: Automated timing analysis
The project SHALL provide a tool that analyzes a WAV recording and reports timing statistics, so that results are measured and not judged by ear.

#### Scenario: Report produced from a recording
- **WHEN** the tool is run on a WAV recording of looped playback
- **THEN** it reports the inter-onset interval mean, standard deviation, maximum deviation from nominal, and cumulative drift

### Requirement: Measured results on target platforms
The spike SHALL be evaluated on a real Android device (speaker or wired headphones, not Bluetooth) and on Linux desktop, with a 5-minute recording per test.

#### Scenario: Pass or fail reported
- **WHEN** all recordings are analyzed
- **THEN** the actual numbers and a pass/fail statement against each criterion are reported
- **AND** on failure the work stops and the numbers are reported, without adding a timer-based scheduler
