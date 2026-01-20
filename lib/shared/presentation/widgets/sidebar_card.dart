import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';

/// macOS-style sidebar card container
///
/// A rounded container with shadow and border, used for sidebar content.
/// Commonly used to group related content in a floating card style.
///
/// Example:
/// ```dart
/// SidebarCard(
///   child: Column(
///     children: [
///       Expanded(child: _ProjectsSection()),
///       Divider(),
///       Expanded(child: _DevicesSection()),
///     ],
///   ),
/// )
/// ```
class SidebarCard extends StatelessWidget {
  /// The content inside the card
  final Widget child;

  /// Width of the card (default 200)
  final double? width;

  /// Optional custom margin
  final EdgeInsetsGeometry? margin;

  /// Border radius (default 12)
  final double borderRadius;

  const SidebarCard({
    super.key,
    required this.child,
    this.width,
    this.margin,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    return Container(
      margin: margin ?? const EdgeInsets.only(left: 12, right: 12, top: 40, bottom: 12),
      width: width ?? 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        border: Border.all(
          color: isDark ? colors.border : Colors.white,
          width: 0.5,
        ),
        boxShadow: MacOSTheme.shadowCard,
      ),
      child: child,
    );
  }
}
