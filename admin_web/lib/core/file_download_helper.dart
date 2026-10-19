import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart' as impl;

class FileDownloadHelper {
  static void downloadBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) {
    impl.downloadBytes(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }

  static void downloadString({
    required String content,
    required String fileName,
    required String mimeType,
  }) {
    impl.downloadString(content: content, fileName: fileName, mimeType: mimeType);
  }
}
