import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/feed_type.dart';
import '../data/models/activity_model.dart';
import '../data/models/comment_model.dart';
import '../data/models/post_model.dart';
import '../data/models/report_model.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/post_repository.dart';
import '../data/repositories/report_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _repository;
  final ActivityRepository _activityRepository;
  final ReportRepository _reportRepository;
  static const int pageSize = 6;

  PostProvider({
    PostRepository? repository,
    ActivityRepository? activityRepository,
    ReportRepository? reportRepository,
  })  : _repository = repository ?? PostRepository(),
        _activityRepository = activityRepository ?? ActivityRepository(),
        _reportRepository = reportRepository ?? ReportRepository();

  /// Live mirror of the `posts` (+ `comments`/`likes`/`saves`)
  /// Firestore collections, kept current by [_feedSub]. The feed
  /// shown on screen is always derived from this via
  /// [_repository.paginate].
  List<Post> _allPosts = [];
  List<ActivityEntry> _activityLog = [];
  StreamSubscription<List<Post>>? _feedSub;

  List<Post> _feedItems = [];
  FeedType _feedType = FeedType.latest;
  String? _categoryFilter; // null == "All"

  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  bool _publishing = false;
  double _uploadProgress = 0;

  // ---- getters consumed by the UI ----
  List<Post> get feedItems => _feedItems;
  FeedType get feedType => _feedType;
  String? get categoryFilter => _categoryFilter;
  bool get isInitialLoading => _initialLoading;
  bool get isRefreshing => _refreshing;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get isPublishing => _publishing;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  int get totalForCurrentFilter => _repository.countFor(source: _allPosts, category: _categoryFilter);

  /// Newest first.
  List<ActivityEntry> get activityLog => _activityLog.reversed.toList();

  List<Post> get savedPosts =>
      (_allPosts.where((p) => p.savedByMe).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  List<Post> get likedPosts =>
      (_allPosts.where((p) => p.likedByMe).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  List<Post> postsByAuthor(String authorName) => _allPosts.where((p) => p.authorName == authorName).toList();

  int commentsMadeBy(String authorName) =>
      _allPosts.expand((p) => p.comments).where((c) => c.authorName == authorName).length;

  Post? postById(String id) {
    for (final p in _allPosts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> init() async {
    if (_feedSub != null) return; // already listening this session
    _initialLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activityLog = await _activityRepository.load();
    } catch (_) {
      // Non-fatal — activity log is a nice-to-have, the feed itself
      // still loads below.
    }

    _feedSub = _repository.watchFeed(_repository.currentUid).listen(
      _onFeedUpdate,
      onError: (_) {
        _error = "We couldn't load your feed. Check your connection and try again.";
        _initialLoading = false;
        notifyListeners();
      },
    );
  }

  /// Handles every live update from Firestore. The very first
  /// emission drives the initial page load (skeleton -> content); any
  /// emission after that just refreshes engagement numbers/comments
  /// on posts already on screen, in place, so a like count ticking up
  /// elsewhere never yanks the user's scroll position. Brand-new
  /// posts land at the top on the next [refresh] or filter change —
  /// same trade-off most realtime feeds make.
  void _onFeedUpdate(List<Post> posts) {
    final isFirstLoad = _initialLoading;
    _allPosts = posts;
    if (isFirstLoad) {
      _loadFirstPage();
      _initialLoading = false;
    } else {
      _syncFeedItemsFromAllPosts();
    }
    _error = null;
    notifyListeners();
  }

  /// Re-runs the initial load after an error state — bound to the
  /// Retry button shown by [ErrorStateView].
  Future<void> retry() async {
    await _feedSub?.cancel();
    _feedSub = null;
    _allPosts = [];
    _initialLoading = true;
    await init();
  }

  void _loadFirstPage() {
    _page = 0;
    final first = _repository.paginate(
      source: _allPosts,
      type: _feedType,
      category: _categoryFilter,
      page: 0,
      pageSize: pageSize,
    );
    _feedItems = first;
    _hasMore = first.length == pageSize;
    _page = 1;
  }

  Future<void> setFeedType(FeedType type) async {
    if (_feedType == type) return;
    _feedType = type;
    _initialLoading = true;
    notifyListeners();
    // Tiny delay so the tab switch shows a brief skeleton instead of a
    // jarring instant swap — keeps perceived performance smooth.
    await Future.delayed(const Duration(milliseconds: 220));
    _loadFirstPage();
    _initialLoading = false;
    notifyListeners();
  }

  Future<void> setCategoryFilter(String? category) async {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    _initialLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 220));
    _loadFirstPage();
    _initialLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _refreshing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    // _allPosts is already live via the Firestore listener — refresh
    // just re-pages from the top so anything new lands in view.
    _loadFirstPage();
    _refreshing = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading || _refreshing) return;
    _loadingMore = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 450));
    final next = _repository.paginate(
      source: _allPosts,
      type: _feedType,
      category: _categoryFilter,
      page: _page,
      pageSize: pageSize,
    );
    _feedItems = [..._feedItems, ...next];
    _hasMore = next.length == pageSize;
    _page += 1;
    _loadingMore = false;
    notifyListeners();
  }

  Future<PostDraft?> loadDraft() => _repository.loadDraft();
  Future<void> saveDraft(PostDraft draft) => _repository.saveDraft(draft);
  Future<void> clearDraft() => _repository.clearDraft();

  /// Publishes a new post: uploads media to Firebase Storage (with
  /// real progress reported through [uploadProgress]) then writes the
  /// post document to Firestore. The live [_feedSub] listener will
  /// pick the new post up on its own; we also eagerly re-page so it's
  /// visible immediately rather than waiting on the round trip.
  Future<Post> publish({
    required String authorName,
    required String category,
    required String caption,
    required PostMediaType mediaType,
    String? mediaPath,
  }) async {
    _publishing = true;
    _uploadProgress = 0;
    notifyListeners();

    try {
      final uid = _repository.currentUid ?? '';
      final post = await _repository.publishPost(
        authorId: uid,
        authorName: authorName,
        authorLevel: 'Lv.1',
        category: category,
        caption: caption,
        mediaType: mediaType,
        localMediaPath: mediaPath,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );

      _allPosts = [post, ..._allPosts];
      await _repository.clearDraft();
      await _logActivity(type: ActivityType.published, postId: post.id, category: post.category);

      // Re-derive the visible feed so the new post lands wherever the
      // active sort/filter says it should (top of Latest; wherever its
      // score lands in Trending/Recommended).
      _loadFirstPage();

      return post;
    } finally {
      _publishing = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  // ---------------- Like system ----------------

  Future<void> toggleLike(String postId) async {
    final current = postById(postId);
    if (current == null) return;
    final turningOn = !current.likedByMe;
    final uid = _repository.currentUid;
    if (uid == null) return;

    // Optimistic local update for instant feedback — the Firestore
    // listener will reconcile with the server value moments later
    // (normally converging to the exact same numbers).
    _allPosts = [
      for (final p in _allPosts)
        if (p.id == postId) p.copyWith(likedByMe: turningOn, likes: p.likes + (turningOn ? 1 : -1)) else p,
    ];
    _syncFeedItemsFromAllPosts();
    notifyListeners();

    try {
      await _repository.setLiked(postId: postId, uid: uid, liked: turningOn);
    } catch (_) {
      // Roll back the optimistic update if the write failed (e.g.
      // offline with no queued retry, permission denied).
      _allPosts = [
        for (final p in _allPosts)
          if (p.id == postId) p.copyWith(likedByMe: !turningOn, likes: p.likes + (turningOn ? -1 : 1)) else p,
      ];
      _syncFeedItemsFromAllPosts();
      notifyListeners();
      return;
    }

    if (turningOn) {
      await _logActivity(type: ActivityType.liked, postId: postId, category: current.category);
    }
  }

  /// Used by double-tap-to-like: only ever turns a like ON (matches
  /// the familiar "double tap" pattern from other apps) — never
  /// unlikes, so a second accidental double-tap is harmless.
  Future<void> likeOnly(String postId) async {
    final post = postById(postId);
    if (post == null || post.likedByMe) return;
    await toggleLike(postId);
  }

  // ---------------- Save system ----------------

  Future<void> toggleSave(String postId) async {
    final current = postById(postId);
    if (current == null) return;
    final turningOn = !current.savedByMe;
    final uid = _repository.currentUid;
    if (uid == null) return;

    _allPosts = [
      for (final p in _allPosts)
        if (p.id == postId) p.copyWith(savedByMe: turningOn) else p,
    ];
    _syncFeedItemsFromAllPosts();
    notifyListeners();

    try {
      await _repository.setSaved(postId: postId, uid: uid, saved: turningOn);
    } catch (_) {
      _allPosts = [
        for (final p in _allPosts)
          if (p.id == postId) p.copyWith(savedByMe: !turningOn) else p,
      ];
      _syncFeedItemsFromAllPosts();
      notifyListeners();
      return;
    }

    if (turningOn) {
      await _logActivity(type: ActivityType.saved, postId: postId, category: current.category);
    }
  }

  // ---------------- Comment system ----------------

  Future<void> addComment({
    required String postId,
    required String authorName,
    required String authorLevel,
    required String text,
    String? parentId,
  }) async {
    if (text.trim().isEmpty) return;
    final current = postById(postId);
    if (current == null) return;
    final uid = _repository.currentUid ?? '';

    await _repository.addComment(
      postId: postId,
      authorId: uid,
      authorName: authorName,
      authorLevel: authorLevel,
      text: text,
      parentId: parentId,
    );
    // The live comments listener delivers the new comment (with its
    // real Firestore id) back into _allPosts within a moment — no
    // local splice needed here, which avoids a duplicate entry.

    await _logActivity(
      type: parentId == null ? ActivityType.commented : ActivityType.replied,
      postId: postId,
      category: current.category,
    );
  }

  Future<void> editComment({
    required String postId,
    required String commentId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) return;
    await _repository.editComment(commentId: commentId, newText: newText);
  }

  /// Deletes a comment. If it's a top-level comment, its replies are
  /// deleted with it (no orphaned replies left behind).
  Future<void> deleteComment({required String postId, required String commentId}) async {
    await _repository.deleteComment(commentId);
  }

  // ---------------- Report system ----------------

  Future<void> submitReport({required String postId, required ReportReason reason}) async {
    await _reportRepository.submit(postId: postId, reason: reason);
  }

  // ---------------- internals ----------------

  Future<void> _logActivity({
    required ActivityType type,
    required String postId,
    required String category,
  }) async {
    _activityLog = await _activityRepository.append(
      current: _activityLog,
      type: type,
      postId: postId,
      postCategory: category,
    );
    notifyListeners();
  }

  /// Updates already-visible cards in place without re-sorting/paging,
  /// so liking/commenting mid-scroll never jumps the list around.
  void _syncFeedItemsFromAllPosts() {
    final byId = {for (final p in _allPosts) p.id: p};
    _feedItems = [for (final p in _feedItems) byId[p.id] ?? p];
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }
}
