// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rhythm_box/audio/soloud_audio_engine.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/synth/pattern_renderer.dart';

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
  const renderer = PatternRenderer(sampleRate: 44100);

  final pattern = Pattern(
    stepCount: 4,
    tracks: [
      [true, true, true, true, ...List.filled(12, false)],
      ...List.generate(7, (_) => List.filled(16, false)),
    ],
  );

  final buffer1 = renderer.renderBuffer(pattern, bpm: 120);
  final buffer2 = renderer.renderBuffer(pattern, bpm: 120);

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
