import 'package:flutter/material.dart';
import 'package:flutter_desk/shared/services/storage_service.dart';

/// ViewModel for managing sidebar state
///
/// Handles sidebar width with persistent storage and drag-to-resize functionality.
class SidebarViewModel extends ChangeNotifier {
  /// Current sidebar width in logical pixels
  double _width;

  /// Minimum allowed width (default 160)
  static const double minWidth = 160;

  /// Maximum allowed width (default 320)
  static const double maxWidth = 320;

  /// Default width (default 200)
  static const double defaultWidth = 200;

  /// Storage key for width persistence
  static const String _widthKey = 'sidebar_width';

  SidebarViewModel() : _width = defaultWidth {
    _loadWidth();
  }

  /// Current sidebar width
  double get width => _width;

  /// Update the sidebar width
  ///
  /// Clamps the value between [minWidth] and [maxWidth].
  void setWidth(double newWidth) {
    final clampedWidth = newWidth.clamp(minWidth, maxWidth);
    if (_width != clampedWidth) {
      _width = clampedWidth;
      _saveWidth();
      notifyListeners();
    }
  }

  /// Load the saved width from storage
  Future<void> _loadWidth() async {
    try {
      final savedWidth = await StorageService.instance.getDouble(_widthKey);
      if (savedWidth != null) {
        _width = savedWidth.clamp(minWidth, maxWidth);
        notifyListeners();
      }
    } catch (e) {
      // Use default width if loading fails
      _width = defaultWidth;
    }
  }

  /// Save the current width to storage
  Future<void> _saveWidth() async {
    try {
      await StorageService.instance.setDouble(_widthKey, _width);
    } catch (e) {
      // Silently fail if saving fails
    }
  }

  /// Reset to default width
  void resetToDefault() {
    setWidth(defaultWidth);
  }
}
