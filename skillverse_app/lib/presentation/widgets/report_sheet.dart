import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/report_model.dart';
import '../../providers/post_provider.dart';

class ReportSheet extends StatefulWidget {
  final String postId;
  const ReportSheet({super.key, required this.postId});

  static Future<void> show(BuildContext context, String postId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(postId: postId),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  ReportReason? _selected;
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    await context.read<PostProvider>().submitReport(postId: widget.postId, reason: _selected!);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
    await Future.delayed(const Duration(milliseconds: 1300));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, top: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, t, child) => Transform.scale(scale: t, child: child),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Report submitted', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          const Text("Thanks for helping keep SkillVerse safe.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Report post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Text('Why are you reporting this post?', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
        ...ReportReason.values.map((reason) {
          final active = _selected == reason;
          return InkWell(
            onTap: () => setState(() => _selected = reason),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(reason.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: active ? Colors.white : AppColors.textSecondary,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        )),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: active ? AppColors.primary : AppColors.divider, width: 2),
                    ),
                    child: active ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selected == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: AppColors.error.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }
}
