// Web implementation: turns bytes into a Blob and clicks a temporary
// <a download> link so the browser saves the file. No token in any URL.
import 'dart:html' as html;

void downloadBytes(String filename, List<int> bytes, String mime) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
