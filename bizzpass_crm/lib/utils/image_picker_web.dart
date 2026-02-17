// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Picks an image file on web using the browser's file input (avoids file_picker _instance error).
Future<Uint8List?> pickImageBytes() async {
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.click();

  final completer = Completer<Uint8List?>();
  void onChange(html.Event e) {
    input.removeEventListener('change', onChange);
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsArrayBuffer(file);
  }

  input.addEventListener('change', onChange);
  return completer.future;
}
