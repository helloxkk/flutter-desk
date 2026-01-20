import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';
import 'package:flutter_desk/shared/services/storage_service.dart';

/// 项目管理 ViewModel
class ProjectViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  /// 项目列表
  List<FlutterProject> _projects = [];

  /// 当前选中的项目
  FlutterProject? _selectedProject;

  /// 是否正在加载
  bool _isLoading = false;

  /// 错误信息
  String? _error;

  /// 项目列表
  List<FlutterProject> get projects => List.unmodifiable(_projects);

  /// 当前选中的项目
  FlutterProject? get selectedProject => _selectedProject;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get error => _error;

  /// 是否有项目
  bool get hasProjects => _projects.isNotEmpty;

  /// 初始化
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 加载项目列表
      _projects = await _storage.loadProjects();

      // 加载最后选择的项目
      final lastProjectPath = await _storage.loadLastProject();
      if (lastProjectPath != null) {
        _selectedProject = _projects.firstWhere(
          (p) => p.path == lastProjectPath,
          orElse: () => _projects.isNotEmpty ? _projects.first : FlutterProject(
            name: '默认项目',
            path: '/Users/kun/CursorProjects',
          ),
        );
      } else if (_projects.isNotEmpty) {
        _selectedProject = _projects.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 选择项目
  void selectProject(FlutterProject project) {
    if (_selectedProject?.path != project.path) {
      _selectedProject = project;
      _storage.saveLastProject(project);
      notifyListeners();
    }
  }

  /// 添加项目
  Future<bool> addProject(String path) async {
    try {
      // 验证路径
      final isValid = await _storage.isValidProjectPath(path);
      if (!isValid) {
        _error = '无效的 Flutter 项目路径';
        notifyListeners();
        return false;
      }

      // 检查是否已存在
      if (_projects.any((p) => p.path == path)) {
        _error = '项目已存在';
        notifyListeners();
        return false;
      }

      // 读取项目名称
      final name = await _storage.getProjectName(path);

      // 创建项目
      final project = FlutterProject(
        name: name,
        path: path,
      );

      _projects.add(project);
      await _storage.saveProjects(_projects);

      // 如果是第一个项目，自动选中
      if (_projects.length == 1) {
        _selectedProject = project;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 移除项目
  Future<void> removeProject(FlutterProject project) async {
    _projects.removeWhere((p) => p.path == project.path);

    // 如果移除的是当前选中的项目，选择另一个
    if (_selectedProject?.path == project.path) {
      _selectedProject = _projects.isNotEmpty ? _projects.first : null;
    }

    await _storage.saveProjects(_projects);
    notifyListeners();
  }

  /// 刷新项目列表
  Future<void> refresh() async {
    await initialize();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 在 Finder 中打开项目目录
  Future<void> openInFinder(String path) async {
    try {
      await Process.run('open', [path]);
    } catch (e) {
      _error = '无法打开 Finder: $e';
      notifyListeners();
    }
  }
}
