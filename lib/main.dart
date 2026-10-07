import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio/soloud_audio_engine.dart';
import 'synth/click_synthesizer.dart';
import 'ui/spike_screen.dart';
import 'ui/theme.dart';

void main(List<String> args) async {
  if (args.isNotEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    final mode = args[0];
    final engine = SoLoudAudioEngine();

    final synth = const ClickSynthesizer(sampleRate: 44100);

    if (mode == 'sequencer') {
      final seconds = int.tryParse(args.length > 1 ? args[1] : '305') ?? 305;
      final buffer = synth.renderPatternBuffer(
        bpm: 120,
        stepCount: 4,
        activeSteps: [true, true, true, true],
      );
      await engine.startLoop(buffer);
      await Future.delayed(Duration(seconds: seconds));
      await engine.stop();
      await engine.dispose();
      exit(0);
    } else if (mode == 'metronome') {
      final seconds = int.tryParse(args.length > 1 ? args[1] : '305') ?? 305;
      final buffer = synth.renderMetronomeBuffer(
        bpm: 120,
        beatsPerBar: 4,
      );
      await engine.startLoop(buffer);
      await Future.delayed(Duration(seconds: seconds));
      await engine.stop();
      await engine.dispose();
      exit(0);
    } else if (mode == 'swap') {
      final swapSec = int.tryParse(args.length > 1 ? args[1] : '15') ?? 15;
      final totalSec = int.tryParse(args.length > 2 ? args[2] : '30') ?? 30;
      final buf1 = synth.renderPatternBuffer(
        bpm: 120,
        stepCount: 4,
        activeSteps: [true, true, true, true],
      );
      final buf2 = synth.renderPatternBuffer(
        bpm: 120,
        stepCount: 4,
        activeSteps: [true, true, true, true],
      );

      await engine.startLoop(buf1);
      await Future.delayed(Duration(seconds: swapSec));
      await engine.swapLoopAtBoundary(buf2);
      await Future.delayed(Duration(seconds: totalSec - swapSec));
      await engine.stop();
      await engine.dispose();
      exit(0);
    }
  }

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

