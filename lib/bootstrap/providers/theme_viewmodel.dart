import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题管理 ViewModel
///
/// 管理应用的主题模式（亮色/暗色/系统），
/// 并将用户偏好持久化到本地存储。
class ThemeViewModel extends ChangeNotifier {
  /// SharedPreferences 存储键
  static const String _themeKey = 'theme_mode';

  /// 当前主题模式（默认为暗色）
  ThemeMode _themeMode = ThemeMode.dark;

  /// 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// 是否为暗色模式
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// 初始化主题设置
  ///
  /// 从持久化存储中读取用户上次选择的主题模式。
  /// 如果没有保存的偏好，默认使用暗色模式。
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 1; // 1 = dark
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  /// 切换亮色/暗色主题
  ///
  /// 在亮色和暗色模式之间切换，并保存用户偏好。
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);

    notifyListeners();
  }

  /// 设置指定的主题模式
  ///
  /// 直接设置主题为指定值（light/dark/system），并保存用户偏好。
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);

    notifyListeners();
  }
}
