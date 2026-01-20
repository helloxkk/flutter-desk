import 'dart:io';
import 'dart:convert';

import 'package:flutter_desk/core/utils/constants.dart';
import 'package:flutter_desk/shared/models/build_config.dart';
import 'package:flutter_desk/shared/models/command_state.dart';
import 'package:flutter_desk/shared/models/flutter_device.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';

/// Flutter 命令执行服务
///
/// 负责执行各种 Flutter 命令（run、build、clean、pub get 等），
/// 管理子进程的生命周期，并提供实时输出流。
class FlutterService {
  /// 主 Flutter 运行进程（flutter run）
  Process? _process;

  /// 长时间运行的进程（如 build、watch）
  Process? _longRunningProcess;

  /// 状态变化监听器列表
  final List<void Function()> _statusListeners = [];

  /// 标准输出监听器列表
  final List<void Function(String)> _outputListeners = [];

  /// 错误输出监听器列表
  final List<void Function(String)> _errorListeners = [];

  /// 当前命令执行状态
  CommandState _state = CommandState();

  // ==================== 状态和监听器 ====================

  /// 获取当前状态
  CommandState get state => _state;

  /// 是否有正在运行的进程
  bool get isRunning => _state.isRunning;

  /// 添加状态变化监听器
  void addStatusListener(void Function() listener) {
    _statusListeners.add(listener);
  }

  /// 移除状态监听器
  void removeStatusListener(void Function() listener) {
    _statusListeners.remove(listener);
  }

  /// 添加标准输出监听器
  void addOutputListener(void Function(String) listener) {
    _outputListeners.add(listener);
  }

  /// 移除输出监听器
  void removeOutputListener(void Function(String) listener) {
    _outputListeners.remove(listener);
  }

  /// 添加错误输出监听器
  void addErrorListener(void Function(String) listener) {
    _errorListeners.add(listener);
  }

  /// 移除错误监听器
  void removeErrorListener(void Function(String) listener) {
    _errorListeners.remove(listener);
  }

  // ==================== 私有辅助方法 ====================

  /// 更新状态并通知所有监听器
  void _updateState(CommandState newState) {
    _state = newState;
    for (final listener in _statusListeners) {
      listener();
    }
  }

  // ==================== 主要命令 ====================

  /// 运行 Flutter 项目
  ///
  /// 启动 `flutter run` 进程，监听其输出并管理其生命周期。
  /// 进程启动后，可以通过 stdin 发送命令进行热重载/热重启。
  Future<void> run(
    FlutterProject project,
    FlutterDevice device,
  ) async {
    if (_process != null) {
      throw StateError('Flutter 进程已在运行中');
    }

    // 验证项目路径是否存在
    final projectDir = Directory(project.path);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', project.path);
    }

    // 更新状态为启动中
    _updateState(_state.copyWith(
      status: ProcessStatus.starting,
      projectId: project.path,
      deviceId: device.id,
      error: null,
    ));

    try {
      // 启动 flutter run 进程
      _process = await Process.start(
        'flutter',
        ['run', '-d', device.id],
        workingDirectory: project.path,
        mode: ProcessStartMode.normal,
        environment: {
          'CLI_TOOL': 'links2-flutter-manager',
        },
      );

      // 获取进程 ID
      final pid = _process!.pid;

      // 监听标准输出
      _process!.stdout.transform(utf8.decoder).listen((data) {
        _handleOutput(data);
      });

      // 监听标准错误
      _process!.stderr.transform(utf8.decoder).listen((data) {
        _handleError(data);
      });

      // 监听进程退出
      _process!.exitCode.then((exitCode) {
        _handleExit(exitCode);
      });

      // 更新状态为运行中
      _updateState(_state.copyWith(
        status: ProcessStatus.running,
        pid: pid,
      ));
    } catch (e) {
      // 启动失败
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      _process = null;
      rethrow;
    }
  }

  /// 热重载
  ///
  /// 向运行中的 Flutter 进程发送 'r' 命令，
  /// 触发热重载以应用代码更改而不重启应用。
  Future<void> hotReload() async {
    if (_process == null) {
      throw StateError('Flutter 进程未运行');
    }

    _updateState(_state.copyWith(status: ProcessStatus.hotReloading));

    try {
      _process!.stdin.writeln(AppConstants.hotReloadCommand);
      await Future.delayed(const Duration(milliseconds: 500));
      _updateState(_state.copyWith(status: ProcessStatus.running));
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 热重启
  ///
  /// 向运行中的 Flutter 进程发送 'R' 命令，
  /// 触发完全重启以应用所有更改（包括需要重启的更改）。
  Future<void> hotRestart() async {
    if (_process == null) {
      throw StateError('Flutter 进程未运行');
    }

    _updateState(_state.copyWith(status: ProcessStatus.hotRestarting));

    try {
      _process!.stdin.writeln(AppConstants.hotRestartCommand);
      await Future.delayed(const Duration(milliseconds: 1000));
      _updateState(_state.copyWith(status: ProcessStatus.running));
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 停止运行
  ///
  /// 向运行中的 Flutter 进程发送 'q' 命令以优雅退出。
  /// 如果进程在 5 秒内未退出，将强制终止。
  Future<void> stop() async {
    if (_process == null) {
      return;
    }

    _updateState(_state.copyWith(status: ProcessStatus.stopping));

    try {
      // 发送 'q' 命令优雅退出
      _process!.stdin.writeln(AppConstants.stopCommand);

      // 等待进程退出（最多 5 秒）
      await _process!.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // 超时则强制杀死进程
          _process?.kill(ProcessSignal.sigterm);
          return -1;
        },
      );

      _process = null;
      _updateState(_state.copyWith(
        status: ProcessStatus.stopped,
        pid: null,
      ));
    } catch (e) {
      // 强制杀死进程
      _process?.kill(ProcessSignal.sigkill);
      _process = null;
      _updateState(_state.copyWith(
        status: ProcessStatus.stopped,
        pid: null,
      ));
    }
  }

  // ==================== 输出处理 ====================

  /// 处理标准输出
  ///
  /// 解析进程输出，逐行添加到日志，并通知所有输出监听器。
  void _handleOutput(String data) {
    final lines = data.split('\n').where((line) => line.isNotEmpty);
    for (final line in lines) {
      _updateState(_state.addLog(line));
      for (final listener in _outputListeners) {
        listener(line);
      }
    }
  }

  /// 处理错误输出
  ///
  /// 解析错误输出，添加 [ERROR] 前缀，并通知所有错误监听器。
  void _handleError(String data) {
    final lines = data.split('\n').where((line) => line.isNotEmpty);
    for (final line in lines) {
      _updateState(_state.addLog('[ERROR] $line'));
      for (final listener in _errorListeners) {
        listener(line);
      }
    }
  }

  /// 处理进程退出
  ///
  /// 根据退出码更新状态：
  /// - 0: 正常停止
  /// - 非 0: 异常退出，记录错误
  void _handleExit(int exitCode) {
    _process = null;
    if (exitCode == 0) {
      _updateState(_state.copyWith(
        status: ProcessStatus.stopped,
        pid: null,
      ));
    } else {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        pid: null,
        error: '进程异常退出，退出码: $exitCode',
      ));
    }
  }

  /// 清空日志
  void clearLogs() {
    _updateState(_state.clearLogs());
  }

  // ==================== 工具命令 ====================

  /// Flutter clean - 清理构建产物
  ///
  /// 删除项目的 build 目录和生成的文件。
  Future<String> cleanProject(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', projectPath);
    }

    _updateState(_state.copyWith(status: ProcessStatus.starting));

    try {
      final result = await Process.run(
        'flutter',
        ['clean'],
        workingDirectory: projectPath,
        environment: {'CLI_TOOL': 'links2-flutter-manager'},
      );

      final output = result.stdout as String;
      if (result.exitCode != 0) {
        final error = result.stderr as String;
        throw Exception('Flutter clean 失败: $error');
      }

      _updateState(_state.copyWith(status: ProcessStatus.idle));
      return output;
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Flutter pub get - 获取依赖
  ///
  /// 下载 pubspec.yaml 中指定的所有依赖包。
  Future<String> getDependencies(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', projectPath);
    }

    _updateState(_state.copyWith(status: ProcessStatus.starting));

    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: projectPath,
        environment: {'CLI_TOOL': 'links2-flutter-manager'},
      );

      final output = result.stdout as String;
      if (result.exitCode != 0) {
        final error = result.stderr as String;
        throw Exception('Flutter pub get 失败: $error');
      }

      _updateState(_state.copyWith(status: ProcessStatus.idle));
      return output;
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Flutter pub upgrade - 升级依赖
  ///
  /// 将所有依赖包升级到与其版本约束兼容的最新版本。
  Future<String> upgradeDependencies(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', projectPath);
    }

    _updateState(_state.copyWith(status: ProcessStatus.starting));

    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'upgrade'],
        workingDirectory: projectPath,
        environment: {'CLI_TOOL': 'links2-flutter-manager'},
      );

      final output = result.stdout as String;
      if (result.exitCode != 0) {
        final error = result.stderr as String;
        throw Exception('Flutter pub upgrade 失败: $error');
      }

      _updateState(_state.copyWith(status: ProcessStatus.idle));
      return output;
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Flutter pub outdated - 检查过期依赖
  ///
  /// 分析所有依赖包，显示可升级的包及其最新版本。
  Future<String> pubOutdated(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', projectPath);
    }

    _updateState(_state.copyWith(status: ProcessStatus.starting));

    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'outdated'],
        workingDirectory: projectPath,
        environment: {'CLI_TOOL': 'links2-flutter-manager'},
      );

      final output = result.stdout as String;
      // pub outdated 返回非零退出码时也可能有有效输出
      _updateState(_state.copyWith(status: ProcessStatus.idle));
      return output;
    } catch (e) {
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 释放资源
  ///
  /// 停止所有进程，清空所有监听器。
  void dispose() {
    stop();
    _statusListeners.clear();
    _outputListeners.clear();
    _errorListeners.clear();
  }

  // ==================== 构建相关 ====================

  /// 构建项目（使用流式输出）
  ///
  /// 执行 Flutter 构建命令（如 apk、ipa、macos 等），
  /// 使用流式输出实时显示构建进度。
  Future<void> build(
    String projectPath,
    BuildConfig config,
  ) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', projectPath);
    }

    // 如果有其他进程在运行，先停止
    if (_longRunningProcess != null) {
      await stopLongRunningProcess();
    }

    _updateState(_state.copyWith(status: ProcessStatus.building));

    try {
      final command = config.buildCommand;

      // 使用 Process.start 实现流式输出
      _longRunningProcess = await Process.start(
        'flutter',
        command,
        workingDirectory: projectPath,
        mode: ProcessStartMode.normal,
        environment: {'CLI_TOOL': 'links2-flutter-manager'},
      );

      // 监听标准输出
      _longRunningProcess!.stdout.transform(utf8.decoder).listen((data) {
        _handleOutput(data);
      });

      // 监听标准错误
      _longRunningProcess!.stderr.transform(utf8.decoder).listen((data) {
        _handleError(data);
      });

      // 监听进程退出
      _longRunningProcess!.exitCode.then((exitCode) {
        _longRunningProcess = null;
        if (exitCode == 0) {
          _updateState(_state.copyWith(status: ProcessStatus.idle));
        } else {
          _updateState(_state.copyWith(
            status: ProcessStatus.error,
            error: '构建失败，退出码: $exitCode',
          ));
        }
      });
    } catch (e) {
      _longRunningProcess = null;
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 停止长时间运行的进程
  ///
  /// 强制终止 build 或 watch 等长时间运行的进程。
  /// 先尝试 SIGTERM，2 秒后如果仍在运行则使用 SIGKILL。
  Future<void> stopLongRunningProcess() async {
    if (_longRunningProcess == null) return;

    try {
      _longRunningProcess!.kill(ProcessSignal.sigterm);
      await Future.delayed(const Duration(seconds: 2));
      if (_longRunningProcess != null) {
        _longRunningProcess!.kill(ProcessSignal.sigkill);
      }
    } catch (e) {
      _longRunningProcess?.kill(ProcessSignal.sigkill);
    } finally {
      _longRunningProcess = null;
    }
  }

  /// 运行 build_runner 命令
  ///
  /// 执行 build_runner 的 build、clean 或 watch 命令。
  /// watch 命令会持续运行，需要手动调用 stopLongRunningProcess() 停止。
  Future<void> runBuildRunner(
    String projectPath, {
    required BuildRunnerCommand command,
    bool deleteConflictingOutputs = false,
  }) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw FileSystemException('项目目录不存在', projectPath);
    }

    // 如果有其他进程在运行，先停止
    if (_longRunningProcess != null) {
      await stopLongRunningProcess();
    }

    _updateState(_state.copyWith(status: ProcessStatus.building));

    try {
      final args = <String>['pub', 'run', 'build_runner'];

      // 添加子命令
      switch (command) {
        case BuildRunnerCommand.build:
          args.add('build');
          break;
        case BuildRunnerCommand.clean:
          args.add('clean');
          break;
        case BuildRunnerCommand.watch:
          args.add('watch');
          break;
      }

      // 添加 delete-conflicting-outputs 参数
      if (deleteConflictingOutputs) {
        args.add('--delete-conflicting-outputs');
      }

      // watch 命令使用 Process.start，其他命令使用 Process.run
      if (command == BuildRunnerCommand.watch) {
        _longRunningProcess = await Process.start(
          'flutter',
          args,
          workingDirectory: projectPath,
          mode: ProcessStartMode.normal,
          environment: {'CLI_TOOL': 'links2-flutter-manager'},
        );

        // 监听标准输出
        _longRunningProcess!.stdout.transform(utf8.decoder).listen((data) {
          _handleOutput(data);
        });

        // 监听标准错误
        _longRunningProcess!.stderr.transform(utf8.decoder).listen((data) {
          _handleError(data);
        });

        // 监听进程退出
        _longRunningProcess!.exitCode.then((exitCode) {
          _longRunningProcess = null;
          if (exitCode == 0) {
            _updateState(_state.copyWith(status: ProcessStatus.idle));
          } else {
            _updateState(_state.copyWith(
              status: ProcessStatus.error,
              error: 'build_runner watch 退出，退出码: $exitCode',
            ));
          }
        });
      } else {
        // build 和 clean 命令使用流式输出
        _longRunningProcess = await Process.start(
          'flutter',
          args,
          workingDirectory: projectPath,
          mode: ProcessStartMode.normal,
          environment: {'CLI_TOOL': 'links2-flutter-manager'},
        );

        // 监听标准输出
        _longRunningProcess!.stdout.transform(utf8.decoder).listen((data) {
          _handleOutput(data);
        });

        // 监听标准错误
        _longRunningProcess!.stderr.transform(utf8.decoder).listen((data) {
          _handleError(data);
        });

        // 监听进程退出
        _longRunningProcess!.exitCode.then((exitCode) {
          _longRunningProcess = null;
          if (exitCode == 0) {
            _updateState(_state.copyWith(status: ProcessStatus.idle));
          } else {
            _updateState(_state.copyWith(
              status: ProcessStatus.error,
              error: 'build_runner 失败，退出码: $exitCode',
            ));
          }
        });
      }
    } catch (e) {
      _longRunningProcess = null;
      _updateState(_state.copyWith(
        status: ProcessStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 在 Finder 中打开构建产物目录
  ///
  /// 使用 macOS 的 open 命令在 Finder 中显示构建输出目录。
  Future<void> openBuildOutput(String projectPath, BuildConfig config) async {
    final outputDir = config.outputDirectory;
    final fullPath = '$projectPath/$outputDir';

    final dir = Directory(fullPath);
    if (!dir.existsSync()) {
      throw FileSystemException('构建输出目录不存在', fullPath);
    }

    // 使用 open 命令在 Finder 中打开目录
    await Process.run('open', [fullPath]);
  }
}
