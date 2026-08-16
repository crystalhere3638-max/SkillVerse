import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/post_categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import 'widgets/media_preview.dart';
import 'widgets/publish_success_overlay.dart';

const int kMaxCaptionLength = 1000;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();

  String? _category;
  PostMediaType _mediaType = PostMediaType.none;
  String? _mediaPath;
  bool _showSuccess = false;
  bool _draftLoaded = false;

  @override
  void initState() {
    super.initState();
    _captionCtrl.addListener(() => setState(() {}));
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await context.read<PostProvider>().loadDraft();
    if (draft == null || !mounted) {
      setState(() => _draftLoaded = true);
      return;
    }
    setState(() {
      _captionCtrl.text = draft.caption;
      _category = draft.category;
      _mediaType = draft.mediaType;
      _mediaPath = draft.mediaPath;
      _draftLoaded = true;
    });
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _mediaType = PostMediaType.image;
      _mediaPath = file.path;
    });
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _mediaType = PostMediaType.video;
      _mediaPath = file.path;
    });
  }

  void _removeMedia() {
    setState(() {
      _mediaType = PostMediaType.none;
      _mediaPath = null;
    });
  }

  bool get _isEmpty => _captionCtrl.text.trim().isEmpty && _mediaType == PostMediaType.none;
  bool get _overLimit => _captionCtrl.text.length > kMaxCaptionLength;
  bool get _canPublish => !_isEmpty && !_overLimit && _category != null;

  Future<void> _saveDraft() async {
    final draft = PostDraft(
      caption: _captionCtrl.text,
      category: _category,
      mediaType: _mediaType,
      mediaPath: _mediaPath,
    );
    await context.read<PostProvider>().saveDraft(draft);
    if (!mounted) return;
    AppSnackbar.success(context, 'Draft saved');
  }

  Future<void> _publish() async {
    if (_isEmpty) {
      AppSnackbar.error(context, 'Add a caption or media before publishing.');
      return;
    }
    if (_overLimit) {
      AppSnackbar.error(context, 'Caption is over the $kMaxCaptionLength character limit.');
      return;
    }
    if (_category == null) {
      AppSnackbar.error(context, 'Pick a category for your post.');
      return;
    }

    final authorName = context.read<UserProvider>().profile?.username ??
        context.read<AuthProvider>().user?.username ??
        'You';

    final provider = context.read<PostProvider>();
    try {
      await provider.publish(
        authorName: authorName,
        category: _category!,
        caption: _captionCtrl.text,
        mediaType: _mediaType,
        mediaPath: _mediaPath,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, "Couldn't publish your post. Check your connection and tap Publish to retry.");
      return;
    }

    if (!mounted) return;
    setState(() => _showSuccess = true);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final captionLen = _captionCtrl.text.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _cancel),
        title: const Text('Create Post', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: provider.isPublishing ? null : _saveDraft,
            child: const Text('Save Draft', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_draftLoaded)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _overLimit ? AppColors.error : AppColors.divider),
                            ),
                            child: TextField(
                              controller: _captionCtrl,
                              maxLines: 6,
                              minLines: 3,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "What are you sharing today?",
                                hintStyle: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$captionLen/$kMaxCaptionLength',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _overLimit ? AppColors.error : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          if (_mediaType != PostMediaType.none && _mediaPath != null)
                            MediaPreview(mediaType: _mediaType, mediaPath: _mediaPath!, onRemove: _removeMedia)
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _MediaPickButton(
                                    icon: Icons.image_outlined,
                                    label: 'Select Image',
                                    onTap: _pickImage,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MediaPickButton(
                                    icon: Icons.videocam_outlined,
                                    label: 'Select Video',
                                    onTap: _pickVideo,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 26),
                          const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: postCategories.map((c) {
                              final active = _category == c.name;
                              return GestureDetector(
                                onTap: () => setState(() => _category = c.name),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: active ? c.accent.withOpacity(0.16) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: active ? c.accent : AppColors.divider, width: active ? 1.5 : 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(c.icon, size: 14, color: active ? c.accent : AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(c.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: active ? Colors.white : AppColors.textSecondary,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          if (provider.isPublishing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('Publishing… ${(provider.uploadProgress * 100).round()}%',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: provider.uploadProgress,
                                minHeight: 6,
                                backgroundColor: AppColors.divider,
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Cancel',
                            variant: AppButtonVariant.outlined,
                            onPressed: provider.isPublishing ? null : _cancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Publish',
                            isLoading: provider.isPublishing,
                            onPressed: _canPublish && !provider.isPublishing ? _publish : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_showSuccess)
            PublishSuccessOverlay(
              onDone: () {
                if (!mounted) return;
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _MediaPickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MediaPickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
