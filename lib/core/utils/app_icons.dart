import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';

/// App Icons - System-style icon helper
///
/// Provides system-native looking icons using extracted macOS icons.
/// Falls back to Material Icons when asset is not available.
class AppIcons {
  AppIcons._();

  // ============== Device Icons ==============

  /// iPhone device icon
  static const String iphone = 'assets/devices/iphone.png';

  /// iPad device icon
  static const String iPad = 'assets/devices/iPad.png';

  /// Android device icon
  static const String android = 'assets/devices/android.png';

  /// Laptop/Desktop icon (macOS, Windows, Linux)
  static const String laptop = 'assets/devices/Laptop.png';

  /// iMac icon (also used for Web)
  static const String iMac = 'assets/devices/iMac.png';

  // ============== Folder Icons ==============

  /// Generic folder icon
  static const String folder = 'assets/icons/folder.png';

  /// Open folder icon
  static const String folderOpen = 'assets/icons/folder_open.png';

  /// Smart folder icon (for filters)
  static const String smartFolder = 'assets/icons/smart_folder.png';

  // ============== Action Icons ==============

  /// Delete/Trash icon
  static const String delete = 'assets/icons/delete.png';

  /// Close/Cancel icon
  static const String close = 'assets/icons/close.png';

  /// Search icon
  static const String search = 'assets/icons/search.png';

  /// Settings/Gear icon
  static const String settings = 'assets/icons/settings.png';

  /// Info icon
  static const String info = 'assets/icons/info.png';

  /// Advanced icon
  static const String advanced = 'assets/icons/advanced.png';

  /// Network icon
  static const String network = 'assets/icons/network.png';

  /// Cloud icon
  static const String cloud = 'assets/icons/cloud.png';

  /// Build icon
  static const String build = 'assets/icons/build.png';

  /// Code icon
  static const String code = 'assets/icons/code.png';

  /// Sun icon (light mode)
  static const String sun = 'assets/icons/sun.png';

  /// Moon icon (dark mode)
  static const String moon = 'assets/icons/moon.png';

  /// Empty logs icon
  static const String emptyLogs = 'assets/icons/empty_logs.png';

  /// No search results icon
  static const String noResults = 'assets/icons/no_results.png';

  /// Refresh icon
  static const String refresh = 'assets/icons/refresh.png';

  /// Add icon
  static const String add = 'assets/icons/add.png';

  // ============== Helper Methods ==============

  /// Create an Image widget for an asset icon with proper coloring
  static Image iconWidget(
    String assetPath, {
    double? size,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
  }) {
    return Image.asset(
      assetPath,
      width: size ?? 16,
      height: size ?? 16,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }

  /// Folder icon widget with theme coloring
  static Widget folderIcon(BuildContext context, {bool isSelected = false}) {
    final colors = MacOSTheme.of(context);
    return iconWidget(
      folder,
      size: 14,
      color: isSelected
          ? const Color(0xFF017AFF)
          : colors.textSecondary,
    );
  }

  /// Delete icon widget
  static Widget deleteIcon({double size = 16}) {
    return iconWidget(
      delete,
      size: size,
      color: MacOSTheme.errorRed,
    );
  }

  /// Search icon widget
  static Widget searchIcon(BuildContext context) {
    final colors = MacOSTheme.of(context);
    return iconWidget(
      search,
      size: 14,
      color: colors.iconColor,
    );
  }

  /// Close icon widget
  static Widget closeIcon({double size = 14}) {
    return iconWidget(close, size: size);
  }

  /// Settings icon widget
  static Widget settingsIcon(BuildContext context) {
    final colors = MacOSTheme.of(context);
    return iconWidget(
      settings,
      size: 16,
      color: colors.iconColor,
    );
  }

  /// Build icon widget
  static Widget buildIcon(BuildContext context) {
    final colors = MacOSTheme.of(context);
    return iconWidget(
      build,
      size: 16,
      color: colors.textSecondary,
    );
  }

  /// Code icon widget
  static Widget codeIcon(BuildContext context) {
    final colors = MacOSTheme.of(context);
    return iconWidget(
      code,
      size: 16,
      color: colors.textSecondary,
    );
  }

  /// Theme icon widget (sun/moon based on theme)
  static Widget themeIcon(BuildContext context, {bool isDark = false}) {
    final colors = MacOSTheme.of(context);
    return iconWidget(
      isDark ? sun : moon,
      size: 16,
      color: colors.iconColor,
    );
  }

  /// Refresh icon widget
  static Widget refreshIcon({double size = 14}) {
    return iconWidget(
      refresh,
      size: size,
      color: MacOSTheme.systemBlue,
    );
  }

  /// Add icon widget
  static Widget addIcon({double size = 14}) {
    return iconWidget(
      add,
      size: size,
      color: MacOSTheme.systemBlue,
    );
  }
}
