import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sequence_controller.dart';
import 'sequence_library_notifier.dart';

/// Screen displaying the list of saved [Sequence]s.
///
/// Allows users to load, rename, or delete sequences.
class SequenceLibraryScreen extends ConsumerWidget {
  const SequenceLibraryScreen({super.key});

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentName,
  ) async {
    final textController = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Sequence'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New Sequence Name'),
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(sequenceLibraryProvider.notifier).renameSequence(id, result);
      final active = ref.read(sequenceControllerProvider).sequence;
      if (active.id == id) {
        ref.read(sequenceControllerProvider.notifier).updateName(result);
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sequence'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(sequenceLibraryProvider.notifier).deleteSequence(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sequences = ref.watch(sequenceLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequence Library'),
      ),
      body: sequences.isEmpty
          ? const Center(child: Text('No saved sequences.'))
          : ListView.builder(
              itemCount: sequences.length,
              itemBuilder: (context, index) {
                final seq = sequences[index];
                return ListTile(
                  title: Text(seq.name),
                  subtitle: Text(
                    '${seq.entries.length} ${seq.entries.length == 1 ? 'entry' : 'entries'} | ${seq.loop ? 'Loop' : 'Play once'}',
                  ),
                  onTap: () {
                    ref.read(sequenceControllerProvider.notifier).setSequence(seq);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Rename',
                        onPressed: () => _showRenameDialog(context, ref, seq.id, seq.name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteDialog(context, ref, seq.id, seq.name),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
