import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/spike_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const ProviderScope(child: RhythmBoxApp()));
}

class RhythmBoxApp extends StatelessWidget {
  const RhythmBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhythm Box',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: const SpikeScreen(),
    );
  }
}

