import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_desk/models/flutter_project.dart';
import 'package:flutter_desk/models/flutter_device.dart';
import 'package:flutter_desk/utils/constants.dart';

/// 配置存储服务
class StorageService {
  static StorageService? _instance;
  static const String _keyProjects = 'projects';
  static const String _keyLastProject = 'last_project_path';
  static const String _keyLastDevice = 'last_device_id';

  StorageService._();

  /// 获取单例实例
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// 保存项目列表
  Future<void> saveProjects(List<FlutterProject> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = projects.map((p) => p.toJson()).toList();
      await prefs.setString(_keyProjects, jsonEncode(jsonList));
    } catch (e) {
      throw Exception('保存项目列表失败: $e');
    }
  }

  /// 加载项目列表
  Future<List<FlutterProject>> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyProjects);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((item) => FlutterProject.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 如果加载失败，返回默认项目列表
      return _getDefaultProjects();
    }
  }

  /// 保存最后选择的项目
  Future<void> saveLastProject(FlutterProject project) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastProject, project.path);
    } catch (e) {
      throw Exception('保存最后项目失败: $e');
    }
  }

  /// 加载最后选择的项目
  Future<String?> loadLastProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastProject);
    } catch (e) {
      return null;
    }
  }

  /// 保存最后选择的设备
  Future<void> saveLastDevice(FlutterDevice device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastDevice, device.id);
    } catch (e) {
      throw Exception('保存最后设备失败: $e');
    }
  }

  /// 加载最后选择的设备
  Future<String?> loadLastDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastDevice);
    } catch (e) {
      return null;
    }
  }

  /// 清除所有保存的数据
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyProjects);
      await prefs.remove(_keyLastProject);
      await prefs.remove(_keyLastDevice);
    } catch (e) {
      throw Exception('清除数据失败: $e');
    }
  }

  /// 验证项目路径是否有效
  Future<bool> isValidProjectPath(String path) async {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        return false;
      }

      // 检查是否存在 Flutter 项目标记文件
      final pubspecFile = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
      return pubspecFile.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// 从项目路径读取项目名称
  Future<String> getProjectName(String path) async {
    try {
      final pubspecFile = File('$path${Platform.pathSeparator}pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        return AppConstants.defaultProjectName;
      }

      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('name:')) {
          final name = trimmed.substring(5).trim();
          // 移除可能的引号
          if ((name.startsWith('"') && name.endsWith('"')) ||
              (name.startsWith("'") && name.endsWith("'"))) {
            return name.substring(1, name.length - 1);
          }
          return name.split(' ')[0].trim();
        }
      }

      return AppConstants.defaultProjectName;
    } catch (e) {
      return AppConstants.defaultProjectName;
    }
  }

  /// 获取默认项目列表
  Future<List<FlutterProject>> _getDefaultProjects() async {
    final defaultPaths = [
      '/Users/kun/CursorProjects/links2-control-mobile',
      '/Users/kun/CursorProjects/links2-control-panel',
      '/Users/kun/CursorProjects/links2-power-mobile',
    ];

    final projects = <FlutterProject>[];

    for (final path in defaultPaths) {
      if (await isValidProjectPath(path)) {
        final name = await getProjectName(path);
        projects.add(FlutterProject(
          name: name,
          path: path,
        ));
      }
    }

    return projects;
  }

  /// 获取应用文档目录
  Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// 获取应用支持目录
  Future<Directory> getAppSupportDirectory() async {
    return await getApplicationSupportDirectory();
  }
}
