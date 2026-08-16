import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_post_model.dart';

/// Local/mock persistence only — same pattern and same reasoning as
/// [PostLocalStorageService]: no backend yet, swap this file's
/// internals for a Firestore/Storage implementation later without
/// touching [VideoRepository]'s public API.
class VideoLocalStorageService {
  static const _kVideosKey = 'skillverse_videos_v1';

  Future<List<VideoPost>> loadVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVideosKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => VideoPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveVideos(List<VideoPost> videos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(videos.map((v) => v.toJson()).toList());
    await prefs.setString(_kVideosKey, raw);
  }
}
