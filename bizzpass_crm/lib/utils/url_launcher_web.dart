import 'dart:html' as html;

/// Opens [url] in a new browser tab (web only).
void openUrl(String url) {
  html.window.open(url, '_blank');
}
