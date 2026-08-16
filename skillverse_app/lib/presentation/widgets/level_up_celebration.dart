import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/skill_level_engine.dart';

/// Call this whenever a level-up is detected (see UserProvider.pendingLevelUp).
/// Shows a full celebration: burst animation, new title reveal, and the
/// rewards earned for reaching it.
Future<void> showLevelUpCelebration(
  BuildContext context, {
  required int newLevel,
  int xpEarned = 0,
  int coinsEarned = 0,
  String? badgeUnlocked,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Level up',
    barrierColor: Colors.black.withOpacity(0.72),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => _LevelUpDialog(
      newLevel: newLevel,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      badgeUnlocked: badgeUnlocked,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return Transform.scale(
        scale: 0.7 + (0.3 * curved.value),
        child: Opacity(opacity: anim.value.clamp(0, 1), child: child),
      );
    },
  );
}

class _LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final int xpEarned;
  final int coinsEarned;
  final String? badgeUnlocked;

  const _LevelUpDialog({required this.newLevel, required this.xpEarned, required this.coinsEarned, this.badgeUnlocked});

  @override
  State<_LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<_LevelUpDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final SkillLevelInfo _info;

  @override
  void initState() {
    super.initState();
    _info = SkillLevelInfo.fromLevel(widget.newLevel);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 320,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Confetti burst behind the card.
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  size: const Size(320, 420),
                  painter: _ConfettiPainter(progress: _controller.value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.25), blurRadius: 40, spreadRadius: 4)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.gold, AppColors.orange]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 24)],
                          ),
                          child: Center(child: Text(_info.emoji, style: const TextStyle(fontSize: 40))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('LEVEL UP!',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: 2)),
                      const SizedBox(height: 6),
                      Text('Level ${widget.newLevel}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('You are now a ${_info.title}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      if (widget.xpEarned > 0 || widget.coinsEarned > 0 || widget.badgeUnlocked != null)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            if (widget.xpEarned > 0) _RewardChip(icon: Icons.bolt_rounded, label: '+${widget.xpEarned} XP', color: AppColors.primary),
                            if (widget.coinsEarned > 0) _RewardChip(icon: Icons.monetization_on_rounded, label: '+${widget.coinsEarned} Coins', color: AppColors.gold),
                            if (widget.badgeUnlocked != null) _RewardChip(icon: Icons.workspace_premium_rounded, label: widget.badgeUnlocked!, color: AppColors.blue),
                          ],
                        ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Keep Going', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RewardChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Lightweight custom-painted confetti burst — no extra package needed.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final List<_ConfettiPiece> _pieces = List.generate(26, (i) {
    final rnd = Random(i * 97);
    return _ConfettiPiece(
      angle: rnd.nextDouble() * pi * 2,
      speed: 80 + rnd.nextDouble() * 120,
      color: [AppColors.gold, AppColors.primary, AppColors.blue, AppColors.orange][i % 4],
      size: 5 + rnd.nextDouble() * 5,
    );
  });

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final origin = Offset(size.width / 2, 70);
    final fade = (1 - progress).clamp(0, 1).toDouble();
    for (final p in _pieces) {
      final t = progress;
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t + (140 * t * t); // gravity
      final paint = Paint()..color = p.color.withOpacity(fade);
      final rect = Rect.fromCenter(center: origin + Offset(dx, dy), width: p.size, height: p.size * 1.6);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(progress * pi * 3 * (p.angle > pi ? 1 : -1));
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiPiece {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  _ConfettiPiece({required this.angle, required this.speed, required this.color, required this.size});
}
