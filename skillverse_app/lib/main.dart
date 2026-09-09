import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'presentation/screens/home/home_shell.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/repositories/auth_repository.dart';
import 'providers/auth_provider.dart' as app_auth;
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


void _installGlobalErrorHandlers() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'UI ERROR:\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      ),
    );
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM ERROR: $error\n$stack');
    return true;
  };


  // Requires `flutterfire configure` to have generated a real
  // firebase_options.dart for your project — see that file's header.
  Object? startupError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await AuthRepository().signInAnonymously();
      } catch (_) {
        // Non-fatal: feed/UI will still show empty/error states gracefully.
      }
    }
  } catch (e, st) {
    startupError = e;
    debugPrint('STARTUP ERROR: $e\n$st');
  }

  if (startupError != null) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Startup failed:\n$startupError',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(const SkillVerseApp());
}

class SkillVerseApp extends StatelessWidget {
  const SkillVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
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
      home: const HomeShell(),
      ),
    );
  }
}
