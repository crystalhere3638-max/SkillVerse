import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `users/{uid}` Firestore document exactly.
/// Field names here must match Firestore field names one-to-one.
class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final String? mainCategory;
  final String? goal;
  final int xp;
  final int coins;
  final int level;
  final double skillRating;
  final int followers;
  final int following;
  final int streak;
  final bool verified;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    this.mainCategory,
    this.goal,
    this.xp = 0,
    this.coins = 0,
    this.level = 1,
    this.skillRating = 0,
    this.followers = 0,
    this.following = 0,
    this.streak = 0,
    this.verified = false,
    this.createdAt,
    this.lastLogin,
  });

  /// A profile is "complete" once onboarding (category + goal) is done.
  /// Used to route the user straight to Home vs. back into onboarding.
  bool get isProfileComplete => mainCategory != null && goal != null;

  factory AppUser.newFromAuth({
    required String uid,
    required String username,
    required String email,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid,
      username: username,
      email: email,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      username: (map['username'] as String?) ?? 'Learner',
      email: (map['email'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      mainCategory: map['mainCategory'] as String?,
      goal: map['goal'] as String?,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      skillRating: (map['skillRating'] as num?)?.toDouble() ?? 0,
      followers: (map['followers'] as num?)?.toInt() ?? 0,
      following: (map['following'] as num?)?.toInt() ?? 0,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      verified: (map['verified'] as bool?) ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser.fromMap({...data, 'uid': doc.id});
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'mainCategory': mainCategory,
      'goal': goal,
      'xp': xp,
      'coins': coins,
      'level': level,
      'skillRating': skillRating,
      'followers': followers,
      'following': following,
      'streak': streak,
      'verified': verified,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? username,
    String? photoUrl,
    String? mainCategory,
    String? goal,
    int? xp,
    int? coins,
    int? level,
    double? skillRating,
    int? followers,
    int? following,
    int? streak,
    bool? verified,
  }) {
    return AppUser(
      uid: uid,
      username: username ?? this.username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      mainCategory: mainCategory ?? this.mainCategory,
      goal: goal ?? this.goal,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      level: level ?? this.level,
      skillRating: skillRating ?? this.skillRating,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      streak: streak ?? this.streak,
      verified: verified ?? this.verified,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }
}
