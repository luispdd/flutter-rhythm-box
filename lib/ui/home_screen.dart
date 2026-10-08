import 'package:flutter/material.dart';
import 'package:rhythm_box/ui/metronome_screen.dart';
import 'package:rhythm_box/ui/sequencer_screen.dart';
import 'package:rhythm_box/ui/sequences_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MetronomeScreen(),
    const SequencerScreen(),
    const SequencesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
