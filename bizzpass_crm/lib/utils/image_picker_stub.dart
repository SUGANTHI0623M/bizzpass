import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Picks an image file on mobile/desktop using file_picker.
Future<Uint8List?> pickImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final bytes = result.files.single.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  return bytes;
}
