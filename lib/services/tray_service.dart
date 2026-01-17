import 'package:flutter/services.dart';
import 'package:flutter_desk/models/command_state.dart';
import 'package:flutter_desk/models/flutter_project.dart';
import 'package:flutter_desk/models/flutter_device.dart';

/// 托盘服务 - Flutter 与 Swift 层的通信桥梁
class TrayService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.drivensmart.flutter-manager/tray',
  );

  // 命令执行回调
  Function()? onRunProject;
  Function()? onHotReload;
  Function()? onHotRestart;
  Function()? onStopProject;
  Function()? onShowMainWindow;

  /// 初始化
  Future<void> initialize() async {
    // 设置方法调用处理器
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自 Swift 的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'runProject':
        onRunProject?.call();
        return true;
      case 'hotReload':
        onHotReload?.call();
        return true;
      case 'hotRestart':
        onHotRestart?.call();
        return true;
      case 'stopProject':
        onStopProject?.call();
        return true;
      case 'showMainWindow':
        onShowMainWindow?.call();
        return true;
      default:
        return false;
    }
  }

  /// 更新状态到 Swift 层
  Future<void> updateState({
    required ProcessStatus status,
    FlutterProject? project,
    FlutterDevice? device,
    required bool isRunning,
  }) async {
    try {
      await _methodChannel.invokeMethod('updateState', {
        'status': _statusToString(status),
        'project': project?.name ?? '',
        'device': device?.name ?? '',
        'deviceIcon': device?.platformIcon ?? '',
        'isRunning': isRunning,
      });
    } catch (e) {
      print('[TrayService] Failed to update tray state: $e');
    }
  }

  /// 显示主窗口
  Future<void> showMainWindow() async {
    try {
      await _methodChannel.invokeMethod('showMainWindow');
    } catch (e) {
      print('[TrayService] Failed to show main window: $e');
    }
  }

  /// 隐藏主窗口
  Future<void> hideMainWindow() async {
    try {
      await _methodChannel.invokeMethod('hideMainWindow');
    } catch (e) {
      print('[TrayService] Failed to hide main window: $e');
    }
  }

  /// 退出应用
  Future<void> quitApp() async {
    try {
      await _methodChannel.invokeMethod('quitApp');
    } catch (e) {
      print('[TrayService] Failed to quit app: $e');
    }
  }

  /// 将 ProcessStatus 转换为字符串
  String _statusToString(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.idle:
        return 'idle';
      case ProcessStatus.starting:
        return 'starting';
      case ProcessStatus.running:
        return 'running';
      case ProcessStatus.hotReloading:
        return 'hotReloading';
      case ProcessStatus.hotRestarting:
        return 'hotRestarting';
      case ProcessStatus.building:
        return 'building';
      case ProcessStatus.stopping:
        return 'stopping';
      case ProcessStatus.stopped:
        return 'stopped';
      case ProcessStatus.error:
        return 'error';
    }
  }
}
