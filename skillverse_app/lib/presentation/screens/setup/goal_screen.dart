import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/step_bar.dart';

class _GoalDef {
  final String name;
  final String desc;
  final IconData icon;
  const _GoalDef(this.name, this.desc, this.icon);
}

const _goals = [
  _GoalDef('Learn', 'Pick up new skills from experts', Icons.menu_book_outlined),
  _GoalDef('Compete', 'Test yourself against the world', Icons.emoji_events_outlined),
  _GoalDef('Earn', 'Turn your skills into income', Icons.attach_money),
  _GoalDef('Teach', 'Share your knowledge with others', Icons.mic_none_outlined),
];

class GoalScreen extends StatefulWidget {
  final String mainCategory;
  const GoalScreen({super.key, required this.mainCategory});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  String? _selected;
  bool _saving = false;

  Future<void> _finish() async {
    if (_selected == null) return;
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await userProvider.completeOnboarding(
        uid: uid,
        mainCategory: widget.mainCategory,
        goal: _selected!,
      );
      auth.applyOnboarding(mainCategory: widget.mainCategory, goal: _selected!);
      // AuthGate is listening to the live Firestore stream and will
      // automatically navigate to Home once the document updates.
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Could not save your goal. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      ),
                      const Expanded(child: StepBar(step: 2)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text("What's Your Goal?",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  const Text("Tell us what you're here for — we'll personalize your feed.",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final g = _goals[index];
                  final active = _selected == g.name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selected = g.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: active ? AppColors.primary : AppColors.divider, width: active ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(active ? 0.3 : 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(g.icon, color: active ? AppColors.primary : AppColors.textSecondary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(g.desc,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? AppColors.primary : Colors.transparent,
                              border: Border.all(color: active ? AppColors.primary : AppColors.divider, width: 2),
                            ),
                            child: active ? const Icon(Icons.check, size: 13, color: Colors.black) : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                label: 'Enter SkillVerse',
                isLoading: _saving,
                onPressed: _selected == null ? null : _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
