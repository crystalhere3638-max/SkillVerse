import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/connectivity_checker.dart';

/// Slim, dismiss-free banner that appears only while offline. Recent
/// posts still show (they're cached locally), so this is purely
/// informational rather than blocking.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _online = true;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    ConnectivityChecker.instance.start();
    _online = ConnectivityChecker.instance.lastKnown;
    _sub = ConnectivityChecker.instance.onStatusChange.listen((online) {
      if (mounted) setState(() => _online = online);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: _online
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: AppColors.orange.withOpacity(0.16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.orange),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "You're offline — showing your recently cached feed",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.orange),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
