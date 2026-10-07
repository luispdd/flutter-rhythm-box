import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/tempo.dart';
import 'package:rhythm_box/ui/tempo_controller.dart';

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
  });
}
