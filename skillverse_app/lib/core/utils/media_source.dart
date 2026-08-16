/// Posts created before Firebase Storage was wired in stored a local
/// device file path in `mediaPath`. Posts published against Firestore
/// store a real Storage download URL instead. Widgets that render
/// media need to pick `Image.network`/`VideoPlayerController.networkUrl`
/// vs the `.file` variants accordingly — this one check is shared so
/// every render site (post_card, feed_video_player) agrees.
bool isNetworkMediaPath(String path) => path.startsWith('http://') || path.startsWith('https://');
