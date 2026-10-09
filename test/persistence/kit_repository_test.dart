import 'dart:async';
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
  Future<ByteData> load(String key) async {
    throw Exception('Unable to load binary asset: $key');
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    if (key == 'AssetManifest.bin') {
      final manifestMap = <String, List<Object?>>{
        for (final k in assets.keys) k: <Object?>[],
      };
      final byteData = const StandardMessageCodec().encodeMessage(manifestMap);
      return parser(byteData!);
    }
    throw StateError('Unable to load binary asset: $key');
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async {
    final str = await loadString(key);
    return parser(str);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'AssetManifest.json') {
      final manifestMap = {
        for (final k in assets.keys) k: [k],
      };
      return jsonEncode(manifestMap);
    }
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
        'assets/kits/classic-synth.kit.json': fakeClassicJson,
        'assets/kits/retro-8bit.kit.json': fakeRetroJson,
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
        'assets/kits/corrupted.kit.json': 'not valid json {{{',
        'assets/kits/invalid_voices.kit.json': jsonEncode({
          'id': 'invalid',
          'name': 'Invalid',
          'voices': [], // Not 8 voices
        }),
      });

      final repo = AssetKitRepository(bundle: bundle);

      final kits = await repo.loadKits();
      // Only default kit should be available
      expect(kits.length, equals(1));
      expect(kits.first.id, equals('classic-synth'));
      expect(repo.getKit('invalid').id, equals('classic-synth'));
    });

    test('AssetKitRepository discovers all kit files ending with .kit.json dynamically', () async {
      final fakeClassicJson = jsonEncode(Kit.classicSynth.toJson());
      final fakeRetroJson = jsonEncode({
        'schemaVersion': 1,
        'id': 'retro-8bit',
        'name': 'Retro 8-bit',
        'builtIn': true,
        'voices': Kit.classicSynth.voices.map((v) => v.toJson()).toList(),
      });
      final fakeDrumsJson = jsonEncode({
        'schemaVersion': 1,
        'id': 'analog-drums',
        'name': 'Analog drums',
        'builtIn': true,
        'voices': Kit.classicSynth.voices.map((v) => v.toJson()).toList(),
      });

      final bundle = FakeAssetBundle({
        'assets/kits/classic-synth.kit.json': fakeClassicJson,
        'assets/kits/retro-8bit.kit.json': fakeRetroJson,
        'assets/kits/analog-drums.kit.json': fakeDrumsJson,
        'assets/other/ignore-me.json': '{}',
      });

      final repo = AssetKitRepository(bundle: bundle);
      final kits = await repo.loadKits();

      expect(kits.length, equals(3));
      expect(
        kits.map((k) => k.id),
        containsAll(['classic-synth', 'retro-8bit', 'analog-drums']),
      );
      expect(repo.getKit('analog-drums').name, equals('Analog drums'));
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
