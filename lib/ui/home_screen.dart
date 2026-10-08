import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_box/ui/app_error.dart';
import 'package:rhythm_box/ui/home_tab_controller.dart';
import 'package:rhythm_box/ui/metronome_screen.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_screen.dart';
import 'package:rhythm_box/ui/sequences_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<Widget> _screens = [
    MetronomeScreen(),
    SequencerScreen(),
    SequencesScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabControllerProvider);
    final audioError = ref.watch(audioErrorProvider);

    return Scaffold(
      body: Column(
        children: [
          if (audioError != null)
            SafeArea(
              bottom: false,
              child: MaterialBanner(
                key: const Key('audio_error_banner'),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                leading: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                content: Text(
                  audioError,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                actions: [
                  TextButton(
                    key: const Key('retry_audio_init_button'),
                    onPressed: () async {
                      try {
                        await ref.read(audioEngineProvider).init();
                        ref.read(audioErrorProvider.notifier).clear();
                      } catch (e) {
                        ref.read(audioErrorProvider.notifier).setError(
                          'Audio engine retry failed: $e',
                        );
                      }
                    },
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeTabControllerProvider.notifier).setIndex(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Metronome',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on),
            label: 'Sequencer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Sequences',
          ),
        ],
      ),
    );
  }
}
