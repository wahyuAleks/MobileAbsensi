// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

void downloadBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadString({
  required String content,
  required String fileName,
  required String mimeType,
}) {
  final bytes = utf8.encode(content);
  downloadBytes(bytes: bytes, fileName: fileName, mimeType: mimeType);
}
