import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/tempo_controller.dart';

import '../persistence/fake_settings_store.dart';

void main() {
  group('TempoNotifier & tempoProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial tempo is 120 BPM', () {
      final tempo = container.read(tempoProvider);
      expect(tempo, equals(Tempo.defaultBpm));
      expect(tempo, equals(120));
    });

    test('setBpm updates state and notifies listeners', () {
      final listenerCalls = <int>[];
      container.listen<int>(
        tempoProvider,
        (previous, next) => listenerCalls.add(next),
        fireImmediately: false,
      );

      container.read(tempoProvider.notifier).setBpm(90);

      expect(container.read(tempoProvider), equals(90));
      expect(listenerCalls, equals([90]));

      container.read(tempoProvider.notifier).setBpm(140);
      expect(container.read(tempoProvider), equals(140));
      expect(listenerCalls, equals([90, 140]));
    });

    test('setBpm clamps values below 30 to minBpm (30)', () {
      container.read(tempoProvider.notifier).setBpm(10);
      expect(container.read(tempoProvider), equals(Tempo.minBpm));
      expect(container.read(tempoProvider), equals(30));
    });

    test('setBpm clamps values above 300 to maxBpm (300)', () {
      container.read(tempoProvider.notifier).setBpm(400);
      expect(container.read(tempoProvider), equals(Tempo.maxBpm));
      expect(container.read(tempoProvider), equals(300));
    });

    test('increment increases tempo by specified amount, clamping at bounds', () {
      container.read(tempoProvider.notifier).setBpm(298);

      container.read(tempoProvider.notifier).increment();
      expect(container.read(tempoProvider), equals(299));

      container.read(tempoProvider.notifier).increment(5);
      expect(container.read(tempoProvider), equals(Tempo.maxBpm));
      expect(container.read(tempoProvider), equals(300));

      // Incrementing at max bound stays at max bound
      container.read(tempoProvider.notifier).increment(1);
      expect(container.read(tempoProvider), equals(300));
    });

    test('decrement decreases tempo by specified amount, clamping at bounds', () {
      container.read(tempoProvider.notifier).setBpm(32);

      container.read(tempoProvider.notifier).decrement();
      expect(container.read(tempoProvider), equals(31));

      container.read(tempoProvider.notifier).decrement(5);
      expect(container.read(tempoProvider), equals(Tempo.minBpm));
      expect(container.read(tempoProvider), equals(30));

      // Decrementing at min bound stays at min bound
      container.read(tempoProvider.notifier).decrement(1);
      expect(container.read(tempoProvider), equals(30));
    });

    group('SettingsStore persistence', () {
      late FakeSettingsStore fakeStore;
      late ProviderContainer storeContainer;

      setUp(() {
        fakeStore = FakeSettingsStore();
        storeContainer = ProviderContainer(
          overrides: [
            settingsStoreProvider.overrideWithValue(fakeStore),
          ],
        );
      });

      tearDown(() {
        storeContainer.dispose();
      });

      test('initializes with saved tempo from store', () async {
        fakeStore.savedTempo = const Tempo(144);
        final notifier = storeContainer.read(tempoProvider.notifier);
        await notifier.loadFromStore();

        expect(storeContainer.read(tempoProvider), equals(144));
        expect(fakeStore.loadTempoCalls, greaterThanOrEqualTo(1));
      });

      test('setBpm persists updated tempo to SettingsStore', () async {
        final notifier = storeContainer.read(tempoProvider.notifier);
        await notifier.setBpm(160);

        expect(storeContainer.read(tempoProvider), equals(160));
        expect(fakeStore.saveTempoCalls, equals(1));
        expect(fakeStore.savedTempo, equals(const Tempo(160)));
      });

      test('increment persists updated tempo to SettingsStore', () async {
        final notifier = storeContainer.read(tempoProvider.notifier);
        await notifier.increment(5);

        expect(storeContainer.read(tempoProvider), equals(125));
        expect(fakeStore.saveTempoCalls, equals(1));
        expect(fakeStore.savedTempo, equals(const Tempo(125)));
      });

      test('decrement persists updated tempo to SettingsStore', () async {
        final notifier = storeContainer.read(tempoProvider.notifier);
        await notifier.decrement(10);

        expect(storeContainer.read(tempoProvider), equals(110));
        expect(fakeStore.saveTempoCalls, equals(1));
        expect(fakeStore.savedTempo, equals(const Tempo(110)));
      });
    });
  });
}

