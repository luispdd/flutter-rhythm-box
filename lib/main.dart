import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'audio/soloud_audio_engine.dart';
import 'domain/metronome_settings.dart';
import 'domain/sequence.dart';
import 'persistence/kit_repository.dart';
import 'persistence/settings_store.dart';
import 'persistence/shared_preferences_settings_store.dart';
import 'synth/metronome_renderer.dart';
import 'synth/pattern_renderer.dart';
import 'ui/app_error.dart';
import 'ui/lifecycle_manager.dart';
import 'ui/playback_controller.dart';
import 'ui/theme.dart';
import 'ui/home_screen.dart';

void main(List<String> args) async {
  if (args.isNotEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    final mode = args[0];
    final engine = SoLoudAudioEngine();

    const patternRenderer = PatternRenderer(sampleRate: 44100);
    const metronomeRenderer = MetronomeRenderer(sampleRate: 44100);

    if (mode == 'sequencer') {
      final seconds = int.tryParse(args.length > 1 ? args[1] : '305') ?? 305;
      final buffer = patternRenderer.renderBuffer(
        spikePatternPresets.first,
        bpm: 120,
      );
      await engine.startLoop(buffer);
      await Future.delayed(Duration(seconds: seconds));
      await engine.stop();
      await engine.dispose();
      exit(0);
    } else if (mode == 'metronome') {
      final seconds = int.tryParse(args.length > 1 ? args[1] : '305') ?? 305;
      final buffer = metronomeRenderer.renderBuffer(
        settings: MetronomeSettings(beatsPerBar: 4),
        bpm: 120,
      );
      await engine.startLoop(buffer);
      await Future.delayed(Duration(seconds: seconds));
      await engine.stop();
      await engine.dispose();
      exit(0);
    } else if (mode == 'swap') {
      final swapSec = int.tryParse(args.length > 1 ? args[1] : '15') ?? 15;
      final totalSec = int.tryParse(args.length > 2 ? args[2] : '30') ?? 30;
      final buf1 = patternRenderer.renderBuffer(
        spikePatternPresets.first,
        bpm: 120,
      );
      final buf2 = patternRenderer.renderBuffer(
        spikePatternPresets.first,
        bpm: 120,
      );

      await engine.startLoop(buf1);
      await Future.delayed(Duration(seconds: swapSec));
      await engine.swapLoopAtBoundary(buf2);
      await Future.delayed(Duration(seconds: totalSec - swapSec));
      await engine.stop();
      await engine.dispose();
      exit(0);
    } else if (mode == 'sequence') {
      final seconds = int.tryParse(args.length > 1 ? args[1] : '305') ?? 305;
      final patternA = spikePatternPresets.first.copyWith(
        id: 'patA',
        name: 'Pattern A 120',
        tempoBpm: 120,
      );
      final patternB = spikePatternPresets.first.copyWith(
        id: 'patB',
        name: 'Pattern B 140',
        tempoBpm: 140,
      );
      final sequence = Sequence(
        id: 'test_seq',
        name: 'Test Sequence',
        loop: true,
        entries: [
          SequenceEntry(patternId: 'patA', repeats: 1),
          SequenceEntry(patternId: 'patB', repeats: 1),
        ],
      );
      final buffer = patternRenderer.renderSequenceBuffer(
        sequence,
        {'patA': patternA, 'patB': patternB},
      );
      await engine.startLoop(buffer, looping: true);
      await Future.delayed(Duration(seconds: seconds));
      await engine.stop();
      await engine.dispose();
      exit(0);
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settingsStore = SharedPreferencesSettingsStore(prefs);
  final kitRepository = AssetKitRepository();
  await kitRepository.loadKits();

  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(settingsStore),
        kitRepositoryProvider.overrideWithValue(kitRepository),
      ],
      child: const RhythmBoxApp(),
    ),
  );
}

class RhythmBoxApp extends StatelessWidget {
  const RhythmBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Rhythm amigo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: const AppLifecycleManager(
        child: HomeScreen(),
      ),
    );
  }
}
