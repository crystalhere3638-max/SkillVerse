import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/step_bar.dart';
import 'goal_screen.dart';

class _CategoryDef {
  final String name;
  final IconData icon;
  final Color accent;
  const _CategoryDef(this.name, this.icon, this.accent);
}

const _categories = [
  _CategoryDef('Gaming', Icons.sports_esports_outlined, Color(0xFF00E676)),
  _CategoryDef('Programming', Icons.code, Color(0xFF00BCD4)),
  _CategoryDef('Graphic Design', Icons.brush_outlined, Color(0xFFFFC107)),
  _CategoryDef('Video Editing', Icons.movie_creation_outlined, Color(0xFFFF7043)),
  _CategoryDef('Photography', Icons.camera_alt_outlined, Color(0xFFAB47BC)),
  _CategoryDef('AI', Icons.psychology_outlined, Color(0xFF42A5F5)),
  _CategoryDef('Music', Icons.music_note_outlined, Color(0xFFEC407A)),
  _CategoryDef('Fitness', Icons.fitness_center_outlined, Color(0xFF66BB6A)),
  _CategoryDef('Education', Icons.school_outlined, Color(0xFFFFCA28)),
  _CategoryDef('Business', Icons.trending_up, Color(0xFF7E57C2)),
];

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      // Goal is required by the schema together with category, so we
      // stage the category client-side and persist both once the goal
      // step completes. See GoalScreen for the actual Firestore write.
      auth.applyOnboarding(mainCategory: _selected!, goal: auth.user?.goal ?? '');
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GoalScreen(mainCategory: _selected!),
      ));
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Could not continue. Please try again.');
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  StepBar(step: 1),
                  SizedBox(height: 20),
                  Text('Choose Your Category',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  SizedBox(height: 6),
                  Text('Pick the skill area you care about most.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final c = _categories[index];
                  final active = _selected == c.name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selected = c.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: active ? c.accent.withOpacity(0.12) : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: active ? c.accent : AppColors.divider, width: active ? 1.5 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: c.accent.withOpacity(active ? 0.25 : 0.11),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(c.icon, color: active ? c.accent : AppColors.textSecondary, size: 22),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            c.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : AppColors.textSecondary,
                            ),
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
                label: 'Continue',
                isLoading: _saving,
                onPressed: _selected == null ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
