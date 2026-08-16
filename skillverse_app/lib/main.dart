import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/competition_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/mission_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/post_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/video_provider.dart';
import 'presentation/screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Requires `flutterfire configure` to have generated a real
  // firebase_options.dart for your project — see that file's header.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SkillVerseApp());
}

class SkillVerseApp extends StatelessWidget {
  const SkillVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        // Gamification — local mock data for Beta V1; swap for
        // Firestore-backed repositories once the backend is ready.
        ChangeNotifierProvider(create: (_) => CompetitionProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'SkillVerse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const AuthGate(),
      ),
    );
  }
}
