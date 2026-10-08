import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/ui/pattern_library_notifier.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/tempo_controller.dart';

class PatternLibraryScreen extends ConsumerWidget {
  const PatternLibraryScreen({super.key});

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, String id, String currentName) async {
    final textController = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Pattern'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New Pattern Name'),
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
      ref.read(patternLibraryProvider.notifier).renamePattern(id, result);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pattern'),
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
      ref.read(patternLibraryProvider.notifier).deletePattern(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(patternLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Library'),
      ),
      body: patterns.isEmpty
          ? const Center(child: Text('No saved patterns.'))
          : ListView.builder(
              itemCount: patterns.length,
              itemBuilder: (context, index) {
                final pattern = patterns[index];
                return ListTile(
                  title: Text(pattern.name),
                  subtitle: Text('Tempo: ${pattern.tempoBpm} BPM | Steps: ${pattern.stepCount}'),
                  onTap: () {
                    ref.read(sequencerControllerProvider.notifier).loadPattern(pattern);
                    ref.read(tempoProvider.notifier).setBpm(pattern.tempoBpm);
                    Navigator.of(context).pop();
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Rename',
                        onPressed: () => _showRenameDialog(context, ref, pattern.id, pattern.name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteDialog(context, ref, pattern.id, pattern.name),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
