## ADDED Requirements

### Requirement: Audio output device keep-alive
The engine SHALL keep the hardware audio output device active during foreground execution, preventing sink sleep or digital clock link suspension during idle playback pauses.

#### Scenario: Playback start after idle
- **WHEN** a loop is started after the application has been idle for more than 500 ms
- **THEN** the initial audio sound onsets are immediately audible without sink wake-up clipping or dropped beats

### Requirement: Continuous engine-anchored position reporting
The engine SHALL provide a position stream that reflects continuous, monotonic elapsed playback time within the loop cycle anchored to the master engine clock, maintaining visual continuity across buffer swaps without dropping to zero or stalling when voice handles transition.

#### Scenario: Position stream during buffer swap
- **WHEN** a loop buffer swap occurs at a loop boundary
- **THEN** the position stream continues reporting smoothly across the transition boundary without freezing, resetting prematurely to 0, or emitting invalid positions from retired voice handles
