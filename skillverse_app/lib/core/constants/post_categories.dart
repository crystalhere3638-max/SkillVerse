import 'package:flutter/material.dart';

class PostCategory {
  final String name;
  final IconData icon;
  final Color accent;
  const PostCategory(this.name, this.icon, this.accent);
}

/// Categories available when creating a post, in the order given by
/// the feature spec. Intentionally separate from the onboarding
/// category list so existing completed screens stay untouched.
const List<PostCategory> postCategories = [
  PostCategory('Gaming', Icons.sports_esports_outlined, Color(0xFF00E676)),
  PostCategory('Programming', Icons.code, Color(0xFF00BCD4)),
  PostCategory('Graphic Design', Icons.brush_outlined, Color(0xFFFFC107)),
  PostCategory('Video Editing', Icons.movie_creation_outlined, Color(0xFFFF7043)),
  PostCategory('Photography', Icons.camera_alt_outlined, Color(0xFFAB47BC)),
  PostCategory('AI', Icons.psychology_outlined, Color(0xFF42A5F5)),
  PostCategory('Fitness', Icons.fitness_center_outlined, Color(0xFF66BB6A)),
  PostCategory('Music', Icons.music_note_outlined, Color(0xFFEC407A)),
  PostCategory('Business', Icons.trending_up, Color(0xFF7E57C2)),
  PostCategory('Education', Icons.school_outlined, Color(0xFFFFCA28)),
];

Color categoryColor(String? name) {
  return postCategories
      .firstWhere((c) => c.name == name, orElse: () => postCategories.first)
      .accent;
}

IconData categoryIcon(String? name) {
  return postCategories
      .firstWhere((c) => c.name == name, orElse: () => postCategories.first)
      .icon;
}
