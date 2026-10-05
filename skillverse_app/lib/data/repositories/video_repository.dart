import 'dart:io';
import 'package:dio/dio.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/post_categories.dart';
import '../models/comment_model.dart';
import '../models/video_post_model.dart';
import '../services/firestore_video_service.dart';
import '../services/storage_upload_service.dart';
import '../services/video_local_storage_service.dart';

/// Business layer for the Videos feed. Screens/providers talk to this,
/// never to [VideoLocalStorageService]/[StorageUploadService] directly.
///
/// The feed itself (list/likes/comments) is still local/mock — that's
/// its own, larger migration and out of scope here. What *is* real:
/// publishing now genuinely uploads to Firebase Storage (compressed
/// where applicable, with progress + retry) and records the resulting
/// URL in the `videos` Firestore collection, per the Storage
/// integration this repository was updated for.
class VideoRepository {
  final VideoLocalStorageService _localStorage;
  final StorageUploadService _upload;
  final FirestoreVideoService _firestoreVideos;
  final _uuid = const Uuid();

  VideoRepository({
    VideoLocalStorageService? storage,
    StorageUploadService? upload,
    FirestoreVideoService? firestoreVideos,
  })  : _localStorage = storage ?? VideoLocalStorageService(),
        _upload = upload ?? StorageUploadService(),
        _firestoreVideos = firestoreVideos ?? FirestoreVideoService();

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<VideoPost>> loadFeed() async {
    final saved = await _localStorage.loadVideos();
    if (saved.isNotEmpty) {
      return saved..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final seed = _mockSeed();
    await _localStorage.saveVideos(seed);
    return seed;
  }

  Future<void> persist(List<VideoPost> videos) => _localStorage.saveVideos(videos);

  /// Uploads the picked video file to Storage — with real progress and
  /// automatic retry (inherited from [StorageUploadService]) — then
  /// records it in Firestore and returns the finished [VideoPost].
  /// Video isn't compressed client-side (no video-compression package
  /// is wired in yet — that's flagged as a known gap, not silently
  /// skipped); the file uploads as picked.
  Future<VideoPost> publishVideo({
    required String authorId,
    required String authorName,
    required String category,
    required String caption,
    required String localVideoPath,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
    String? competitionBadge,
  }) async {
    final id = _uuid.v4();
    final storagePath = 'videos/$authorId/$id.mp4';

    final downloadUrl = await _upload.uploadFile(
      file: File(localVideoPath),
      storagePath: storagePath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );

    final video = VideoPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorLevel: 'Lv.1',
      category: category,
      caption: caption.trim(),
      videoUrl: downloadUrl,
      source: VideoSource.network,
      createdAt: DateTime.now(),
      competitionBadge: competitionBadge,
    );

    // Best-effort — a failure here shouldn't undo a successful upload
    // the user is already watching play back locally.
    try {
      await _firestoreVideos.recordPublishedVideo({
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorLevel': 'Lv.1',
        'category': category,
        'caption': caption.trim(),
        'videoUrl': downloadUrl,
      });
    } catch (_) {}

    return video;
  }

  Comment buildComment({
    required String videoId,
    required String authorName,
    required String authorLevel,
    required String text,
    String? parentId,
  }) {
    return Comment(
      id: _uuid.v4(),
      postId: videoId,
      authorName: authorName,
      authorLevel: authorLevel,
      text: text.trim(),
      createdAt: DateTime.now(),
      parentId: parentId,
    );
  }

  /// A handful of short, freely-licensed sample clips (Blender
  /// Foundation open movies, hosted on Google's public test bucket) so
  /// the Videos tab has real, scrollable, playable content without
  /// needing a media backend. User-uploaded videos never use this —
  /// only the seed set does.
    static const List<String> _sampleClipUrls = [
    // Programming
    'https://assets.mixkit.co/videos/41656/41656-360.mp4',
    'https://assets.mixkit.co/videos/41654/41654-360.mp4',
    'https://assets.mixkit.co/videos/41655/41655-360.mp4',
    'https://assets.mixkit.co/videos/41658/41658-360.mp4',
    'https://assets.mixkit.co/videos/41653/41653-360.mp4',
    'https://assets.mixkit.co/videos/41657/41657-360.mp4',
    'https://assets.mixkit.co/videos/41659/41659-360.mp4',
    'https://assets.mixkit.co/videos/50811/50811-360.mp4',
    // Fitness
    'https://assets.mixkit.co/videos/52079/52079-360.mp4',
    'https://assets.mixkit.co/videos/40246/40246-360.mp4',
    'https://assets.mixkit.co/videos/52080/52080-360.mp4',
    'https://assets.mixkit.co/videos/40788/40788-360.mp4',
    'https://assets.mixkit.co/videos/52082/52082-360.mp4',
    'https://assets.mixkit.co/videos/40776/40776-360.mp4',
    'https://assets.mixkit.co/videos/40249/40249-360.mp4',
    'https://assets.mixkit.co/videos/40159/40159-360.mp4',
  ];

  List<VideoPost> _mockSeed() {
    final now = DateTime.now();
    final authors = [
      ('Aarav Sharma', 12),
      ('Priya Verma', 9),
      ('Rohan Gupta', 15),
      ('Sanya Kapoor', 7),
      ('Vivaan Mehta', 21),
      ('Diya Iyer', 5),
      ('Kabir Khan', 18),
      ('Ananya Rao', 11),
      ('Ishaan Bose', 14),
      ('Meera Nair', 8),
      ('Arjun Reddy', 19),
      ('Tara Malhotra', 6),
    ];
    final captions = [
      'Quick tip that changed how I debug Flutter layouts 🔧',
      '3 composition tricks in 30 seconds 📸',
      'Cinematic transition breakdown — try this one!',
      'Neural networks explained in one clip.',
      'My 20-min warm-up before every session 💪',
      'How this lo-fi loop came together 🎧',
      'Pricing freelance work the right way.',
      'Study technique that actually worked for finals.',
      'Level design mistake everyone makes early on.',
      'Color theory in 40 seconds for cleaner UI.',
      'Entry for this week\'s SkillVerse challenge!',
      'Behind the scenes of my winning submission 🏆',
    ];
    // Every 4th seed video is tagged as a competition entry/winner so
    // the badge has real coverage to test against.
    final competitionLabels = ['Weekly Challenge Winner', 'Competition Entry', null, null];

    final videos = <VideoPost>[];
    for (var i = 0; i < _sampleClipUrls.length; i++) {
      final author = authors[i % authors.length];
      final category = postCategories[i % postCategories.length].name;
      final caption = captions[i % captions.length];
      final badge = competitionLabels[i % competitionLabels.length];
      videos.add(VideoPost(
        id: _uuid.v4(),
        authorName: author.$1,
        authorLevel: 'Lv.${author.$2}',
        category: category,
        caption: caption,
        videoUrl: _sampleClipUrls[i],
        source: VideoSource.network,
        createdAt: now.subtract(Duration(hours: i * 5 + 1)),
        likes: 80 + (i * 23) % 640,
        views: 900 + (i * 137) % 15000,
        shares: 5 + (i * 3) % 60,
        mockCommentCount: 3 + (i * 7) % 42,
        competitionBadge: badge,
      ));
    }
    return videos;
  }
}
