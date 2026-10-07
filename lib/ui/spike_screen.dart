import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/metronome_settings.dart';
import '../domain/pattern.dart';
import 'playback_controller.dart';
import 'theme.dart';

/// Spike screen demonstrating audio-driven looped playback and boundary swapping.
///
/// Features:
/// - Sequencer start/stop
/// - Metronome start/stop
/// - Swap tempo/pattern buttons
/// - Live boundary swap feedback
class SpikeScreen extends ConsumerWidget {
  const SpikeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempo = ref.watch(tempoProvider);
    final sequencerState = ref.watch(sequencerPlaybackControllerProvider);
    final metronomeState = ref.watch(metronomePlaybackControllerProvider);
    final pattern = ref.watch(sequencerPatternProvider);
    final settings = ref.watch(metronomeSettingsProvider);

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
                  _buildStatusCard(
                    context,
                    tempo: tempo,
                    sequencerState: sequencerState,
                    metronomeState: metronomeState,
                  ),
                  const SizedBox(height: 16),

                  // Sequencer Controls Card
                  _buildSequencerCard(
                    context,
                    ref: ref,
                    pattern: pattern,
                    sequencerState: sequencerState,
                  ),
                  const SizedBox(height: 16),

                  // Metronome Controls Card
                  _buildMetronomeCard(
                    context,
                    ref: ref,
                    settings: settings,
                    metronomeState: metronomeState,
                  ),
                  const SizedBox(height: 16),

                  // Boundary Swap Controls Card
                  _buildBoundarySwapCard(
                    context,
                    ref: ref,
                    tempo: tempo,
                    pattern: pattern,
                  ),
                  const SizedBox(height: 16),

                  // Stop All & Architectural info
                  _buildFooter(
                    context,
                    ref: ref,
                    isPlaying: sequencerState.isPlaying || metronomeState.isPlaying,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required int tempo,
    required SequencerPlaybackState sequencerState,
    required MetronomePlaybackState metronomeState,
  }) {
    final theme = Theme.of(context);
    final isSequencer = sequencerState.isPlaying;
    final isMetronome = metronomeState.isPlaying;
    final isPlaying = isSequencer || isMetronome;

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

    final lastEvent = isSequencer
        ? sequencerState.lastEvent
        : (isMetronome ? metronomeState.lastEvent : 'Ready');

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
                  label: Text('$tempo BPM'),
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
                    lastEvent,
                    key: const Key('last_event_text'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isPlaying
                          ? kAmber
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    BuildContext context, {
    required WidgetRef ref,
    required Pattern pattern,
    required SequencerPlaybackState sequencerState,
  }) {
    final theme = Theme.of(context);
    final isSequencerRunning = sequencerState.isPlaying;
    final track0 = pattern.tracks[0];
    final displaySteps = pattern.stepCount;

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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pattern Step Visualizer
            Row(
              children: [
                Text('Pattern: ', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                ...List.generate(displaySteps, (index) {
                  final active = track0[index];
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
                        color: active
                            ? Colors.black
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Text(
                  pattern.name,
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
                    onPressed: isSequencerRunning
                        ? null
                        : () => ref
                            .read(sequencerPlaybackControllerProvider.notifier)
                            .start(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Sequencer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('stop_sequencer_button'),
                    onPressed: isSequencerRunning
                        ? () => ref
                            .read(sequencerPlaybackControllerProvider.notifier)
                            .stop()
                        : null,
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
    BuildContext context, {
    required WidgetRef ref,
    required MetronomeSettings settings,
    required MetronomePlaybackState metronomeState,
  }) {
    final theme = Theme.of(context);
    final isMetronomeRunning = metronomeState.isPlaying;

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
                  'Metronome (${settings.beatsPerBar}/4 Bar)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Beats: ', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                ...List.generate(settings.beatsPerBar, (index) {
                  final isAccent = index == 0 && settings.accent;
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
                        color: isMetronomeRunning
                            ? Colors.black
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Text(
                  settings.accent
                      ? 'Accent beat 1 (${settings.accentPitchHz.round()}Hz)'
                      : 'No accent',
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
                    onPressed: isMetronomeRunning
                        ? null
                        : () => ref
                            .read(metronomePlaybackControllerProvider.notifier)
                            .start(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Metronome'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('stop_metronome_button'),
                    onPressed: isMetronomeRunning
                        ? () => ref
                            .read(metronomePlaybackControllerProvider.notifier)
                            .stop()
                        : null,
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
    BuildContext context, {
    required WidgetRef ref,
    required int tempo,
    required Pattern pattern,
  }) {
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    onPressed: () {
                      final next = tempo == 120 ? 140 : 120;
                      ref.read(tempoProvider.notifier).setBpm(next);
                    },
                    icon: const Icon(Icons.speed),
                    label: Text(
                      'Swap Tempo (${tempo == 120 ? "→ 140" : "→ 120"})',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('swap_pattern_button'),
                    onPressed: () {
                      final currentIdx = spikePatternPresets.indexWhere(
                        (p) => p.id == pattern.id,
                      );
                      final nextIdx =
                          (currentIdx + 1) % spikePatternPresets.length;
                      ref
                          .read(sequencerPatternProvider.notifier)
                          .setPattern(spikePatternPresets[nextIdx]);
                    },
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
              children: [100, 120, 140, 160].map((bpm) {
                final isSelected = tempo == bpm;
                return ChoiceChip(
                  key: Key('bpm_chip_$bpm'),
                  label: Text('$bpm BPM'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(tempoProvider.notifier).setBpm(bpm);
                    }
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
              children: spikePatternPresets.map((preset) {
                final isSelected = pattern.id == preset.id;
                return ChoiceChip(
                  key: Key('pattern_chip_${preset.id}'),
                  label: Text(preset.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(sequencerPatternProvider.notifier)
                          .setPattern(preset);
                    }
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
    BuildContext context, {
    required WidgetRef ref,
    required bool isPlaying,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPlaying)
          FilledButton.tonalIcon(
            key: const Key('stop_all_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
              foregroundColor: Colors.red.shade200,
            ),
            onPressed: () => stopAllPlayback(ref),
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
