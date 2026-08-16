import '../../data/models/post_model.dart';

/// Placeholder for real sharing (e.g. via `share_plus`). Kept as its
/// own service so wiring up an actual share sheet later is a
/// one-file change — nothing else in the app should need to know
/// sharing isn't "real" yet.
class ShareService {
  Future<bool> sharePost(Post post) async {
    // Simulated — no share_plus dependency added yet per spec.
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  String buildShareLink(Post post) => 'skillverse://post/${post.id}';
}
