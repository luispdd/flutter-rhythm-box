import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/services/library_import_export_service.dart';
import 'package:rhythm_box/ui/metronome_controller.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/hold_timer_icon_button.dart';

class MetronomeScreen extends ConsumerWidget {
  const MetronomeScreen({super.key});

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final service = ref.read(libraryImportExportServiceProvider);
    final result = await service.exportLibrary();

    if (!context.mounted) return;

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export')),
      );
    } else if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${result.patternCount} patterns and ${result.sequenceCount} sequences',
          ),
        ),
      );
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final service = ref.read(libraryImportExportServiceProvider);
    final prepResult = await service.pickAndValidateImportFile();

    if (!context.mounted) return;

    if (prepResult.isCanceled) {
      return;
    }

    if (!prepResult.isReady || prepResult.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prepResult.errorMessage ?? 'Import validation failed'),
        ),
      );
      return;
    }

    final data = prepResult.data!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace all data?'),
        content: Text(
          data.patterns.isEmpty && data.sequences.isEmpty
              ? 'This file contains 0 patterns and 0 sequences. Importing will permanently delete and clear all saved patterns and sequences on this device.'
              : 'This file contains ${data.patterns.length} patterns and ${data.sequences.length} sequences.\n\nImporting will permanently delete everything currently saved on this device and replace it with the contents of the file.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_import_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_import_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Replace All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final execResult = await service.executeImport(data);
      if (!context.mounted) return;

      if (execResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${execResult.patternCount} patterns and ${execResult.sequenceCount} sequences',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(execResult.errorMessage ?? 'Import execution failed'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempo = ref.watch(tempoProvider);
    final metronomeState = ref.watch(metronomeControllerProvider);
    final settings = metronomeState.settings;
    final isPlaying = metronomeState.isPlaying;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Metronome',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$tempo BPM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('export_library_button'),
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export Library',
            onPressed: () => _handleExport(context, ref),
          ),
          IconButton(
            key: const Key('import_library_button'),
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import Library',
            onPressed: () => _handleImport(context, ref),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            HoldTimerIconButton(
              key: const Key('tempo_decrement_button'),
              icon: Icons.remove,
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
            HoldTimerIconButton(
              key: const Key('tempo_increment_button'),
              icon: Icons.add,
              onPressed: () => ref.read(tempoProvider.notifier).increment(),
            ),
          ],
        ),
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
          children: [
            ...List.generate(beatsPerBar, (index) {
              final isActive = index == activeBeat;
              final isAccent = index == 0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
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
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('play_stop_button'),
              iconSize: 28,
              onPressed: () =>
                  ref.read(metronomeControllerProvider.notifier).togglePlayback(),
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              tooltip: isPlaying ? 'Stop' : 'Play',
            ),
          ],
        );
      },
    );
  }
}
