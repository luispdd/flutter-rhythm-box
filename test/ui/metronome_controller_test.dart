import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/app_error.dart';
import 'package:rhythm_box/ui/metronome_controller.dart';
import 'package:rhythm_box/ui/playback_controller.dart';

import '../audio/fake_audio_engine.dart';
import '../audio/fake_background_audio_service.dart';
import '../persistence/fake_settings_store.dart';

void main() {
  group('MetronomeController', () {
    late FakeSettingsStore fakeStore;
    late FakeAudioEngine fakeEngine;
    late FakeBackgroundAudioService fakeBackgroundService;
    late ProviderContainer container;

    setUp(() {
      fakeStore = FakeSettingsStore();
      fakeEngine = FakeAudioEngine();
      fakeBackgroundService = FakeBackgroundAudioService();
      container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(fakeStore),
          audioEngineProvider.overrideWithValue(fakeEngine),
          backgroundAudioServiceProvider
              .overrideWithValue(fakeBackgroundService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State & Store Loading', () {
      test('has default settings and idle playback initially', () {
        final state = container.read(metronomeControllerProvider);
        expect(state.isPlaying, isFalse);
        expect(state.settings.beatsPerBar, equals(4));
        expect(state.settings.accent, isTrue);
        expect(state.settings.waveform, equals(Waveform.sine));
      });

      test('loads initial settings from SettingsStore', () async {
        final saved = MetronomeSettings(
          beatsPerBar: 3,
          accent: false,
          waveform: Waveform.triangle,
          pitchHz: 1200.0,
          decayMs: 60.0,
        );
        fakeStore.savedSettings = saved;

        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.loadFromStore();

        final state = container.read(metronomeControllerProvider);
        expect(state.settings.beatsPerBar, equals(3));
        expect(state.settings.accent, isFalse);
        expect(state.settings.waveform, equals(Waveform.triangle));
        expect(state.settings.pitchHz, equals(1200.0));
        expect(state.settings.decayMs, equals(60.0));
        expect(fakeStore.loadMetronomeSettingsCalls, greaterThanOrEqualTo(1));
      });
    });

    group('Settings Updates & Persistence', () {
      test('setBeatsPerBar updates state and saves to store', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.setBeatsPerBar(6);

        final state = container.read(metronomeControllerProvider);
        expect(state.settings.beatsPerBar, equals(6));
        expect(fakeStore.saveMetronomeSettingsCalls, equals(1));
        expect(fakeStore.savedSettings?.beatsPerBar, equals(6));
      });

      test('toggleAccent updates state and saves to store', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        expect(container.read(metronomeControllerProvider).settings.accent, isTrue);

        await notifier.toggleAccent();
        expect(container.read(metronomeControllerProvider).settings.accent, isFalse);
        expect(fakeStore.savedSettings?.accent, isFalse);

        await notifier.toggleAccent();
        expect(container.read(metronomeControllerProvider).settings.accent, isTrue);
        expect(fakeStore.savedSettings?.accent, isTrue);
      });

      test('setWaveform updates waveform and saves to store', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.setWaveform(Waveform.square);

        expect(
          container.read(metronomeControllerProvider).settings.waveform,
          equals(Waveform.square),
        );
        expect(fakeStore.savedSettings?.waveform, equals(Waveform.square));
      });

      test('setPitchHz updates pitch and saves to store', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.setPitchHz(880.0);

        expect(
          container.read(metronomeControllerProvider).settings.pitchHz,
          equals(880.0),
        );
        expect(fakeStore.savedSettings?.pitchHz, equals(880.0));
      });

      test('setDecayMs updates decay and saves to store', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.setDecayMs(100.0);

        expect(
          container.read(metronomeControllerProvider).settings.decayMs,
          equals(100.0),
        );
        expect(fakeStore.savedSettings?.decayMs, equals(100.0));
      });

      test('updateSettings updates all settings and saves to store', () async {
        final custom = MetronomeSettings(
          beatsPerBar: 5,
          accent: false,
          waveform: Waveform.square,
          pitchHz: 600.0,
          decayMs: 40.0,
        );
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.updateSettings(custom);

        expect(container.read(metronomeControllerProvider).settings, equals(custom));
        expect(fakeStore.savedSettings, equals(custom));
      });
    });

    group('Playback Control & AudioEngine Integration', () {
      test('start begins loop on AudioEngine and marks isPlaying true', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();

        final state = container.read(metronomeControllerProvider);
        expect(state.isPlaying, isTrue);
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeBackgroundService.startCalls, equals(1));
        expect(fakeEngine.lastStartedBuffer, isNotNull);
        expect(fakeEngine.lastStartedBuffer!.totalSamples, greaterThan(0));
      });

      test('stop ceases playback on AudioEngine and marks isPlaying false', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();
        expect(container.read(metronomeControllerProvider).isPlaying, isTrue);

        await notifier.stop();
        expect(container.read(metronomeControllerProvider).isPlaying, isFalse);
        expect(fakeEngine.stopCalls, equals(1));
        expect(fakeBackgroundService.stopCalls, equals(1));
      });

      test('togglePlayback starts when stopped and stops when playing', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);

        await notifier.togglePlayback();
        expect(container.read(metronomeControllerProvider).isPlaying, isTrue);
        expect(fakeEngine.startLoopCalls, equals(1));

        await notifier.togglePlayback();
        expect(container.read(metronomeControllerProvider).isPlaying, isFalse);
        expect(fakeEngine.stopCalls, equals(1));
      });

      test('calling start when already playing is a no-op', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();
        expect(fakeEngine.startLoopCalls, equals(1));

        await notifier.start();
        expect(fakeEngine.startLoopCalls, equals(1));
      });

      test('calling stop when already stopped is a no-op', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.stop();
        expect(fakeEngine.stopCalls, equals(0));
      });

      test('onExternalStop marks isPlaying false without calling engine.stop', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();
        expect(container.read(metronomeControllerProvider).isPlaying, isTrue);

        notifier.onExternalStop();
        expect(container.read(metronomeControllerProvider).isPlaying, isFalse);
        expect(fakeEngine.stopCalls, equals(0));
      });
    });

    group('Dynamic Boundary Swapping', () {
      test('modifying settings while playing triggers swapLoopAtBoundary', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(0));

        await notifier.setBeatsPerBar(3);
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(1));
        expect(fakeEngine.lastSwappedBuffer, isNotNull);

        await notifier.toggleAccent();
        expect(fakeEngine.swapLoopCalls, equals(2));

        await notifier.setWaveform(Waveform.triangle);
        expect(fakeEngine.swapLoopCalls, equals(3));
      });

      test('modifying settings while stopped does NOT trigger swapLoopAtBoundary', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.setBeatsPerBar(3);

        expect(fakeEngine.startLoopCalls, equals(0));
        expect(fakeEngine.swapLoopCalls, equals(0));
      });

      test('changing global tempo while playing triggers swapLoopAtBoundary', () async {
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(0));

        await container.read(tempoProvider.notifier).setBpm(150);

        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(1));
        expect(fakeEngine.lastSwappedBuffer, isNotNull);
      });

      test('changing global tempo while stopped does NOT trigger swapLoopAtBoundary', () async {
        await container.read(tempoProvider.notifier).setBpm(150);

        expect(fakeEngine.startLoopCalls, equals(0));
        expect(fakeEngine.swapLoopCalls, equals(0));
      });

      test('playback failure stops cleanly and sets audioErrorProvider', () async {
        fakeEngine.shouldFailStart = true;
        final notifier = container.read(metronomeControllerProvider.notifier);
        await notifier.start();

        final state = container.read(metronomeControllerProvider);
        expect(state.isPlaying, isFalse);
        expect(container.read(audioErrorProvider), contains('Engine failure'));
      });
    });
  });
}
