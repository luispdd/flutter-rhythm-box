import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/sequencer_controls.dart';
import 'package:rhythm_box/ui/step_playhead.dart';
import 'package:rhythm_box/ui/tempo_controller.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/ui/hold_timer_icon_button.dart';

import 'package:rhythm_box/persistence/kit_repository.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';
import 'package:rhythm_box/ui/pattern_library_screen.dart';

class SequencerScreen extends ConsumerWidget {
  const SequencerScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(sequencerControllerProvider);
    final tempo = ref.read(tempoProvider);
    final textController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Pattern'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Pattern Name'),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop(name);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final newPattern = state.pattern.copyWith(
        id: DateTime.now().toIso8601String(),
        name: result,
        tempoBpm: tempo,
      );
      ref.read(patternLibraryProvider.notifier).savePattern(newPattern);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pattern "$result" saved')),
      );
    }
  }

  Future<void> _showClearConfirmationDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Pattern'),
        content: const Text(
          'Are you sure you want to clear the working pattern? All active steps will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(sequencerControllerProvider.notifier).clearPattern();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sequencerControllerProvider);
    final tempo = ref.watch(tempoProvider);
    final kitRepo = ref.watch(kitRepositoryProvider);
    final availableKits = kitRepo.availableKits;
    final currentKitId = state.pattern.kitId;
    final selectedKitId = availableKits.any((k) => k.id == currentKitId)
        ? currentKitId
        : kitRepo.defaultKit.id;

    final showTrackLabels = ref.watch(trackLabelsVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Sequencer',
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('sequencerKitSelector'),
                value: selectedKitId,
                onChanged: (newKitId) {
                  if (newKitId != null) {
                    ref.read(sequencerControllerProvider.notifier).setKit(newKitId);
                  }
                },
                items: availableKits.map((kit) {
                  return DropdownMenuItem<String>(
                    value: kit.id,
                    child: Text(kit.name, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: 'Pattern Library',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PatternLibraryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    HoldTimerIconButton(
                      icon: Icons.remove,
                      onPressed: () => ref.read(tempoProvider.notifier).decrement(),
                    ),
                    Expanded(
                      child: Slider(
                        value: tempo.toDouble(),
                        min: Tempo.minBpm.toDouble(),
                        max: Tempo.maxBpm.toDouble(),
                        onChanged: (value) =>
                            ref.read(tempoProvider.notifier).setBpm(value.toInt()),
                      ),
                    ),
                    HoldTimerIconButton(
                      icon: Icons.add,
                      onPressed: () => ref.read(tempoProvider.notifier).increment(),
                    ),
                  ],
                ),
              ),
            ),
            SequencerControls(
              isPlaying: state.isPlaying,
              stepCount: state.pattern.stepCount,
              showTrackLabels: showTrackLabels,
              onToggleTrackLabels: () {
                ref.read(trackLabelsVisibleProvider.notifier).toggle();
              },
              onPlayPauseToggled: () {
                ref.read(sequencerControllerProvider.notifier).togglePlay();
              },
              onStepCountChanged: (val) {
                ref.read(sequencerControllerProvider.notifier).setStepCount(val);
              },
              onClearPattern: () => _showClearConfirmationDialog(context, ref),
              onSavePattern: () => _showSaveDialog(context, ref),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: StepPlayhead(),
            ),
          ],
        ),
      ),
    );
  }
}
