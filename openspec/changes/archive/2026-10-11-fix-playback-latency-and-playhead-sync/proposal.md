## Why

When starting playback after idle, audio output is muted or missing for the first 1–2 beats (noticeable on HDMI/external sinks) because the underlying audio device suspends on idle and wakes up after playback is already scheduled. Furthermore, editing sequencer steps during playback often takes 2 full loop cycles to take effect instead of applying on the very next loop, and the step playhead indicator becomes erratic and out-of-sync during and after edits because visual position reporting is coupled to retiring voice handles rather than the engine's master timeline.

## What Changes

- **Audio Device Keep-Alive & Start Preroll**: Configure the audio engine to keep the audio device active while the app is in the foreground (`setAudioDeviceIdleTimeout(null)`), preventing hardware sink sleep/clock drops. Increase initial start pre-roll lead time when starting from a cold stop.
- **Continuous Master-Clock Playhead Stream**: Drive `positionStream` directly from the engine's continuous audio timeline anchor (`(getEngineTime() - anchorTime) % loopDuration`) instead of polling transient voice handles with `getPosition(handle)`, ensuring seamless, monotonic playhead tracking across loop boundary swaps.
- **Decoupled Step Persistence & Accurate Boundary Scheduling**: Trigger pattern storage saves (`saveWorkingPattern`) asynchronously in the background so disk I/O does not delay audio re-rendering, and sample engine time after buffer preparation in the swap path so edits consistently land on the immediate next loop boundary.

## Capabilities

### Modified Capabilities

- `audio-engine`: Add audio device keep-alive behavior and continuous engine-clock-based position stream reporting that survives buffer swaps without discontinuities or handle invalidation freezes.
- `sequencer`: Ensure live pattern edits apply at the immediate next loop boundary without skipping extra cycles due to persistence latency, and ensure the playhead indicator remains locked to playback across pattern swaps.

## Impact

- Affected code: `lib/audio/soloud_audio_engine.dart`, `lib/ui/sequencer_controller.dart`, `lib/ui/step_playhead.dart`.
- Dependencies: No new dependencies. Uses existing `flutter_soloud` APIs and Riverpod state management.
- Breaking changes: None.

## Non-goals

- Sub-loop / immediate intra-loop live step insertion (changes remain quantized to the loop boundary as designed).
- Low-latency live finger-drumming or MIDI input.
- Keeping audio hardware active when the app is backgrounded or minimized (normal OS lifecycle suspension still applies).
