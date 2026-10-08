import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/ui/sequencer_controller.dart';

import '../audio/fake_audio_engine.dart';
import '../audio/fake_background_audio_service.dart';
import '../persistence/fake_settings_store.dart';

void main() {
  group('SequencerController', () {
    late ProviderContainer container;
    late FakeSettingsStore store;
    late FakeAudioEngine engine;
    late FakeBackgroundAudioService backgroundService;

    setUp(() async {
      store = FakeSettingsStore();
      engine = FakeAudioEngine();
      backgroundService = FakeBackgroundAudioService();

      container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          audioEngineProvider.overrideWithValue(engine),
          backgroundAudioServiceProvider
              .overrideWithValue(backgroundService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with default empty pattern and not playing', () async {
      final state = container.read(sequencerControllerProvider);

      expect(state.isPlaying, isFalse);
      expect(state.pattern, equals(Pattern.empty()));
    });

    test('initializes with loaded pattern from store', () async {
      var savedPattern = Pattern.empty();
      savedPattern = savedPattern.toggle(2, 4); // Random edit to ensure it's not default
      savedPattern = savedPattern.setStepCount(8);
      await store.saveWorkingPattern(savedPattern);

      final newContainer = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(newContainer.dispose);

      final controller = newContainer.read(sequencerControllerProvider.notifier);
      // Wait for async load from store to complete
      await controller.loadFromStore();
      
      final state = newContainer.read(sequencerControllerProvider);

      expect(state.isPlaying, isFalse);
      expect(state.pattern, equals(savedPattern));
      expect(state.pattern.stepCount, equals(8));
      expect(state.pattern.isStepOn(2, 4), isTrue);
    });

    test('toggleStep updates state and persists', () async {
      final controller = container.read(sequencerControllerProvider.notifier);
      await controller.toggleStep(1, 1);

      final state = container.read(sequencerControllerProvider);
      expect(state.pattern.isStepOn(1, 1), isTrue);

      final saved = await store.loadWorkingPattern();
      expect(saved!.isStepOn(1, 1), isTrue);
    });

    test('setStepCount updates state and persists', () async {
      final controller = container.read(sequencerControllerProvider.notifier);
      await controller.setStepCount(12);

      final state = container.read(sequencerControllerProvider);
      expect(state.pattern.stepCount, equals(12));

      final saved = await store.loadWorkingPattern();
      expect(saved!.stepCount, equals(12));
    });

    test('clearPattern updates state and persists', () async {
      final controller = container.read(sequencerControllerProvider.notifier);
      await controller.toggleStep(0, 0);
      expect(container.read(sequencerControllerProvider).pattern.isStepOn(0, 0), isTrue);

      await controller.clearPattern();

      final state = container.read(sequencerControllerProvider);
      expect(state.pattern.isStepOn(0, 0), isFalse);

      final saved = await store.loadWorkingPattern();
      expect(saved!.isStepOn(0, 0), isFalse);
    });

    test('togglePlay starts and stops AudioEngine and BackgroundAudioService', () async {
      final controller = container.read(sequencerControllerProvider.notifier);
      
      await controller.togglePlay();
      expect(container.read(sequencerControllerProvider).isPlaying, isTrue);
      expect(engine.startLoopCalls, equals(1));
      expect(backgroundService.startCalls, equals(1));

      await controller.togglePlay();
      expect(container.read(sequencerControllerProvider).isPlaying, isFalse);
      expect(engine.stopCalls, equals(1));
      expect(backgroundService.stopCalls, equals(1));
    });

    test('pattern updates swap buffer if playing', () async {
      final controller = container.read(sequencerControllerProvider.notifier);
      
      await controller.togglePlay();
      expect(engine.startLoopCalls, equals(1));
      expect(engine.swapLoopCalls, equals(0));

      await controller.toggleStep(0, 0);
      expect(engine.swapLoopCalls, equals(1));

      await controller.setStepCount(12);
      expect(engine.swapLoopCalls, equals(2));

      await controller.clearPattern();
      expect(engine.swapLoopCalls, equals(3));
    });

    test('pattern updates do not swap buffer if stopped', () async {
      final controller = container.read(sequencerControllerProvider.notifier);
      
      await controller.toggleStep(0, 0);
      expect(engine.startLoopCalls, equals(0));
      expect(engine.swapLoopCalls, equals(0));
    });

    test('setKit updates kitId, persists to store, and swaps loop if playing', () async {
      final controller = container.read(sequencerControllerProvider.notifier);

      // Stopped: updates state and store, no swap
      await controller.setKit('retro-8bit');
      expect(container.read(sequencerControllerProvider).pattern.kitId, equals('retro-8bit'));
      final saved = await store.loadWorkingPattern();
      expect(saved!.kitId, equals('retro-8bit'));
      expect(engine.swapLoopCalls, equals(0));

      // Start playing
      await controller.togglePlay();
      expect(engine.startLoopCalls, equals(1));

      // While playing: setKit triggers boundary swap
      await controller.setKit('classic-synth');
      expect(container.read(sequencerControllerProvider).pattern.kitId, equals('classic-synth'));
      expect(engine.swapLoopCalls, equals(1));
    });
  });
}

