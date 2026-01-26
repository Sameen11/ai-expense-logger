import 'dart:ui';
import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      accentColor: const Color(0xFF34C759), // iOS Green
      icon: Icons.check,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      accentColor: const Color(0xFFFF3B30), // iOS Red
      icon: Icons.close,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      accentColor: const Color(0xFFFFCC00), // iOS Yellow
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      accentColor: const Color(0xFF0A84FF), // iOS Blue
      icon: Icons.info_outline,
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    required Color accentColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _IOSAlertBanner(
            accentColor: accentColor,
            icon: icon,
            message: message,
            duration: duration,
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration + const Duration(milliseconds: 500), entry.remove);
  }
}

class _IOSAlertBanner extends StatefulWidget {
  final Color accentColor;
  final IconData icon;
  final String message;
  final Duration duration;

  const _IOSAlertBanner({
    required this.accentColor,
    required this.icon,
    required this.message,
    required this.duration,
  });

  @override
  State<_IOSAlertBanner> createState() => _IOSAlertBannerState();
}

class _IOSAlertBannerState extends State<_IOSAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(curve: Curves.easeOutBack, parent: _controller));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                // Use card color with opacity for glass effect, simpler in dark mode
                color: theme.cardColor.withOpacity(isDark ? 0.8 : 0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: isDark
                    ? Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      )
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Accent indicator pill
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Icon bubble
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // Subtle background using accent color
                      color: widget.accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
