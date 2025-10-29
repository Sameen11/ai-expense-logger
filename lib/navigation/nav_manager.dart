import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Defines the types of modern transitions available.
enum TransitionType {
  /// Standard platform-specific transition (Material on Android, Cupertino on iOS).
  platform,

  /// Fades the new screen in.
  fade,

  /// Slides the new screen in from the right.
  slideFromRight,

  /// Slides the new screen in from the bottom.
  slideFromBottom,

  /// Scales the new screen in from the center.
  scale,

  /// A modal transition that blurs the background.
  /// The new screen should be semi-transparent or smaller than the full screen.
  blurModal,
}

/// A utility class for handling modern page transitions.
///
/// This manager simplifies the use of [PageRouteBuilder] for common
/// and visually appealing navigation effects like fades, slides, and blur modals.
class NavigationManager {
  // --- Public API ---

  /// Pushes a new page onto the navigation stack with a specified transition.
  ///
  /// [context]: The BuildContext from which to navigate.
  /// [page]: The widget (screen) to navigate to.
  /// [type]: The [TransitionType] to use. Defaults to [TransitionType.platform].
  /// [duration]: The transition duration. Defaults to 300ms.
  /// [fullscreenDialog]: Whether the new page is a fullscreen dialog.
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.platform,
    Duration duration = const Duration(milliseconds: 300),
    bool fullscreenDialog = false,
  }) {
    final route = _createRoute<T>(
      page,
      type: type,
      duration: duration,
      fullscreenDialog: fullscreenDialog,
    );
    return Navigator.of(context).push<T>(route);
  }

  /// Replaces the current page with a new one using a specified transition.
  ///
  /// [context]: The BuildContext from which to navigate.
  /// [page]: The widget (screen) to navigate to.
  /// [type]: The [TransitionType] to use. Defaults to [TransitionType.platform].
  /// [duration]: The transition duration. Defaults to 300ms.
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.platform,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final route = _createRoute<T>(
      page,
      type: type,
      duration: duration,
      fullscreenDialog: false, // pushReplacement doesn't typically use this
    );
    return Navigator.of(context).pushReplacement<T, TO>(route);
  }

  /// Pops the top-most route off the navigator.
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  // --- Internal Route Creation ---

  /// Creates a [PageRoute] based on the [TransitionType].
  static PageRoute<T> _createRoute<T extends Object?>(
    Widget page, {
    required TransitionType type,
    required Duration duration,
    required bool fullscreenDialog,
  }) {
    // For blur modal, we need a special non-opaque route.
    if (type == TransitionType.blurModal) {
      return _BlurModalRoute<T>(
        page: page,
        duration: duration,
        fullscreenDialog: fullscreenDialog,
      );
    }

    // For platform-specific transitions
    if (type == TransitionType.platform) {
      if (Platform.isIOS) {
        return CupertinoPageRoute<T>(
          builder: (_) => page,
          fullscreenDialog: fullscreenDialog,
        );
      }
      // Default to Material on Android and other platforms
      return MaterialPageRoute<T>(
        builder: (_) => page,
        fullscreenDialog: fullscreenDialog,
      );
    }

    // For all other custom transitions, use PageRouteBuilder
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case TransitionType.fade:
            return FadeTransition(opacity: animation, child: child);

          case TransitionType.slideFromRight:
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );

          case TransitionType.slideFromBottom:
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );

          case TransitionType.scale:
            return ScaleTransition(
              scale: animation.drive(
                Tween(
                  begin: 0.8,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );

          case TransitionType.platform:
          case TransitionType.blurModal:
          default:
            // These are handled above, but we return a simple fade as a fallback.
            return FadeTransition(opacity: animation, child: child);
        }
      },
    );
  }
}

/// A custom route for the blur modal effect.
class _BlurModalRoute<T> extends PageRoute<T> {
  final Widget page;
  final Duration duration;

  _BlurModalRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    bool fullscreenDialog = false,
  }) : super(fullscreenDialog: fullscreenDialog);

  @override
  Color? get barrierColor => Colors.black.withOpacity(0.3);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get opaque => false; // THIS IS KEY: The route is not opaque

  // --- FIX 1: Added maintainState getter ---
  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    // --- FIX 2: Corrected parameter type ---
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This wrapper is what the user passes in as [page].
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The child is the [page] from buildPage.

    // 1. Animate the blur
    final blurAnimation = Tween(
      begin: 0.0,
      end: 5.0,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

    // 2. Animate the child (e.g., slide from bottom)
    final slideAnimation = Tween(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: blurAnimation.value,
        sigmaY: blurAnimation.value,
      ),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slideAnimation, child: child),
      ),
    );
  }
}
