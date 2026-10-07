// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rhythm_box/audio/soloud_audio_engine.dart';
import 'package:rhythm_box/synth/click_synthesizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Running Swap Benchmark...',
            style: TextStyle(color: Colors.amber, fontSize: 24),
          ),
        ),
      ),
    ),
  );

  final engine = SoLoudAudioEngine();
  final synth = const ClickSynthesizer(sampleRate: 44100);

  final buffer1 = synth.renderPatternBuffer(
    bpm: 120,
    stepCount: 4,
    activeSteps: [true, true, true, true],
  );

  final buffer2 = synth.renderPatternBuffer(
    bpm: 120,
    stepCount: 4,
    activeSteps: [true, true, true, true],
  );

  // Give the UI a moment to stabilize
  await Future.delayed(const Duration(seconds: 1));

  print('BENCHMARK:START');
  await engine.startLoop(buffer1);

  // Play buffer 1 for 15 seconds
  await Future.delayed(const Duration(seconds: 15));

  print('BENCHMARK:SWAP');
  await engine.swapLoopAtBoundary(buffer2);

  // Play buffer 2 for 15 seconds
  await Future.delayed(const Duration(seconds: 15));

  print('BENCHMARK:STOP');
  await engine.stop();
  await engine.dispose();

  print('BENCHMARK:DONE');
  exit(0);
}
