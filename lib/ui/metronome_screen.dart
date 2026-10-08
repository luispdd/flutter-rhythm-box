import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/ui/metronome_controller.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/tempo_controller.dart';

class MetronomeScreen extends ConsumerWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempo = ref.watch(tempoProvider);
    final metronomeState = ref.watch(metronomeControllerProvider);
    final settings = metronomeState.settings;
    final isPlaying = metronomeState.isPlaying;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTempoControls(context, ref, tempo),
                const SizedBox(height: 24),
                BeatIndicator(
                  tempo: tempo,
                  beatsPerBar: settings.beatsPerBar,
                  isPlaying: isPlaying,
                ),
                const SizedBox(height: 24),
                _buildPlaybackControls(context, ref, isPlaying),
                const SizedBox(height: 24),
                _buildSettingsControls(context, ref, settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTempoControls(BuildContext context, WidgetRef ref, int tempo) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Tempo: $tempo BPM',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('tempo_decrement_button'),
                  icon: const Icon(Icons.remove),
                  onPressed: () => ref.read(tempoProvider.notifier).decrement(),
                ),
                Expanded(
                  child: Slider(
                    key: const Key('tempo_slider'),
                    value: tempo.toDouble(),
                    min: Tempo.minBpm.toDouble(),
                    max: Tempo.maxBpm.toDouble(),
                    onChanged: (value) =>
                        ref.read(tempoProvider.notifier).setBpm(value.toInt()),
                  ),
                ),
                IconButton(
                  key: const Key('tempo_increment_button'),
                  icon: const Icon(Icons.add),
                  onPressed: () => ref.read(tempoProvider.notifier).increment(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context, WidgetRef ref, bool isPlaying) {
    return ElevatedButton.icon(
      key: const Key('play_stop_button'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16.0),
      ),
      onPressed: () => ref.read(metronomeControllerProvider.notifier).togglePlayback(),
      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
      label: Text(
        isPlaying ? 'Stop' : 'Play',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildSettingsControls(BuildContext context, WidgetRef ref, MetronomeSettings settings) {
    final controller = ref.read(metronomeControllerProvider.notifier);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            // Beats per bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Beats per bar: ${settings.beatsPerBar}'),
                Slider(
                  key: const Key('beats_per_bar_slider'),
                  value: settings.beatsPerBar.toDouble(),
                  min: MetronomeSettings.minBeatsPerBar.toDouble(),
                  max: MetronomeSettings.maxBeatsPerBar.toDouble(),
                  divisions: MetronomeSettings.maxBeatsPerBar - MetronomeSettings.minBeatsPerBar,
                  onChanged: (val) => controller.setBeatsPerBar(val.toInt()),
                ),
              ],
            ),
            const Divider(),
            // Accent
            SwitchListTile(
              key: const Key('accent_toggle'),
              title: const Text('Accent beat 1'),
              value: settings.accent,
              onChanged: (val) => controller.toggleAccent(),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            // Waveform
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Waveform'),
                const SizedBox(height: 8),
                SegmentedButton<Waveform>(
                  key: const Key('waveform_segmented_button'),
                  segments: const [
                    ButtonSegment(value: Waveform.sine, label: Text('Sine')),
                    ButtonSegment(value: Waveform.triangle, label: Text('Triangle')),
                    ButtonSegment(value: Waveform.square, label: Text('Square')),
                  ],
                  selected: {settings.waveform},
                  onSelectionChanged: (Set<Waveform> newSelection) {
                    controller.setWaveform(newSelection.first);
                  },
                ),
              ],
            ),
            const Divider(),
            // Pitch
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pitch: ${settings.pitchHz.round()} Hz'),
                Slider(
                  key: const Key('pitch_slider'),
                  value: settings.pitchHz,
                  min: MetronomeSettings.minPitchHz,
                  max: MetronomeSettings.maxPitchHz,
                  onChanged: (val) => controller.setPitchHz(val),
                ),
              ],
            ),
            const Divider(),
            // Decay
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decay: ${settings.decayMs.round()} ms'),
                Slider(
                  key: const Key('decay_slider'),
                  value: settings.decayMs,
                  min: MetronomeSettings.minDecayMs,
                  max: MetronomeSettings.maxDecayMs,
                  onChanged: (val) => controller.setDecayMs(val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BeatIndicator extends ConsumerWidget {
  final int tempo;
  final int beatsPerBar;
  final bool isPlaying;

  const BeatIndicator({
    super.key,
    required this.tempo,
    required this.beatsPerBar,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(audioEngineProvider);
    final theme = Theme.of(context);

    return StreamBuilder<Duration>(
      stream: engine.positionStream,
      builder: (context, snapshot) {
        int activeBeat = -1;

        if (isPlaying && snapshot.hasData) {
          final positionMs = snapshot.data!.inMilliseconds;
          final msPerBeat = 60000 / tempo;
          activeBeat = (positionMs / msPerBeat).floor() % beatsPerBar;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(beatsPerBar, (index) {
            final isActive = index == activeBeat;
            final isAccent = index == 0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? (isAccent ? Colors.amber : Colors.amber.shade700)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Colors.amberAccent
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive
                      ? Colors.black
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
