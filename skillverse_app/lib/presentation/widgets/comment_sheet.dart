import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import 'comment_tile.dart';
import 'empty_state.dart';

const int kMaxCommentLength = 300;
const List<String> _quickEmojis = ['😀', '🔥', '❤️', '👏', '😂', '💯', '🚀', '👍'];

class CommentSheet extends StatefulWidget {
  final String postId;
  const CommentSheet({super.key, required this.postId});

  static Future<void> show(BuildContext context, String postId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(postId: postId),
    );
  }

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

enum _ComposeMode { newComment, reply, edit }

class _CommentSheetState extends State<CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  _ComposeMode _mode = _ComposeMode.newComment;
  Comment? _target; // comment being replied to or edited

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _currentUsername =>
      context.read<UserProvider>().profile?.username ?? context.read<AuthProvider>().user?.username ?? 'You';
  String get _currentUserLevel => 'Lv.${context.read<UserProvider>().profile?.level ?? 1}';

  void _startReply(Comment target) {
    setState(() {
      _mode = _ComposeMode.reply;
      _target = target;
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  void _startEdit(Comment target) {
    setState(() {
      _mode = _ComposeMode.edit;
      _target = target;
      _controller.text = target.text;
    });
    _focusNode.requestFocus();
  }

  void _cancelSpecialMode() {
    setState(() {
      _mode = _ComposeMode.newComment;
      _target = null;
      _controller.clear();
    });
  }

  Future<void> _confirmDelete(BuildContext context, Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete comment?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PostProvider>().deleteComment(postId: widget.postId, commentId: comment.id);
      if (_target?.id == comment.id) _cancelSpecialMode();
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > kMaxCommentLength) return;
    final provider = context.read<PostProvider>();

    if (_mode == _ComposeMode.edit && _target != null) {
      await provider.editComment(postId: widget.postId, commentId: _target!.id, newText: text);
    } else {
      await provider.addComment(
        postId: widget.postId,
        authorName: _currentUsername,
        authorLevel: _currentUserLevel,
        text: text,
        parentId: _mode == _ComposeMode.reply ? _target?.id : null,
      );
    }
    _cancelSpecialMode();
  }

  void _insertEmoji(String emoji) {
    final sel = _controller.selection;
    final text = _controller.text;
    final insertAt = sel.start >= 0 ? sel.start : text.length;
    final newText = text.replaceRange(insertAt, sel.end >= 0 ? sel.end : text.length, emoji);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _currentUsername;
    final overLimit = _controller.text.length > kMaxCommentLength;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
                ),
                Consumer<PostProvider>(
                  builder: (context, provider, _) {
                    final post = provider.postById(widget.postId);
                    final count = post?.commentCount ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('$count Comment${count == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: Consumer<PostProvider>(
                    builder: (context, provider, _) {
                      final post = provider.postById(widget.postId);
                      final topLevel = post?.topLevelComments ?? const <Comment>[];

                      if (topLevel.isEmpty) {
                        return const EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No comments yet',
                          message: 'Be the first to say something.',
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        itemCount: topLevel.length,
                        itemBuilder: (context, index) {
                          final comment = topLevel[index];
                          final replies = post!.repliesTo(comment.id);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommentTile(
                                comment: comment,
                                isOwn: comment.authorName == username,
                                onReply: () => _startReply(comment),
                                onEdit: () => _startEdit(comment),
                                onDelete: () => _confirmDelete(context, comment),
                              ),
                              for (final reply in replies)
                                CommentTile(
                                  key: ValueKey(reply.id),
                                  comment: reply,
                                  isReply: true,
                                  isOwn: reply.authorName == username,
                                  onReply: () => _startReply(comment),
                                  onEdit: () => _startEdit(reply),
                                  onDelete: () => _confirmDelete(context, reply),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _mode == _ComposeMode.newComment
                      ? const SizedBox.shrink()
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: AppColors.primary.withOpacity(0.08),
                          child: Row(
                            children: [
                              Icon(_mode == _ComposeMode.edit ? Icons.edit_outlined : Icons.reply_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _mode == _ComposeMode.edit
                                      ? 'Editing your comment'
                                      : 'Replying to ${_target?.authorName ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                              GestureDetector(
                                onTap: _cancelSpecialMode,
                                child: const Icon(Icons.close, size: 15, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                ),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quickEmojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _insertEmoji(_quickEmojis[i]),
                      child: Container(
                        width: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                        child: Text(_quickEmojis[i], style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: overLimit ? AppColors.error : AppColors.divider),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Add a comment…',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: (_controller.text.trim().isEmpty || overLimit) ? null : _submit,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: (_controller.text.trim().isEmpty || overLimit) ? null : AppColors.primaryGradient,
                            color: (_controller.text.trim().isEmpty || overLimit) ? AppColors.surface : null,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_upward_rounded,
                              size: 19, color: (_controller.text.trim().isEmpty || overLimit) ? AppColors.textMuted : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                if (overLimit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${_controller.text.length}/$kMaxCommentLength — too long',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.error)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
