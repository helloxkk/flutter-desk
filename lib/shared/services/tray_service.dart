import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_desk/shared/models/command_state.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';
import 'package:flutter_desk/shared/models/flutter_device.dart';

/// 系统托盘服务
///
/// Flutter 层与 macOS Swift 原生层之间的通信桥梁。
/// 负责处理系统托盘菜单的交互，并同步应用状态到托盘。
class TrayService {
  /// MethodChannel 用于与 Swift 原生代码通信
  static const MethodChannel _methodChannel = MethodChannel(
    'com.drivensmart.flutter-manager/tray',
  );

  // ==================== 回调函数 ====================
  // 这些函数由主应用设置，当用户在托盘菜单中执行操作时被调用

  /// 用户点击"运行项目"菜单项时的回调
  Function()? onRunProject;

  /// 用户点击"热重载"菜单项时的回调
  Function()? onHotReload;

  /// 用户点击"热重启"菜单项时的回调
  Function()? onHotRestart;

  /// 用户点击"停止项目"菜单项时的回调
  Function()? onStopProject;

  /// 用户点击"显示主窗口"菜单项时的回调
  Function()? onShowMainWindow;

  // ==================== 公共方法 ====================

  /// 初始化托盘服务
  ///
  /// 设置 MethodChannel 的方法调用处理器，
  /// 用于接收来自 Swift 层的托盘菜单操作。
  Future<void> initialize() async {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// 更新托盘状态
  ///
  /// 将当前的运行状态、项目信息和设备信息发送到 Swift 层，
  /// 用于更新托盘菜单的显示内容。
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
      debugPrint('[TrayService] Failed to update tray state: $e');
    }
  }

  /// 显示主窗口
  ///
  /// 通知 Swift 层显示应用主窗口。
  Future<void> showMainWindow() async {
    try {
      await _methodChannel.invokeMethod('showMainWindow');
    } catch (e) {
      debugPrint('[TrayService] Failed to show main window: $e');
    }
  }

  /// 隐藏主窗口
  ///
  /// 通知 Swift 层隐藏应用主窗口。
  Future<void> hideMainWindow() async {
    try {
      await _methodChannel.invokeMethod('hideMainWindow');
    } catch (e) {
      debugPrint('[TrayService] Failed to hide main window: $e');
    }
  }

  /// 退出应用
  ///
  /// 通知 Swift 层完全退出应用程序。
  Future<void> quitApp() async {
    try {
      await _methodChannel.invokeMethod('quitApp');
    } catch (e) {
      debugPrint('[TrayService] Failed to quit app: $e');
    }
  }

  // ==================== 私有方法 ====================

  /// 处理来自 Swift 层的方法调用
  ///
  /// 当用户在托盘菜单中执行操作时，Swift 层会调用此方法。
  /// 根据方法名称分发到对应的回调函数。
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

  /// 将 ProcessStatus 枚举转换为字符串
  ///
  /// 用于将 Dart 枚举值传递给 Swift 层。
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
