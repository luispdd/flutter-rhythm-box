import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';
import 'package:rhythm_box/domain/kit.dart';
import 'package:rhythm_box/persistence/kit_repository.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';
import 'package:rhythm_box/ui/step_playhead.dart';

import '../audio/fake_audio_engine.dart';
import '../audio/fake_background_audio_service.dart';
import '../persistence/fake_settings_store.dart';

void main() {
  group('StepPlayhead', () {
    late FakeAudioEngine fakeEngine;
    late FakeBackgroundAudioService fakeBackgroundService;
    late FakeSettingsStore fakeStore;
    late InMemoryKitRepository kitRepo;
    late ProviderContainer container;

    setUp(() {
      fakeEngine = FakeAudioEngine();
      fakeBackgroundService = FakeBackgroundAudioService();
      fakeStore = FakeSettingsStore();
      kitRepo = InMemoryKitRepository(kits: [Kit.classicSynth]);
      container = ProviderContainer(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
          backgroundAudioServiceProvider.overrideWithValue(fakeBackgroundService),
          settingsStoreProvider.overrideWithValue(fakeStore),
          kitRepositoryProvider.overrideWithValue(kitRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('advances playhead across steps and maintains continuity across loop boundary swaps',
        (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: StepPlayhead(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially stopped: no active step highlighted (all playhead bars transparent)
      Finder amberPlayheadFinder() => find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.amber,
          );

      expect(amberPlayheadFinder(), findsNothing);

      // Start playback at 120 BPM (16 steps). Step duration is 15,000,000 / 120 = 125,000 us (125 ms).
      container.read(tempoProvider.notifier).setBpm(120);
      await container.read(sequencerControllerProvider.notifier).start();
      await tester.pump();

      // Emit position at step 0 (50 ms)
      fakeEngine.emitPosition(const Duration(milliseconds: 50));
      await tester.pump(Duration.zero);
      expect(amberPlayheadFinder(), findsOneWidget);

      // Advance position to step 1 (150 ms)
      fakeEngine.emitPosition(const Duration(milliseconds: 150));
      await tester.pump(Duration.zero);
      expect(amberPlayheadFinder(), findsOneWidget);

      // Advance position near loop boundary (step 15 = 1900 ms)
      fakeEngine.emitPosition(const Duration(milliseconds: 1900));
      await tester.pump(Duration.zero);
      expect(amberPlayheadFinder(), findsOneWidget);

      // Simulate loop swap and boundary: new cycle starts at step 0 (20 ms into new loop)
      // Playhead should continuously highlight step 0 without error or dropping
      fakeEngine.emitPosition(const Duration(milliseconds: 20));
      await tester.pump(Duration.zero);
      expect(amberPlayheadFinder(), findsOneWidget);
      await tester.pump();
      expect(amberPlayheadFinder(), findsOneWidget);
    });
  });
}
