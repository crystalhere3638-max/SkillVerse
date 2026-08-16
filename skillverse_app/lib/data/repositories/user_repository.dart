import 'dart:io';

import '../../core/exceptions/auth_exception_mapper.dart';
import '../models/app_user.dart';
import '../services/firestore_user_service.dart';
import '../services/storage_upload_service.dart';

/// Everything related to reading/updating the signed-in user's
/// Firestore profile. Gamification fields (xp, coins, level, etc.)
/// are exposed read-only here, ready for future features to write to.
class UserRepository {
  final FirestoreUserService _userService;
  final StorageUploadService _storage;

  UserRepository({FirestoreUserService? userService, StorageUploadService? storage})
      : _userService = userService ?? FirestoreUserService(),
        _storage = storage ?? StorageUploadService();

  Future<AppUser?> getUser(String uid) => _userService.getUser(uid);

  Stream<AppUser?> watchUser(String uid) => _userService.watchUser(uid);

  Future<void> completeOnboarding({
    required String uid,
    required String mainCategory,
    required String goal,
  }) async {
    try {
      await _userService.updateOnboarding(uid: uid, mainCategory: mainCategory, goal: goal);
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  /// Compresses, uploads, and links a new profile photo. Always
  /// uploads to the same fixed path (`profile_images/{uid}.jpg`) so a
  /// re-upload overwrites the old file instead of accumulating orphaned
  /// images in Storage every time someone changes their avatar.
  Future<String> updateProfilePhoto(String uid, File localImage, {required void Function(double) onProgress}) async {
    final compressed = await _storage.compressImage(localImage);
    final url = await _storage.uploadFile(
      file: compressed,
      storagePath: 'profile_images/$uid.jpg',
      onProgress: onProgress,
    );
    await _userService.updatePhotoUrl(uid, url);
    return url;
  }
}
