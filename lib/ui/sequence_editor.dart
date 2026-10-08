import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pattern.dart';
import 'pattern_library_notifier.dart';
import 'sequence_controller.dart';

/// Interactive editor widget for viewing, reordering, and editing sequence entries.
class SequenceEditor extends ConsumerWidget {
  const SequenceEditor({super.key});

  Future<void> _showPatternPicker(BuildContext context, WidgetRef ref) async {
    final patterns = ref.read(patternLibraryProvider);
    if (patterns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No saved patterns in library. Save patterns in the Sequencer tab first.',
          ),
        ),
      );
      return;
    }

    final selected = await showDialog<Pattern>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pattern to Sequence'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: patterns.length,
            itemBuilder: (context, index) {
              final pattern = patterns[index];
              return ListTile(
                title: Text(pattern.name),
                subtitle: Text(
                  'Tempo: ${pattern.tempoBpm} BPM | Steps: ${pattern.stepCount}',
                ),
                onTap: () => Navigator.of(context).pop(pattern),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      ref.read(sequenceControllerProvider.notifier).addEntry(selected.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sequenceState = ref.watch(sequenceControllerProvider);
    final sequence = sequenceState.sequence;
    final patterns = ref.watch(patternLibraryProvider);
    final patternMap = {for (final p in patterns) p.id: p};

    final isPlaying = sequenceState.isPlaying;
    final currentPlayingIndex = sequenceState.currentEntryIndex;

    return Column(
      children: [
        // Editor Controls Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Loop Mode'),
                  subtitle: Text(sequence.loop ? 'Plays continuously' : 'Plays once then stops'),
                  value: sequence.loop,
                  onChanged: (value) {
                    ref.read(sequenceControllerProvider.notifier).setLoop(value);
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton.icon(
                key: const Key('add_entry_button'),
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
                onPressed: () => _showPatternPicker(context, ref),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Entries List
        Expanded(
          child: sequence.entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No entries in this sequence.\nTap "Add Entry" to add patterns from your library.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  key: const Key('sequence_entries_list'),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: sequence.entries.length,
                  onReorderItem: (oldIndex, newIndex) {
                    ref
                        .read(sequenceControllerProvider.notifier)
                        .reorderEntries(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final entry = sequence.entries[index];
                    final pattern = patternMap[entry.patternId];
                    final isEntryActive = isPlaying && currentPlayingIndex == index;

                    return Card(
                      key: ValueKey('entry_${index}_${entry.patternId}'),
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      color: isEntryActive
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: isEntryActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: ListTile(
                        leading: isEntryActive
                            ? Icon(
                                Icons.volume_up,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : CircleAvatar(
                                radius: 14,
                                child: Text('${index + 1}'),
                              ),
                        title: Text(
                          pattern != null ? pattern.name : 'Unknown Pattern',
                          style: TextStyle(
                            fontWeight: isEntryActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          pattern != null
                              ? 'Tempo: ${pattern.tempoBpm} BPM | Steps: ${pattern.stepCount}'
                              : 'Referenced pattern was removed',
                          style: TextStyle(
                            color: pattern == null ? Colors.orange : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: ValueKey('decrement_$index'),
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Decrease repeats',
                              onPressed: entry.repeats > 1
                                  ? () {
                                      ref
                                          .read(sequenceControllerProvider.notifier)
                                          .setEntryRepeats(index, entry.repeats - 1);
                                    }
                                  : null,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 32),
                              alignment: Alignment.center,
                              child: Text(
                                '${entry.repeats}x',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              key: ValueKey('increment_$index'),
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Increase repeats',
                              onPressed: entry.repeats < 99
                                  ? () {
                                      ref
                                          .read(sequenceControllerProvider.notifier)
                                          .setEntryRepeats(index, entry.repeats + 1);
                                    }
                                  : null,
                            ),
                            IconButton(
                              key: ValueKey('delete_$index'),
                              icon: const Icon(Icons.close),
                              tooltip: 'Remove entry',
                              onPressed: () {
                                ref
                                    .read(sequenceControllerProvider.notifier)
                                    .removeEntry(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
