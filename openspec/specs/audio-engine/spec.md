# Audio Engine Specification

## Purpose

Defines the behavior contract of the audio engine seam: starting, stopping and swapping gapless loops, including edits that arrive faster than loop boundaries, so any engine implementation can replace the current one.

## Requirements

### Requirement: Start, stop and playing state
The engine SHALL start a buffer as a gapless loop, report whether a loop is playing, and stop immediately without waiting for a loop boundary.

#### Scenario: Start
- **WHEN** a loop is started on a stopped engine
- **THEN** the engine reports playing

#### Scenario: Immediate stop with a swap pending
- **WHEN** a swap is pending and stop is called
- **THEN** all sound ceases immediately, including the loop being retired, and the engine reports not playing

### Requirement: Swap at the next boundary
A swap request SHALL take effect at the next loop boundary of the currently audible loop and SHALL NOT interrupt the audible loop before that boundary.

#### Scenario: Swap mid-loop
- **WHEN** a swap is requested halfway through a loop
- **THEN** the current loop plays to its end and the new loop starts there, with no audible gap or doubled hit

#### Scenario: Swap to a different length
- **WHEN** the new loop has a different length (for example after a tempo change)
- **THEN** the boundary is derived from the audible loop's length, and the new loop plays at its own length from that boundary

### Requirement: Latest swap wins
If several swaps are requested before a boundary, only the most recent SHALL play at that boundary, and earlier pending buffers SHALL never become audible.

#### Scenario: Three edits in one loop
- **WHEN** three swaps A, B, C are requested before the next boundary
- **THEN** C starts at that boundary and neither A nor B is ever heard

#### Scenario: Audible loop not cut by a later swap
- **WHEN** a second swap is requested while the first is still pending
- **THEN** the audible loop keeps playing until the boundary and is not cut early

### Requirement: Resources are released
Buffers no longer audible or pending SHALL be released, and repeated swaps SHALL NOT grow memory without bound.

#### Scenario: Many swaps
- **WHEN** 100 swaps occur during one run
- **THEN** at most the audible and one pending buffer are held at any time

### Requirement: Testable without audio hardware
The engine contract SHALL be exercisable in headless tests through a fake implementation.

#### Scenario: Fake engine in tests
- **WHEN** playback logic is tested with the engine provider overridden by a fake
- **THEN** the test runs without a native audio device
