## Why

On mobile devices, vertical screen space is precious, and horizontal (landscape) orientation currently causes the Sequencer screen's controls and step grid to overflow or squish, making the step grid unreachable. Moving the tempo indicator to the top bar, streamlining action buttons to icon-only controls, grouping playback with beat counters, making track labels collapsible, and introducing scrollability on the Sequencer screen maximizes usable workspace for instrument practice.

## What Changes

- **Metronome Top Bar**: Move current BPM display into the Metronome screen's top bar (as a subtext or badge beside the title) and remove the redundant `'Tempo: 120 BPM'` title above the slider.
- **Metronome Play/Stop Control**: Convert the full-width `'Play'` / `'Stop'` button into an icon-only button located directly to the right of the beat indicator numbers.
- **Sequencer Top Bar**: Move current BPM display into the Sequencer screen's top bar (with truncation protection against long kit/appbar titles) and remove the `'Tempo: 120 BPM'` title above the slider.
- **Sequencer Controls Order & Icons**: Reorder sequencer controls to:
  `[Track Labels Toggle]` -> `[Step Count Slider]` -> `[Clear Icon]` -> `[Save Icon]` -> `[Play/Stop Icon]`.
  Clear, Save, and Play/Stop buttons are rendered as icon-only controls.
- **Collapsible Track Labels**: Add an icon button in the sequencer controls to toggle track labels on/off. When hidden, the step grid and playhead expand to fill 100% of the horizontal width.
  - Default: Hidden on mobile (`TargetPlatform.android` / `iOS`), visible on desktop (`Linux`).
  - Scope: Session-only (in-memory state, no persistence required).
- **Sequencer Screen Scrolling**: Make the Sequencer screen vertically scrollable (`SingleChildScrollView`) with fixed ergonomic track heights (e.g. 36-38dp), enabling comfortable use and accessibility in horizontal / landscape mode.

## Non-goals

- Persisting track label visibility preference across restarts.
- Adding landscape-specific split layouts (e.g. two-column view).
- Modifying audio synthesis, clocking, or loop swap mechanisms.

## Capabilities

### Modified Capabilities
- `metronome`: Update metronome UI requirements for top-bar BPM display and inline beat-indicator play/stop button.
- `sequencer`: Update sequencer UI requirements for top-bar BPM display, icon-only controls order, collapsible track labels with platform defaults, and vertical scrollability.

## Impact

- `lib/ui/metronome_screen.dart`: AppBar title, tempo slider card layout, beat indicator row + play/stop icon button.
- `lib/ui/sequencer_screen.dart`: AppBar title, tempo slider card layout, scrollable body.
- `lib/ui/sequencer_controls.dart`: Reordered control elements, icon buttons for clear/save/play/stop, and track label toggle button.
- `lib/ui/step_grid.dart` & `lib/ui/step_playhead.dart`: Conditional track label rendering and fixed row height layout.
- `test/ui/metronome_screen_test.dart` & `test/ui/sequencer_screen_test.dart`: Updated widget test matchers for icon buttons and new BPM text locations.
