import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/kit.dart';
import 'package:rhythm_box/persistence/kit_repository.dart';

class FakeAssetBundle extends Fake implements AssetBundle {
  final Map<String, String> assets;

  FakeAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = assets[key];
    if (content == null) {
      throw StateError('Unable to load asset: $key');
    }
    return content;
  }
}

void main() {
  group('KitRepository', () {
    test('InMemoryKitRepository provides defaultKit and fallback', () {
      final repo = InMemoryKitRepository();
      expect(repo.defaultKit.id, equals('classic-synth'));
      expect(repo.availableKits.length, equals(1));
      expect(repo.getKit('unknown-id').id, equals('classic-synth'));
      expect(repo.getKit('classic-synth').id, equals('classic-synth'));
    });

    test('AssetKitRepository loads valid kit JSON from AssetBundle', () async {
      final fakeClassicJson = jsonEncode(Kit.classicSynth.toJson());
      final fakeRetroJson = jsonEncode({
        'schemaVersion': 1,
        'id': 'retro-8bit',
        'name': 'Retro 8-bit',
        'builtIn': true,
        'voices': Kit.classicSynth.voices.map((v) => v.toJson()).toList(),
      });
      final bundle = FakeAssetBundle({
        AssetKitRepository.classicSynthPath: fakeClassicJson,
        AssetKitRepository.retro8BitPath: fakeRetroJson,
      });

      final repo = AssetKitRepository(bundle: bundle);
      final kits = await repo.loadKits();

      expect(kits.length, equals(2));
      expect(kits.map((k) => k.id), containsAll(['classic-synth', 'retro-8bit']));
      expect(repo.getKit('classic-synth').name, equals('Classic synth'));
      expect(repo.getKit('retro-8bit').name, equals('Retro 8-bit'));
      expect(repo.getKit('unknown-id').id, equals('classic-synth'));
    });


    test('AssetKitRepository safely ignores invalid or corrupted kit assets', () async {
      final bundle = FakeAssetBundle({
        'assets/kits/corrupted.json': 'not valid json {{{',
        'assets/kits/invalid_voices.json': jsonEncode({
          'id': 'invalid',
          'name': 'Invalid',
          'voices': [], // Not 8 voices
        }),
      });

      final repo = AssetKitRepository(
        bundle: bundle,
        assetPaths: [
          'assets/kits/corrupted.json',
          'assets/kits/invalid_voices.json',
        ],
      );

      final kits = await repo.loadKits();
      // Only default kit should be available
      expect(kits.length, equals(1));
      expect(kits.first.id, equals('classic-synth'));
      expect(repo.getKit('invalid').id, equals('classic-synth'));
    });

    test('Riverpod kitRepositoryProvider resolves', () {
      final container = ProviderContainer(
        overrides: [
          kitRepositoryProvider.overrideWithValue(InMemoryKitRepository()),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(kitRepositoryProvider);
      expect(repo.defaultKit.id, equals('classic-synth'));
    });
  });
}
