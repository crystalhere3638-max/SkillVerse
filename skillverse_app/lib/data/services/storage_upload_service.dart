import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

/// Thrown after every retry attempt has been exhausted, so callers can
/// show a real error instead of hanging on a stuck progress bar.
class UploadFailedException implements Exception {
  final String message;
  UploadFailedException(this.message);
  @override
  String toString() => message;
}

class StorageUploadService {
  final FirebaseStorage _storage;
  StorageUploadService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  /// Compresses an image before upload — cuts typical phone-camera
  /// photos (3-8MB) down to a web-friendly size without a visible
  /// quality hit. Falls back to the original file untouched if
  /// compression fails for any reason (corrupt file, unsupported
  /// format) rather than blocking the whole upload on it.
  Future<File> compressImage(File source, {int quality = 78, int minWidth = 1280}) async {
    try {
      final targetDir = await getTemporaryDirectory();
      final targetPath = p.join(
        targetDir.path,
        '${DateTime.now().microsecondsSinceEpoch}_${p.basenameWithoutExtension(source.path)}.jpg',
      );
      final result = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        keepExif: false,
      );
      if (result == null) return source;
      return File(result.path);
    } catch (_) {
      return source;
    }
  }

  /// Uploads [file] to [storagePath], retrying transient failures
  /// (network blips, storage/retry-limit-exceeded) with a short
  /// backoff. [onProgress] receives a 0.0–1.0 fraction; call sites
  /// (e.g. [PostProvider.publish]) feed that straight into their
  /// existing upload-progress bar.
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    required void Function(double progress) onProgress,
    int maxAttempts = 3,
  }) async {
    final dio = Dio();
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final formData = FormData.fromMap({
          'upload_preset': 'skillverse_unsigned',
          'file': await MultipartFile.fromFile(file.path),
        });
        final response = await dio.post(
          'https://api.cloudinary.com/v1_1/vbff2dy9/auto/upload',
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0) onProgress(sent / total);
          },
        );
        if (response.statusCode != 200) {
          throw Exception('Cloudinary ${response.statusCode}: ${response.data}');
        }
        return response.data['secure_url'] as String;
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    throw UploadFailedException('Upload failed after $maxAttempts attempts: $lastError');
  }

  Future<void> deleteFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {
      // Best-effort cleanup (e.g. publish failed after upload) — a
      // missed delete just leaves an orphaned file, never a crash.
    }
  }
}
