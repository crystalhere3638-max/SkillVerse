import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';

/// Streams the signed-in user's Firestore profile so Home/Profile can
/// show live xp/coins/level/streak. Read-only for now — future
/// features (missions, posts, competitions) will write through
/// [UserRepository], not through this provider directly.
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  StreamSubscription<AppUser?>? _sub;
  String? _uid;

  UserProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  AppUser? _profile;
  AppUser? get profile => _profile;

  bool _isUploadingPhoto = false;
  double _photoUploadProgress = 0;
  String? _photoUploadError;

  bool get isUploadingPhoto => _isUploadingPhoto;
  double get photoUploadProgress => _photoUploadProgress;
  String? get photoUploadError => _photoUploadError;

  // --- Skill Journey: level-up detection --------------------------------
  // Tracks the last level we've already celebrated so a level-up popup
  // fires exactly once per level gained, even across profile stream
  // updates that don't change the level.
  int? _lastSeenLevel;
  int? _pendingLevelUp;

  /// Non-null the moment a level increase is detected; the UI (HomeShell)
  /// should show the celebration then call [consumeLevelUp].
  int? get pendingLevelUp => _pendingLevelUp;

  void consumeLevelUp() {
    _pendingLevelUp = null;
  }

  void listenTo(String uid) {
    _uid = uid;
    _sub?.cancel();
    _sub = _userRepository.watchUser(uid).listen((profile) {
      final previousLevel = _lastSeenLevel;
      _profile = profile;
      if (profile != null) {
        if (previousLevel != null && profile.level > previousLevel) {
          _pendingLevelUp = profile.level;
        }
        _lastSeenLevel = profile.level;
      }
      notifyListeners();
    });
  }

  Future<void> completeOnboarding({
    required String uid,
    required String mainCategory,
    required String goal,
  }) {
    return _userRepository.completeOnboarding(uid: uid, mainCategory: mainCategory, goal: goal);
  }

  /// Uploads and links a new profile photo. Safe to call again after
  /// a failure — that's the retry path, no separate method needed.
  Future<void> updateProfilePhoto(File localImage) async {
    final uid = _uid;
    if (uid == null) return;

    _isUploadingPhoto = true;
    _photoUploadProgress = 0;
    _photoUploadError = null;
    notifyListeners();

    try {
      await _userRepository.updateProfilePhoto(
        uid,
        localImage,
        onProgress: (p) {
          _photoUploadProgress = p;
          notifyListeners();
        },
      );
      // _profile updates on its own via the live watchUser stream
      // once Firestore's photoUrl write lands.
    } catch (_) {
      _photoUploadError = "Couldn't upload your photo. Check your connection and try again.";
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  void dismissPhotoUploadError() {
    _photoUploadError = null;
    notifyListeners();
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _profile = null;
    _uid = null;
    _isUploadingPhoto = false;
    _photoUploadProgress = 0;
    _photoUploadError = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
