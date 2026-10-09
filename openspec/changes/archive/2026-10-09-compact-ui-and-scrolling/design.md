## Context

See `proposal.md` for motivation. The Rhythm Box UI runs primarily on mobile (Android) and secondarily on Linux desktop. Currently, both the Metronome and Sequencer screens dedicate substantial vertical real estate to redundant tempo titles, and the Sequencer controls and step grid overflow in landscape orientation because the body is constrained by an unscrollable `Column` and `Expanded` widgets.

## Goals / Non-Goals

**Goals:**
- Free vertical space on both screens by relocating tempo numbers to the top bar.
- Reposition the Metronome Play/Stop control inline with beat indicators as an icon button.
- Reorder Sequencer controls into `[Toggle Labels] -> [Step Slider] -> [Clear] -> [Save] -> [Play/Stop]` with compact icon buttons.
- Allow hiding track labels in the Sequencer to grant 100% width to step cells on narrow mobile screens, defaulting to hidden on Android/iOS and visible on desktop.
- Enable vertical scrolling on the Sequencer screen so all controls and step selectors are accessible in landscape orientation.

**Non-Goals:**
- Persisting track label visibility across app restarts (session-only).
- Changing audio engine clocking, loop swap timing, or synthesis algorithms.
- Custom landscape two-column layout.

## Decisions

### Decision 1: Top Bar BPM Display Pattern
- **Choice**: Display the current BPM as a styled subtext/badge in the `AppBar.title` (e.g. `Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text('Sequencer', overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Container(... Text('$tempo BPM'))])`).
- **Rationale**: Keeps tempo visible at all times while eliminating the 40dp `'Tempo: 120 BPM'` header card above the slider. Using `Flexible` with ellipsis protects against RenderFlex overflow on 360dp phone screens where the AppBar also hosts the sound kit dropdown and pattern library action.
- **Alternatives Considered**: Subtitle in AppBar (takes additional vertical space in toolbar); inline plain text (less visually distinct from screen title).

### Decision 2: Inline Metronome Play/Stop Control
- **Choice**: Place an `IconButton.filled` or `IconButton.filledTonal` (48x48dp touch target) on the same horizontal row as the beat circles in `BeatIndicator`:
  `Row(mainAxisAlignment: MainAxisAlignment.center, children: [...beatCircles, SizedBox(width: 16), playStopButton])`.
- **Rationale**: Merges beat feedback and playback initiation into a single ergonomic cluster, eliminating the standalone full-width playback button and saving ~60dp vertical space.
- **Alternatives Considered**: Placing play/stop in the AppBar (too far from beat indicators and conflicts with import/export actions).

### Decision 3: Sequencer Controls Order and Icon-Only Actions
- **Choice**: Reorder `SequencerControls` from left to right:
  1. Track labels toggle (`IconButton`, tooltip: "Toggle track labels")
  2. Step count selector (`Text('Steps: $stepCount')` + `Slider`)
  3. Clear pattern (`IconButton(icon: Icon(Icons.delete_outline))`, tooltip: "Clear pattern")
  4. Save pattern (`IconButton(icon: Icon(Icons.save_outlined))`, tooltip: "Save pattern")
  5. Play/Stop toggle (`IconButton(icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow))`, tooltip: "Play" / "Stop")
- **Rationale**: Moving Play/Stop to the right aligns with modern media player conventions. Converting Clear and Save from `ElevatedButton` with text to icon buttons frees ~120dp horizontal space, preventing clipping when the step slider is expanded.

### Decision 4: Track Labels Visibility State & Dynamic Grid Sizing
- **Choice**: Introduce a lightweight Riverpod notifier/provider `trackLabelsVisibleProvider` initialized via `defaultTargetPlatform`:
  `defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS ? false : true`.
- **Rationale**: Clean reactive binding across `SequencerControls`, `StepPlayhead`, and `StepGrid`. When hidden, both `StepPlayhead` ruler and `StepGrid` drop the 76dp left label width to 0, letting step tap targets stretch across the entire screen width.
- **Alternatives Considered**: Screen-level StatefulWidget local state (requires lifting state or drilling callbacks through multiple layers); SharedPreferences persistence (unnecessary complexity for a simple viewing toggle).

### Decision 5: Fixed Track Row Heights and Scrollable Viewport
- **Choice**: Change `StepGrid` track rows from `Expanded` to fixed height (36.0dp per row, ~288dp total for 8 tracks). Wrap the `SequencerScreen` body in a `SingleChildScrollView`.
- **Rationale**: In Flutter, placing `Expanded` inside a `SingleChildScrollView` throws an unbounded height runtime exception. Using fixed row heights guarantees that each track button retains a touch-accessible height (36dp) and allows smooth vertical scrolling in landscape orientation (~360-400dp screen height). In portrait mode (~800dp), all content fits comfortably on screen without scrolling.
- **Alternatives Considered**: `LayoutBuilder` with conditional scrolling (more complex without ergonomic advantage over fixed row height).

## Risks / Trade-offs

- **[Risk] Widget test failures on text finders**: Existing tests look for `find.text('Play')`, `find.text('Stop')`, `find.text('Clear')`, and `find.text('Tempo: 121 BPM')`.
  - **Mitigation**: Update test finders in `metronome_screen_test.dart` and `sequencer_screen_test.dart` to find by `Key` (`Key('play_stop_button')`, `Key('clear_pattern_button')`) and verify the updated BPM format.
- **[Risk] AppBar title overflow on narrow devices**: Adding BPM to Sequencer AppBar alongside the kit dropdown could overflow if screen width is narrow (<340dp).
  - **Mitigation**: Wrap title in `Flexible` with `TextOverflow.ellipsis` and maintain compact padding on the kit dropdown.
