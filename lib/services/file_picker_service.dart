import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data representing a file selected by the user.
@immutable
class PickedFileData {
  /// Name of the picked file.
  final String name;

  /// Binary contents of the file.
  final Uint8List bytes;

  /// Optional absolute path of the file (available on desktop platforms).
  final String? path;

  const PickedFileData({
    required this.name,
    required this.bytes,
    this.path,
  });
}

/// Abstract interface for file dialog operations.
///
/// Decouples native file dialogs from domain and UI logic to facilitate testing.
abstract interface class FilePickerService {
  /// Prompts the user with a save file dialog to write [bytes] to disk.
  ///
  /// Returns the chosen file path/identifier if saved, or `null` if cancelled.
  Future<String?> saveFile({
    required String suggestedFileName,
    required Uint8List bytes,
    String? dialogTitle,
  });

  /// Prompts the user to pick a JSON file from disk.
  ///
  /// Returns [PickedFileData] if a file was selected, or `null` if cancelled.
  Future<PickedFileData?> pickJsonFile({String? dialogTitle});
}

/// Default implementation of [FilePickerService] backed by `package:file_picker`.
class DefaultFilePickerService implements FilePickerService {
  const DefaultFilePickerService();

  @override
  Future<String?> saveFile({
    required String suggestedFileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle ?? 'Save Library',
      fileName: suggestedFileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (path == null) {
      return null;
    }

    // On desktop platforms (such as Linux), FilePicker returns the target path
    // but may not write the bytes automatically; ensure bytes are written.
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      final file = File(path);
      await file.writeAsBytes(bytes);
    }

    return path;
  }

  @override
  Future<PickedFileData?> pickJsonFile({String? dialogTitle}) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle ?? 'Select Library File',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final platformFile = result.files.first;
    Uint8List? bytes = platformFile.bytes;

    if (bytes == null && platformFile.path != null && !kIsWeb) {
      final file = File(platformFile.path!);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
      }
    }

    if (bytes == null) {
      return null;
    }

    return PickedFileData(
      name: platformFile.name,
      bytes: bytes,
      path: platformFile.path,
    );
  }
}

/// Global provider for the active [FilePickerService].
final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return const DefaultFilePickerService();
});
