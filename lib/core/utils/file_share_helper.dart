import 'package:flutter/services.dart';

class FileShareHelper {
  FileShareHelper._();

  static const _channel = MethodChannel('ataa/share');

  static Future<void> shareFile({
    required String path,
    String? filename,
    String mimeType = 'application/pdf',
  }) {
    return _channel.invokeMethod<void>('shareFile', {
      'path': path,
      'filename': filename,
      'mimeType': mimeType,
    });
  }
}
