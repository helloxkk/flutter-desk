import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/shared/models/flutter_device.dart';

/// Sidebar device list item
///
/// A selectable list item displaying a Flutter device with:
/// - Device-specific icon (phone, desktop, emulator)
/// - Device name
/// - Hover and selection states
class DeviceListItem extends StatefulWidget {
  /// The device to display
  final FlutterDevice device;

  /// Whether this item is selected
  final bool isSelected;

  /// Callback when item is tapped
  final VoidCallback onTap;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<DeviceListItem> {
  bool _isHovering = false;

  Widget _buildDeviceIcon(MacOSColors colors) {
    final iconAssetPath = widget.device.iconAssetPath;

    // 使用系统图标资源
    if (iconAssetPath != null) {
      return Image.asset(
        iconAssetPath,
        width: 16,
        height: 16,
        color: widget.isSelected
            ? const Color(0xFF017AFF)
            : colors.textSecondary,
        colorBlendMode: BlendMode.srcIn,
      );
    }

    // 回退到默认图标
    return Icon(
      widget.device.iconData,
      size: 14,
      color: widget.isSelected
          ? const Color(0xFF017AFF)
          : colors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F6))
                : (_isHovering ? colors.hoverColor : null),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _buildDeviceIcon(colors),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.device.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? MacOSTheme.weightMedium
                        : MacOSTheme.weightRegular,
                    color: widget.isSelected
                        ? const Color(0xFF017AFF)
                        : colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
