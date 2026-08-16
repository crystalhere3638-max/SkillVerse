import 'package:flutter/material.dart';

/// Smoother alternative to the platform-default push transition —
/// subtle slide-up + fade. Use in place of MaterialPageRoute wherever
/// a slightly more polished transition is worth it.
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SlideFadeRoute({required this.builder})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}
