import 'package:flutter/foundation.dart';
import 'package:flutter_desk/shared/models/command_state.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';
import 'package:flutter_desk/shared/models/flutter_device.dart';
import 'package:flutter_desk/shared/models/build_config.dart';
import 'package:flutter_desk/features/run_control/services/flutter_service.dart';
import 'package:flutter_desk/core/utils/constants.dart';

/// 日志过滤类型
enum LogFilter {
  /// 显示全部日志
  all,

  /// 仅显示错误日志
  errors,

  /// 仅显示警告日志
  warnings,

  /// 仅显示信息日志（排除错误和警告）
  info,

  /// 仅显示 Flutter 相关日志
  flutter,
}

/// 命令执行 ViewModel
class CommandViewModel extends ChangeNotifier {
  final FlutterService _flutterService = FlutterService();

  /// 当前状态
  CommandState _state = CommandState();

  /// 日志过滤类型
  LogFilter _logFilter = LogFilter.all;

  /// 搜索关键字
  String _searchKeyword = '';

  /// 是否正在执行命令（防止重复执行）
  bool _isExecuting = false;

  /// 上次构建状态
  QuickActionStatus _lastBuildStatus = QuickActionStatus.none;

  /// 上次代码生成状态
  QuickActionStatus _lastCodeGenStatus = QuickActionStatus.none;

  /// 缓存的过滤后日志
  List<String> _cachedFilteredLogs = [];

  /// 缓存是否有效
  bool _isCacheValid = false;

  /// 当前状态
  CommandState get state => _state;

  /// 上次构建状态
  QuickActionStatus get lastBuildStatus => _lastBuildStatus;

  /// 上次代码生成状态
  QuickActionStatus get lastCodeGenStatus => _lastCodeGenStatus;

  /// 是否正在运行
  bool get isRunning => _state.isRunning;

  /// 是否可以执行操作
  bool get canOperate => _state.canOperate;

  /// 是否正在执行命令（防止重复执行）
  bool get isExecuting => _isExecuting;

  /// 进程 ID
  int? get pid => _state.pid;

  /// 原始日志列表
  List<String> get logs => List.unmodifiable(_state.logs);

  /// 更新状态并通知监听器（内部辅助方法，减少重复代码）
  void _updateState(CommandState newState) {
    _state = newState;
    _isCacheValid = false; // 状态变化时缓存失效
    notifyListeners();
  }

  /// 过滤后的日志列表（带缓存）
  List<String> get filteredLogs {
    if (_isCacheValid) {
      return List.unmodifiable(_cachedFilteredLogs);
    }

    var filtered = _state.logs;

    // 应用类型过滤
    switch (_logFilter) {
      case LogFilter.errors:
        // 使用正则表达式进行更精确的匹配，避免误报
        final errorPattern = RegExp(
          r'\b(error|exception|failed|fatal)\b',
          caseSensitive: false,
        );
        filtered = filtered.where((log) =>
          log.contains('[ERROR]') || errorPattern.hasMatch(log)
        ).toList();
        break;
      case LogFilter.warnings:
        final warningPattern = RegExp(
          r'\b(warning|deprecated|warn)\b',
          caseSensitive: false,
        );
        filtered = filtered.where((log) =>
          log.toLowerCase().contains('[warning]') || warningPattern.hasMatch(log)
        ).toList();
        break;
      case LogFilter.info:
        final errorPattern = RegExp(
          r'\b(error|exception|failed|warning|warn)\b',
          caseSensitive: false,
        );
        filtered = filtered.where((log) =>
          !errorPattern.hasMatch(log) && !log.contains('[ERROR]')
        ).toList();
        break;
      case LogFilter.flutter:
        filtered = filtered.where((log) =>
          log.toLowerCase().contains('flutter') ||
          log.toLowerCase().contains('hot reload') ||
          log.toLowerCase().contains('hot restart') ||
          log.toLowerCase().contains('running')
        ).toList();
        break;
      case LogFilter.all:
        break;
    }

    // 应用搜索关键字
    if (_searchKeyword.isNotEmpty) {
      final keyword = _searchKeyword.toLowerCase();
      filtered = filtered.where((log) => log.toLowerCase().contains(keyword)).toList();
    }

    _cachedFilteredLogs = filtered;
    _isCacheValid = true;

    return List.unmodifiable(filtered);
  }

  /// 过滤后的日志数量
  int get filteredLogCount => filteredLogs.length;

  /// 错误信息
  String? get error => _state.error;

  /// 当前日志过滤器
  LogFilter get logFilter => _logFilter;

  /// 搜索关键字
  String get searchKeyword => _searchKeyword;

  /// 初始化
  void initialize() {
    // 监听 Flutter 服务状态变化
    _flutterService.addStatusListener(() {
      _state = _flutterService.state;
      _isCacheValid = false; // 状态变化时缓存失效
      notifyListeners();
    });

    // 监听输出
    _flutterService.addOutputListener((line) {
      _state = _state.addLog(line);
      _isCacheValid = false; // 日志变化时缓存失效
      notifyListeners();
    });

    // 监听错误
    _flutterService.addErrorListener((line) {
      _state = _state.addLog('[ERROR] $line');
      _isCacheValid = false; // 日志变化时缓存失效
      notifyListeners();
    });
  }

  /// 设置日志过滤器
  void setLogFilter(LogFilter filter) {
    _logFilter = filter;
    _isCacheValid = false; // 过滤器变化时缓存失效
    notifyListeners();
  }

  /// 设置搜索关键字
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    _isCacheValid = false; // 搜索关键字变化时缓存失效
    notifyListeners();
  }

  /// 清除搜索和过滤
  void clearFilters() {
    _logFilter = LogFilter.all;
    _searchKeyword = '';
    _isCacheValid = false;
    notifyListeners();
  }

  /// 运行项目
  Future<void> run(
    FlutterProject project,
    FlutterDevice device,
  ) async {
    if (_isExecuting) return;

    _isExecuting = true;
    try {
      await _flutterService.run(project, device);
      _state = _flutterService.state;
      _isCacheValid = false;
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      // 不再抛出异常，由 UI 层通过检查 error 字段来显示错误
    } finally {
      _isExecuting = false;
    }
  }

  /// 热重载
  Future<void> hotReload() async {
    if (!_flutterService.isRunning) {
      _updateState(_state.copyWith(
        error: 'Flutter 进程未运行',
      ));
      return;
    }

    try {
      await _flutterService.hotReload();
      _state = _flutterService.state;
      _isCacheValid = false;
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        error: e.toString(),
      ));
    }
  }

  /// 热重启
  Future<void> hotRestart() async {
    if (!_flutterService.isRunning) {
      _updateState(_state.copyWith(
        error: 'Flutter 进程未运行',
      ));
      return;
    }

    try {
      await _flutterService.hotRestart();
      _state = _flutterService.state;
      _isCacheValid = false;
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        error: e.toString(),
      ));
    }
  }

  /// 停止运行
  Future<void> stop() async {
    try {
      await _flutterService.stop();
      _state = _flutterService.state;
      _isCacheValid = false;
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        error: e.toString(),
      ));
    }
  }

  /// 清空日志
  void clearLogs() {
    _flutterService.clearLogs();
    _updateState(_state.clearLogs());
  }

  /// 清除错误
  void clearError() {
    if (_state.error != null) {
      _updateState(_state.copyWith(error: null));
    }
  }

  /// Flutter clean - 清理构建产物
  Future<void> cleanProject(String projectPath) async {
    try {
      final output = await _flutterService.cleanProject(projectPath);
      _state = _flutterService.state;
      _isCacheValid = false;
      // 将命令输出添加到日志
      final lines = output.split('\n').where((line) => line.isNotEmpty);
      for (final line in lines) {
        _state = _state.addLog(line);
      }
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Flutter pub get - 获取依赖
  Future<void> getDependencies(String projectPath) async {
    try {
      final output = await _flutterService.getDependencies(projectPath);
      _state = _flutterService.state;
      _isCacheValid = false;
      final lines = output.split('\n').where((line) => line.isNotEmpty);
      for (final line in lines) {
        _state = _state.addLog(line);
      }
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Flutter pub upgrade - 升级依赖
  Future<void> upgradeDependencies(String projectPath) async {
    try {
      final output = await _flutterService.upgradeDependencies(projectPath);
      _state = _flutterService.state;
      _isCacheValid = false;
      final lines = output.split('\n').where((line) => line.isNotEmpty);
      for (final line in lines) {
        _state = _state.addLog(line);
      }
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Flutter pub outdated - 检查过期依赖
  Future<void> pubOutdated(String projectPath) async {
    try {
      final output = await _flutterService.pubOutdated(projectPath);
      _state = _flutterService.state;
      _isCacheValid = false;
      final lines = output.split('\n').where((line) => line.isNotEmpty);
      for (final line in lines) {
        _state = _state.addLog(line);
      }
      notifyListeners();
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// 构建项目（流式输出）
  Future<void> build(
    String projectPath,
    BuildConfig config,
  ) async {
    if (_isExecuting) return;

    _isExecuting = true;
    try {
      await _flutterService.build(projectPath, config);
      _lastBuildStatus = QuickActionStatus.success;
      // 状态和日志会通过监听器自动更新
      notifyListeners();
    } catch (e) {
      _lastBuildStatus = QuickActionStatus.failure;
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow; // 重新抛出异常，让调用者知道构建失败
    } finally {
      _isExecuting = false;
    }
  }

  /// 运行 build_runner（流式输出，watch 命令会持续运行）
  Future<void> runBuildRunner(
    String projectPath, {
    required BuildRunnerCommand command,
    bool deleteConflictingOutputs = true,
  }) async {
    if (_isExecuting) return;

    _isExecuting = true;
    try {
      await _flutterService.runBuildRunner(
        projectPath,
        command: command,
        deleteConflictingOutputs: deleteConflictingOutputs,
      );
      _lastCodeGenStatus = QuickActionStatus.success;
      // 状态和日志会通过监听器自动更新
      notifyListeners();
    } catch (e) {
      _lastCodeGenStatus = QuickActionStatus.failure;
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    } finally {
      _isExecuting = false;
    }
  }

  /// 停止长时间运行的进程（如 build 或 watch）
  Future<void> stopLongRunningProcess() async {
    try {
      await _flutterService.stopLongRunningProcess();
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// 在 Finder 中打开构建产物目录
  Future<void> openBuildOutput(String projectPath, BuildConfig config) async {
    try {
      await _flutterService.openBuildOutput(projectPath, config);
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
    }
  }

  @override
  void dispose() {
    _flutterService.dispose();
    super.dispose();
  }
}
