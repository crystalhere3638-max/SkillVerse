import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

/// Local persistence for just the in-progress composer draft. Posts
/// themselves, along with their likes, saves, and comments, now live
/// in Firestore (see PostRepository / FirestorePostService) — a
/// draft stays local since it's transient per-device typing state,
/// not published content.
class PostLocalStorageService {
  static const _kDraftKey = 'skillverse_post_draft_v1';

  Future<PostDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDraftKey);
    if (raw == null || raw.isEmpty) return null;
    return PostDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveDraft(PostDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
  }
}
