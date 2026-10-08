import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sequence.dart';
import '../persistence/kit_repository.dart';
import 'sequence_controller.dart';
import 'sequence_editor.dart';
import 'sequence_library_notifier.dart';
import 'sequence_library_screen.dart';

/// Screen representing the Sequences tab.
///
/// Provides top playback controls, save/library actions, and the [SequenceEditor].
class SequencesScreen extends ConsumerWidget {
  const SequencesScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final currentSeq = ref.read(sequenceControllerProvider).sequence;
    final textController = TextEditingController(text: currentSeq.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Sequence'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Sequence Name'),
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

    if (result != null && result.isNotEmpty) {
      final id = currentSeq.id.isNotEmpty
          ? currentSeq.id
          : 'seq_${DateTime.now().millisecondsSinceEpoch}';
      final toSave = currentSeq.copyWith(id: id, name: result);
      await ref.read(sequenceLibraryProvider.notifier).saveSequence(toSave);
      ref.read(sequenceControllerProvider.notifier).setSequence(toSave);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved sequence "$result"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sequenceState = ref.watch(sequenceControllerProvider);
    final sequence = sequenceState.sequence;
    final isPlaying = sequenceState.isPlaying;
    final isLoading = sequenceState.isLoading;

    final kitRepo = ref.watch(kitRepositoryProvider);
    final availableKits = kitRepo.availableKits;
    final currentKitId = sequence.kitId;
    final selectedKitId = availableKits.any((k) => k.id == currentKitId)
        ? currentKitId
        : kitRepo.defaultKit.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(sequence.name.isNotEmpty ? sequence.name : 'Sequences'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('sequencesKitSelector'),
                value: selectedKitId,
                onChanged: (newKitId) {
                  if (newKitId != null) {
                    ref.read(sequenceControllerProvider.notifier).setKit(newKitId);
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
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'New Sequence',
            onPressed: () {
              ref.read(sequenceControllerProvider.notifier).setSequence(
                    Sequence.empty(
                      id: 'seq_${DateTime.now().millisecondsSinceEpoch}',
                      name: 'New Sequence',
                    ),
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Sequence',
            onPressed: () => _showSaveDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: 'Sequence Library',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SequenceLibraryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Playback Control Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                FilledButton.icon(
                  key: const Key('sequence_play_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.red : Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    isLoading
                        ? 'Rendering...'
                        : isPlaying
                            ? 'Stop'
                            : 'Play Sequence',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          ref.read(sequenceControllerProvider.notifier).togglePlay();
                        },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sequence.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${sequence.entries.length} ${sequence.entries.length == 1 ? 'entry' : 'entries'} • ${sequence.loop ? 'Looping' : 'Play-once'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: SequenceEditor(),
          ),
        ],
      ),
    );
  }
}
