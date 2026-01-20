import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';

/// Loading state widget
///
/// Displays a centered circular progress indicator with standard sizing
class LoadingState extends StatelessWidget {
  /// Optional custom size for the indicator (default 16x16)
  final double size;

  /// Optional custom message to display below the loader
  final String? message;

  const LoadingState({
    super.key,
    this.size = 16,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(MacOSTheme.systemBlue),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption1,
                  color: MacOSTheme.of(context).textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget
///
/// Displays an error icon, message, and optional retry button
class ErrorState extends StatelessWidget {
  /// The error message to display
  final String error;

  /// Optional callback when retry is tapped
  final VoidCallback? onRetry;

  /// Icon to display (default: error_outline)
  final IconData? icon;

  const ErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 20,
              color: MacOSTheme.errorRed,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption1,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  '重试',
                  style: const TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption1,
                    color: MacOSTheme.systemBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
///
/// Displays an empty state icon, message, and optional action button
class EmptyState extends StatelessWidget {
  /// The message to display
  final String message;

  /// Optional callback when action is tapped
  final VoidCallback? onAction;

  /// Label for the action button (default: "添加")
  final String actionLabel;

  /// Icon to display (default: folder_off_outlined)
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.message,
    this.onAction,
    this.actionLabel = '添加',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.folder_off_outlined,
              size: 24,
              color: colors.iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption1,
                color: colors.textSecondary,
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption1,
                    color: MacOSTheme.systemBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error state for horizontal layouts
///
/// A compact horizontal error display with retry button,
/// useful for banners and inline messages
class InlineErrorState extends StatelessWidget {
  /// The error message to display
  final String error;

  /// Callback when retry is tapped
  final VoidCallback onRetry;

  const InlineErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MacOSTheme.paddingM),
      decoration: BoxDecoration(
        color: MacOSTheme.errorRed.withOpacity(0.08),
        borderRadius: const BorderRadius.all(
          Radius.circular(MacOSTheme.radiusSmall),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: MacOSTheme.errorRed,
          ),
          const SizedBox(width: MacOSTheme.paddingM),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: MacOSTheme.fontSizeFootnote,
                color: MacOSTheme.errorRed,
              ),
            ),
          ),
          _RetryButton(onRetry: onRetry),
        ],
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: '重试',
        child: GestureDetector(
          onTap: widget.onRetry,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _isHovering ? MacOSTheme.systemGray6 : null,
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
            ),
            child: const Icon(
              Icons.refresh_outlined,
              size: 16,
              color: MacOSTheme.errorRed,
            ),
          ),
        ),
      ),
    );
  }
}
