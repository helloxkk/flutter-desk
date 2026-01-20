import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';

/// Compact icon button for toolbar use
///
/// A small, hoverable button with an icon, typically used in toolbars.
/// Features:
/// - Hover effect with background color change
/// - Disabled state with reduced opacity
/// - Optional custom color or destructive (red) styling
/// - Tooltip support
class CompactIconButton extends StatefulWidget {
  /// The icon to display
  final IconData icon;

  /// Tooltip text shown on long press
  final String tooltip;

  /// Whether the button is enabled
  final bool isEnabled;

  /// Whether this is a destructive action (shows red color)
  final bool isDestructive;

  /// Optional custom color for the icon
  final Color? color;

  /// Callback when button is tapped
  final VoidCallback onPressed;

  /// Button size (default 28x28)
  final double size;

  const CompactIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isEnabled = true,
    this.isDestructive = false,
    this.color,
    this.size = 28,
  });

  @override
  State<CompactIconButton> createState() => _CompactIconButtonState();
}

class _CompactIconButtonState extends State<CompactIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    // Determine icon color
    Color iconColor;
    if (widget.color != null) {
      iconColor = widget.color!;
    } else if (widget.isDestructive) {
      iconColor = MacOSTheme.errorRed;
    } else {
      iconColor = colors.textSecondary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onPressed : null,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _isHovering && widget.isEnabled
                    ? colors.hoverColor
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
