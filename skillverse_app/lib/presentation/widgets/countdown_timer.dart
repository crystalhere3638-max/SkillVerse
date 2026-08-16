import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Live-ticking countdown to [target]. Updates once a minute (not every
/// second) to stay light on rebuilds — plenty precise for competition
/// deadlines that are hours or days away.
class CountdownTimer extends StatefulWidget {
  final DateTime target;
  final bool compact;

  const CountdownTimer({super.key, required this.target, this.compact = false});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    if (d.isNegative) return 'Ended';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h left';
    if (hours > 0) return '${hours}h ${mins}m left';
    return '${mins}m left';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.target.difference(DateTime.now());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: widget.compact ? 13 : 16, color: AppColors.orange),
        const SizedBox(width: 4),
        Text(
          _format(d),
          style: TextStyle(
            fontSize: widget.compact ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }
}
