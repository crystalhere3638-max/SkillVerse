import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/setup/category_screen.dart';
import '../../screens/setup/goal_screen.dart';
import '../../screens/home/home_shell.dart';

/// The single source of truth for top-level navigation:
///
///   unknown            -> Splash
///   unauthenticated     -> Login (Signup / Forgot Password reachable from there)
///   authenticated, no category  -> Category selection
///   authenticated, no goal      -> Goal selection
///   authenticated, complete     -> Home
///
/// This mirrors the "Auto Login" + "after login" rules exactly:
/// Firebase's persisted session is checked once on cold start via
/// [AuthProvider], with no extra local session bookkeeping needed.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _listeningUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    if (auth.status == AuthStatus.unknown) {
      return const SplashScreen();
    }

    if (auth.status == AuthStatus.unauthenticated || auth.user == null) {
      if (_listeningUid != null) {
        userProvider.stop();
        _listeningUid = null;
      }
      return const LoginScreen();
    }

    final uid = auth.user!.uid;
    if (_listeningUid != uid) {
      _listeningUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) => userProvider.listenTo(uid));
    }

    final profile = userProvider.profile ?? auth.user!;

    if (profile.mainCategory == null) {
      return const CategoryScreen();
    }
    if (profile.goal == null) {
      return const GoalScreen(mainCategory: 'General');
    }
    return const HomeShell();
  }
}
