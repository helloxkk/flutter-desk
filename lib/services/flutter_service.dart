import 'dart:io';
import 'dart:convert';
import 'package:flutter_desk/models/command_state.dart';
import 'package:flutter_desk/models/flutter_project.dart';
import 'package:flutter_desk/models/flutter_device.dart';
import 'package:flutter_desk/models/build_config.dart';
import 'package:flutter_desk/utils/constants.dart';

/// Flutter 命令执行服务
class FlutterService {
  Process? _process;
  /// 用于长时间运行的命令（如 build, watch）
  Process? _longRunningProcess;
  final List<void Function()> _statusListeners = [];
  final List<void Function(String)> _outputListeners = [];
  final List<void Function(String)> _errorListeners = [];

  CommandState _state = CommandState();

  /// 当前状态
  CommandState get state => _state;

  /// 是否正在运行
  bool get isRunning => _state.isRunning;

  /// 添加状态监听器
  void addStatusListener(void Function() listener) {
    _statusListeners.add(listener);
  }

  /// 移除状态监听器
  void removeStatusListener(void Function() listener) {
    _statusListeners.remove(listener);
  }

  /// 添加输出监听器
  void addOutputListener(void Function(String) listener) {
    _outputListeners.add(listener);
  }

  /// 移除输出监听器
  void removeOutputListener(void Function(String) listener) {
    _outputListeners.remove(listener);
  }

  /// 添加错误监听器
  void addErrorListener(void Function(String) listener) {
    _errorListeners.add(listener);
  }

  /// 移除错误监听器
  void removeErrorListener(void Function(String) listener) {
    _errorListeners.remove(listener);
  }

  /// 更新状态
  void _updateState(CommandState newState) {
    _state = newState;
    for (final listener in _statusListeners) {
      listener();
    }
  }

  /// 运行 Flutter 项目
  Future<void> run(
    FlutterProject project,
    FlutterDevice device,
  ) async {
    if (_process != null) {
      throw StateError('Flutter 进程已在运行中');
    }

    // 验证项目路径
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

  /// 处理输出
  void _handleOutput(String data) {
    final lines = data.split('\n').where((line) => line.isNotEmpty);
    for (final line in lines) {
      _updateState(_state.addLog(line));
      for (final listener in _outputListeners) {
        listener(line);
      }
    }
  }

  /// 处理错误
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

  /// Flutter clean - 清理构建产物
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
  void dispose() {
    stop();
    _statusListeners.clear();
    _outputListeners.clear();
    _errorListeners.clear();
  }

  /// 构建项目（使用流式输出）
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
  /// watch 命令会持续运行，需要手动调用 stopLongRunningProcess() 停止
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
