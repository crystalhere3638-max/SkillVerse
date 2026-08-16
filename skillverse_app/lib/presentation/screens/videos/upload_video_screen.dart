import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/post_categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/video_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../create_post/widgets/publish_success_overlay.dart';

const int _kMaxCaptionLength = 500;

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();

  String? _category;
  String? _videoPath;
  VideoPlayerController? _previewController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _captionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    _previewController?.dispose();
    final controller = VideoPlayerController.file(File(file.path));
    await controller.initialize();
    await controller.setLooping(true);
    controller.play();

    if (!mounted) return;
    setState(() {
      _videoPath = file.path;
      _previewController = controller;
    });
  }

  bool get _canPublish => _videoPath != null && _category != null && _captionCtrl.text.trim().isNotEmpty;

  Future<void> _publish() async {
    if (!_canPublish) return;
    final username =
        context.read<UserProvider>().profile?.username ?? context.read<AuthProvider>().user?.username ?? 'You';

    try {
      await context.read<VideoProvider>().publish(
            authorName: username,
            category: _category!,
            caption: _captionCtrl.text,
            videoPath: _videoPath!,
          );
      if (!mounted) return;
      setState(() => _showSuccess = true);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, "Couldn't publish your video. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final overLimit = _captionCtrl.text.length > _kMaxCaptionLength;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: provider.isPublishing ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Upload Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                GestureDetector(
                  onTap: provider.isPublishing ? null : _pickVideo,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _previewController != null && _previewController!.value.isInitialized
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _previewController!.value.size.width,
                                  height: _previewController!.value.size.height,
                                  child: VideoPlayer(_previewController!),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: GestureDetector(
                                  onTap: provider.isPublishing ? null : _pickVideo,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration:
                                        BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(color: AppColors.surfaceSunken, shape: BoxShape.circle),
                                child: const Icon(Icons.video_call_outlined, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(height: 12),
                              const Text('Tap to choose a video',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                              const SizedBox(height: 4),
                              const Text('From your gallery',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Caption', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: overLimit ? AppColors.error : AppColors.divider),
                  ),
                  child: TextField(
                    controller: _captionCtrl,
                    enabled: !provider.isPublishing,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'Describe your video…',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${_captionCtrl.text.length}/$_kMaxCaptionLength',
                        style: TextStyle(fontSize: 10.5, color: overLimit ? AppColors.error : AppColors.textMuted)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: postCategories.map((c) {
                    final selected = _category == c.name;
                    return GestureDetector(
                      onTap: provider.isPublishing ? null : () => setState(() => _category = c.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? c.accent.withOpacity(0.16) : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: selected ? c.accent : AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(c.icon, size: 14, color: selected ? c.accent : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(c.name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? c.accent : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                if (provider.isPublishing) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: provider.uploadProgress,
                      minHeight: 8,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Uploading… ${(provider.uploadProgress * 100).round()}%',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: provider.isPublishing ? 'Publishing…' : 'Publish',
                  isLoading: provider.isPublishing,
                  onPressed: (_canPublish && !overLimit && !provider.isPublishing) ? _publish : null,
                ),
              ],
            ),
          ),
          if (_showSuccess)
            PublishSuccessOverlay(
              onDone: () {
                if (mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
