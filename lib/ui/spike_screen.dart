import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/playback_state.dart';
import 'playback_controller.dart';
import 'theme.dart';

/// Spike screen demonstrating audio-driven looped playback and boundary swapping.
///
/// Implements Task 4.1:
/// - Sequencer start/stop
/// - Metronome start/stop
/// - Swap tempo/pattern buttons
/// - Live boundary swap feedback
class SpikeScreen extends ConsumerWidget {
  const SpikeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackNotifierProvider);
    final notifier = ref.read(playbackNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhythm Box - Timing Spike'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status & Diagnostics Card
                  _buildStatusCard(context, state),
                  const SizedBox(height: 16),

                  // Sequencer Controls Card
                  _buildSequencerCard(context, state, notifier),
                  const SizedBox(height: 16),

                  // Metronome Controls Card
                  _buildMetronomeCard(context, state, notifier),
                  const SizedBox(height: 16),

                  // Boundary Swap Controls Card
                  _buildBoundarySwapCard(context, state, notifier),
                  const SizedBox(height: 16),

                  // Stop All & Architectural info
                  _buildFooter(context, state, notifier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, PlaybackState state) {
    final theme = Theme.of(context);
    final isSequencer = state.mode == PlaybackMode.sequencer;
    final isMetronome = state.mode == PlaybackMode.metronome;
    final isPlaying = state.isPlaying;

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (isSequencer) {
      badgeColor = kAmber;
      badgeText = 'SEQUENCER ACTIVE';
      badgeIcon = Icons.graphic_eq;
    } else if (isMetronome) {
      badgeColor = kAmberLight;
      badgeText = 'METRONOME ACTIVE';
      badgeIcon = Icons.access_time;
    } else {
      badgeColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
      badgeText = 'IDLE';
      badgeIcon = Icons.stop_circle_outlined;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  badgeText,
                  key: const Key('status_badge_text'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${state.bpm.round()} BPM'),
                  backgroundColor: kAmber.withValues(alpha: 0.15),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.lastEvent,
                    key: const Key('last_event_text'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isPlaying ? kAmber : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequencerCard(
    BuildContext context,
    PlaybackState state,
    PlaybackNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isSequencerRunning = state.mode == PlaybackMode.sequencer;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '16th-Note Sequencer',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pattern Step Visualizer
            Row(
              children: [
                Text('Pattern: ', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                ...List.generate(state.patternPreset.steps.length, (index) {
                  final active = state.patternPreset.steps[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active
                          ? (isSequencerRunning ? kAmber : kAmberDark)
                          : kSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: active ? kAmberLight : theme.colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Text(
                  state.patternPreset.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('start_sequencer_button'),
                    onPressed: isSequencerRunning ? null : () => notifier.startSequencer(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Sequencer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('stop_sequencer_button'),
                    onPressed: isSequencerRunning ? () => notifier.stopSequencer() : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Sequencer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetronomeCard(
    BuildContext context,
    PlaybackState state,
    PlaybackNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isMetronomeRunning = state.mode == PlaybackMode.metronome;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Metronome (4/4 Bar)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Beats: ', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                ...List.generate(state.beatsPerBar, (index) {
                  final isAccent = index == 0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isMetronomeRunning
                          ? (isAccent ? kAmber : kAmberDark)
                          : kSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAccent ? kAmberLight : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isMetronomeRunning ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Text(
                  'Accent beat 1 (2500Hz)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('start_metronome_button'),
                    onPressed: isMetronomeRunning ? null : () => notifier.startMetronome(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Metronome'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('stop_metronome_button'),
                    onPressed: isMetronomeRunning ? () => notifier.stopMetronome() : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Metronome'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoundarySwapCard(
    BuildContext context,
    PlaybackState state,
    PlaybackNotifier notifier,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Live Boundary Swap Controls',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Swaps buffer at next loop boundary on audio engine clock. No audible clicks or gaps.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('swap_tempo_button'),
                    onPressed: () => notifier.toggleTempo(),
                    icon: const Icon(Icons.speed),
                    label: Text('Swap Tempo (${state.bpm.round() == 120 ? "→ 140" : "→ 120"})'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('swap_pattern_button'),
                    onPressed: () => notifier.togglePattern(),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Swap Pattern'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Quick Tempo Preset:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [100.0, 120.0, 140.0, 160.0].map((bpm) {
                final isSelected = state.bpm == bpm;
                return ChoiceChip(
                  key: Key('bpm_chip_${bpm.round()}'),
                  label: Text('${bpm.round()} BPM'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) notifier.swapTempo(bpm);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('Pattern Preset:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: PatternPreset.values.map((preset) {
                final isSelected = state.patternPreset == preset;
                return ChoiceChip(
                  key: Key('pattern_chip_${preset.name}'),
                  label: Text(preset.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) notifier.swapPattern(preset);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    PlaybackState state,
    PlaybackNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isPlaying)
          FilledButton.tonalIcon(
            key: const Key('stop_all_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
              foregroundColor: Colors.red.shade200,
            ),
            onPressed: () => notifier.stop(),
            icon: const Icon(Icons.stop_circle),
            label: const Text('Stop All Playback'),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified, size: 20, color: kAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Timing verified: Audio-driven buffer looping via SoLoud mixer clock. 0 Dart timers triggering audio.',
                  style: TextStyle(
                    fontSize: 11,
                    color: kTextPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
