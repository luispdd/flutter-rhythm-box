import 'dart:typed_data';

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
