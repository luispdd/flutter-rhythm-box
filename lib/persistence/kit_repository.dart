import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/kit.dart';

/// Repository interface managing discovery, loading, and lookup of sound kits.
abstract class KitRepository {
  /// The default kit (`classic-synth`) returned when an unknown kit ID is requested.
  Kit get defaultKit;

  /// Currently cached or available kits.
  List<Kit> get availableKits;

  /// Loads and returns all available kits.
  Future<List<Kit>> loadKits();

  /// Retrieves a kit by [id], falling back to [defaultKit] if not found or invalid.
  Kit getKit(String id);

  /// Creates an in-memory repository suitable for testing or offline usage.
  factory KitRepository.inMemory({List<Kit>? kits, Kit? defaultKit}) =
      InMemoryKitRepository;
}

/// In-memory implementation of [KitRepository] useful for tests and headless execution.
class InMemoryKitRepository implements KitRepository {
  final List<Kit> _kits;
  @override
  final Kit defaultKit;

  InMemoryKitRepository({List<Kit>? kits, Kit? defaultKit})
      : defaultKit = defaultKit ?? Kit.classicSynth,
        _kits = kits != null
            ? List<Kit>.from(kits)
            : [defaultKit ?? Kit.classicSynth];

  @override
  List<Kit> get availableKits => List.unmodifiable(_kits);

  @override
  Future<List<Kit>> loadKits() async => availableKits;

  @override
  Kit getKit(String id) {
    final match = _kits.where((k) => k.id == id);
    if (match.isNotEmpty) return match.first;
    return defaultKit;
  }
}

/// Asset-backed [KitRepository] loading bundled kit JSON files from `assets/kits/`.
class AssetKitRepository implements KitRepository {
  static const String classicSynthPath = 'assets/kits/classic-synth.json';
  static const String retro8BitPath = 'assets/kits/retro-8bit.json';

  final AssetBundle _bundle;
  final List<String> _assetPaths;
  @override
  final Kit defaultKit;

  final Map<String, Kit> _loadedKits = {};

  AssetKitRepository({
    AssetBundle? bundle,
    List<String>? assetPaths,
    Kit? defaultKit,
  })  : _bundle = bundle ?? rootBundle,
        _assetPaths = assetPaths ?? [classicSynthPath, retro8BitPath],
        defaultKit = defaultKit ?? Kit.classicSynth {
    _loadedKits[this.defaultKit.id] = this.defaultKit;
  }


  @override
  List<Kit> get availableKits => List.unmodifiable(_loadedKits.values);

  @override
  Future<List<Kit>> loadKits() async {
    for (final path in _assetPaths) {
      try {
        final content = await _bundle.loadString(path);
        final dynamic decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          final kit = Kit.fromJson(decoded);
          _loadedKits[kit.id] = kit;
        }
      } catch (e) {
        // Corrupted or invalid kits are logged and ignored without crashing.
        // ignore: avoid_print
        print('Warning: Failed to load kit asset "$path": $e');
      }
    }
    return availableKits;
  }

  @override
  Kit getKit(String id) {
    return _loadedKits[id] ?? defaultKit;
  }
}

/// Global provider for [KitRepository].
final kitRepositoryProvider = Provider<KitRepository>((ref) {
  return AssetKitRepository();
});
