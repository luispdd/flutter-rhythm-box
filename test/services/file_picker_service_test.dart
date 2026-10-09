import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/services/file_picker_service.dart';

/// Test double implementing [FilePickerService].
class FakeFilePickerService implements FilePickerService {
  String? saveResult;
  PickedFileData? pickResult;

  String? lastSavedFileName;
  Uint8List? lastSavedBytes;
  int saveFileCalls = 0;
  int pickJsonFileCalls = 0;

  @override
  Future<String?> saveFile({
    required String suggestedFileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) async {
    saveFileCalls++;
    lastSavedFileName = suggestedFileName;
    lastSavedBytes = bytes;
    return saveResult;
  }

  @override
  Future<PickedFileData?> pickJsonFile({String? dialogTitle}) async {
    pickJsonFileCalls++;
    return pickResult;
  }
}

void main() {
  group('FilePickerService', () {
    test('FakeFilePickerService records saveFile calls and arguments', () async {
      final fake = FakeFilePickerService()..saveResult = '/path/to/exported.json';
      final bytes = Uint8List.fromList([1, 2, 3]);

      final result = await fake.saveFile(
        suggestedFileName: 'library.json',
        bytes: bytes,
      );

      expect(result, equals('/path/to/exported.json'));
      expect(fake.saveFileCalls, equals(1));
      expect(fake.lastSavedFileName, equals('library.json'));
      expect(fake.lastSavedBytes, equals(bytes));
    });

    test('FakeFilePickerService records pickJsonFile calls and returns data', () async {
      final bytes = Uint8List.fromList([123, 125]);
      final fake = FakeFilePickerService()
        ..pickResult = PickedFileData(name: 'test.json', bytes: bytes);

      final result = await fake.pickJsonFile();

      expect(result, isNotNull);
      expect(result!.name, equals('test.json'));
      expect(result.bytes, equals(bytes));
      expect(fake.pickJsonFileCalls, equals(1));
    });

    test('filePickerServiceProvider can be overridden in Riverpod container', () {
      final fake = FakeFilePickerService();
      final container = ProviderContainer(
        overrides: [
          filePickerServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final resolved = container.read(filePickerServiceProvider);
      expect(resolved, same(fake));
    });
  });
}
