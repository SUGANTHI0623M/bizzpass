import 'dart:html' as html;

/// Triggers browser download of [bytes] as [filename]. Web only.
bool saveBytesAsFile(List<int> bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename;
  anchor.click();
  html.Url.revokeObjectUrl(url);
  return true;
}
