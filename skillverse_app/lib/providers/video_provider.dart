import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/comment_model.dart';
import '../data/models/video_post_model.dart';
import '../data/repositories/video_repository.dart';

class VideoProvider extends ChangeNotifier {
  final VideoRepository _repository;

  VideoProvider({VideoRepository? repository}) : _repository = repository ?? VideoRepository();

  List<VideoPost> _videos = [];
  bool _initialLoading = true;
  String? _error;

  bool _publishing = false;
  double _uploadProgress = 0;

  /// Index of the video currently centered in the vertical PageView.
  /// Every [VideoFeedItem] compares its own index against this to
  /// decide whether it should be playing — single source of truth so
  /// only one video is ever active at a time.
  int _activeIndex = 0;

  /// Videos we've already counted a view for this session, so rapid
  /// scroll-back-and-forth doesn't inflate the counter.
  final Set<String> _viewedThisSession = {};

  List<VideoPost> get videos => _videos;
  bool get isInitialLoading => _initialLoading;
  String? get error => _error;
  bool get isPublishing => _publishing;
  double get uploadProgress => _uploadProgress;
  int get activeIndex => _activeIndex;

  List<VideoPost> get savedVideos =>
      (_videos.where((v) => v.savedByMe).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  VideoPost? videoById(String id) {
    for (final v in _videos) {
      if (v.id == id) return v;
    }
    return null;
  }

  Future<void> init() async {
    if (_videos.isNotEmpty) return; // already initialized this session
    _initialLoading = true;
    _error = null;
    notifyListeners();
    try {
      _videos = await _repository.loadFeed();
    } catch (_) {
      _error = "We couldn't load videos. Check your connection and try again.";
    }
    _initialLoading = false;
    notifyListeners();
  }

  Future<void> retry() async {
    _videos = [];
    await init();
  }

  void setActiveIndex(int index) {
    if (_activeIndex == index) return;
    _activeIndex = index;
    notifyListeners();
    if (index >= 0 && index < _videos.length) {
      _registerView(_videos[index].id);
    }
  }

  void _registerView(String videoId) {
    if (_viewedThisSession.contains(videoId)) return;
    _viewedThisSession.add(videoId);
    _videos = [
      for (final v in _videos)
        if (v.id == videoId) v.copyWith(views: v.views + 1) else v,
    ];
    notifyListeners();
    unawaited(_repository.persist(_videos));
  }

  /// Publishes a new video: real Storage upload (progress + automatic
  /// retry via [StorageUploadService]) followed by a Firestore
  /// metadata write, then added to the local feed — see
  /// [VideoRepository.publishVideo] for the full breakdown of what's
  /// real vs. still local in this pipeline.
  Future<VideoPost> publish({
    required String authorName,
    required String category,
    required String caption,
    required String videoPath,
  }) async {
    _publishing = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      final video = await _repository.publishVideo(
        authorId: _repository.currentUid ?? '',
        authorName: authorName,
        category: category,
        caption: caption,
        localVideoPath: videoPath,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );

      _videos = [video, ..._videos];
      await _repository.persist(_videos);
      return video;
    } catch (e) {
      _error = "Couldn't upload your video. Check your connection and try again.";
      rethrow;
    } finally {
      _publishing = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  // ---------------- Like system ----------------

  Future<void> toggleLike(String videoId) async {
    final current = videoById(videoId);
    if (current == null) return;
    final turningOn = !current.likedByMe;

    _videos = [
      for (final v in _videos)
        if (v.id == videoId) v.copyWith(likedByMe: turningOn, likes: v.likes + (turningOn ? 1 : -1)) else v,
    ];
    notifyListeners();
    await _repository.persist(_videos);
  }

  Future<void> likeOnly(String videoId) async {
    final video = videoById(videoId);
    if (video == null || video.likedByMe) return;
    await toggleLike(videoId);
  }

  // ---------------- Save system ----------------

  Future<void> toggleSave(String videoId) async {
    final current = videoById(videoId);
    if (current == null) return;
    final turningOn = !current.savedByMe;

    _videos = [
      for (final v in _videos)
        if (v.id == videoId) v.copyWith(savedByMe: turningOn) else v,
    ];
    notifyListeners();
    await _repository.persist(_videos);
  }

  // ---------------- Share system ----------------

  Future<void> registerShare(String videoId) async {
    final current = videoById(videoId);
    if (current == null) return;
    _videos = [
      for (final v in _videos)
        if (v.id == videoId) v.copyWith(shares: v.shares + 1) else v,
    ];
    notifyListeners();
    await _repository.persist(_videos);
  }

  // ---------------- Comment system ----------------

  Future<void> addComment({
    required String videoId,
    required String authorName,
    required String authorLevel,
    required String text,
    String? parentId,
  }) async {
    if (text.trim().isEmpty) return;
    final current = videoById(videoId);
    if (current == null) return;

    final comment = _repository.buildComment(
      videoId: videoId,
      authorName: authorName,
      authorLevel: authorLevel,
      text: text,
      parentId: parentId,
    );

    _videos = [
      for (final v in _videos)
        if (v.id == videoId) v.copyWith(comments: [...v.comments, comment]) else v,
    ];
    notifyListeners();
    await _repository.persist(_videos);
  }

  Future<void> editComment({
    required String videoId,
    required String commentId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) return;
    _videos = [
      for (final v in _videos)
        if (v.id == videoId)
          v.copyWith(comments: [
            for (final c in v.comments)
              if (c.id == commentId) c.copyWith(text: newText.trim(), editedAt: DateTime.now()) else c,
          ])
        else
          v,
    ];
    notifyListeners();
    await _repository.persist(_videos);
  }

  Future<void> deleteComment({required String videoId, required String commentId}) async {
    _videos = [
      for (final v in _videos)
        if (v.id == videoId)
          v.copyWith(comments: v.comments.where((c) => c.id != commentId && c.parentId != commentId).toList())
        else
          v,
    ];
    notifyListeners();
    await _repository.persist(_videos);
  }
}
