import '../../data/models/post_model.dart';
import 'package:share_plus/share_plus.dart';

/// Placeholder for real sharing (e.g. via `share_plus`). Kept as its
/// own service so wiring up an actual share sheet later is a
/// one-file change — nothing else in the app should need to know
/// sharing isn't "real" yet.
class ShareService {
  Future<bool> sharePost(Post post) async {
    final result = await SharePlus.instance.share(
  ShareParams(text: '${post.caption}\n\n${buildShareLink(post)}'),
);
return result.status == ShareResultStatus.success;
  }

  String buildShareLink(Post post) => 'https://skillverse.app/post/${post.id}';
}
