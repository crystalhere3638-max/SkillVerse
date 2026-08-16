import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoubleTapLike extends StatefulWidget {
  final Widget child;
  final VoidCallback onLike;
  final BorderRadius? borderRadius;

  const DoubleTapLike({super.key, required this.child, required this.onLike, this.borderRadius});

  @override
  State<DoubleTapLike> createState() => _DoubleTapLikeState();
}

class _DoubleTapLikeState extends State<DoubleTapLike> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.onLike();
    setState(() => _showHeart = true);
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (_showHeart)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 84,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 16)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
