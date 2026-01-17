import 'dart:io';
import 'dart:convert';
import 'package:flutter_desk/models/flutter_device.dart';

/// Flutter 设备检测服务
class DeviceService {
  /// 设备列表缓存
  List<FlutterDevice> _devices = [];

  /// 当前设备列表
  List<FlutterDevice> get devices => List.unmodifiable(_devices);

  /// 最后更新时间
  DateTime? _lastUpdated;

  /// 最后更新时间
  DateTime? get lastUpdated => _lastUpdated;

  /// 是否已缓存
  bool get isCached => _devices.isNotEmpty && _lastUpdated != null;

  /// 获取可用的 Flutter 设备列表
  Future<List<FlutterDevice>> getDevices({bool forceRefresh = false}) async {
    // 如果有缓存且未强制刷新，则返回缓存
    if (isCached && !forceRefresh) {
      return _devices;
    }

    try {
      // 执行 flutter devices --machine 命令
      final result = await Process.run(
        'flutter',
        ['devices', '--machine'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        throw Exception('获取设备列表失败: ${result.stderr}');
      }

      // 解析 JSON 输出
      final jsonString = result.stdout as String;
      if (jsonString.trim().isEmpty) {
        _devices = [];
        _lastUpdated = DateTime.now();
        return _devices;
      }

      final jsonData = jsonDecode(jsonString) as List;

      // 转换为设备模型
      _devices = jsonData
          .map((item) => FlutterDevice.fromFlutterJson(item as Map<String, dynamic>))
          .where((device) => device.isAvailable)
          .toList();

      _lastUpdated = DateTime.now();
      return _devices;
    } catch (e) {
      // 如果出错且有缓存，返回缓存
      if (isCached) {
        return _devices;
      }
      rethrow;
    }
  }

  /// 根据 ID 获取设备
  FlutterDevice? getDeviceById(String id) {
    try {
      return _devices.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取第一个可用设备
  FlutterDevice? getFirstAvailableDevice() {
    if (_devices.isEmpty) {
      return null;
    }
    return _devices.firstWhere(
      (device) => device.isAvailable,
      orElse: () => _devices.first,
    );
  }

  /// 获取 macOS 桌面设备
  FlutterDevice? getMacOSDevice() {
    try {
      return _devices.firstWhere(
        (device) =>
            device.platform == DevicePlatform.macos &&
            device.type == DeviceType.desktop,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取物理设备列表
  List<FlutterDevice> getPhysicalDevices() {
    return _devices.where((device) => device.type == DeviceType.physical).toList();
  }

  /// 获取模拟器列表
  List<FlutterDevice> getEmulators() {
    return _devices.where((device) => device.type == DeviceType.emulator).toList();
  }

  /// 获取桌面平台列表
  List<FlutterDevice> getDesktopDevices() {
    return _devices.where((device) => device.type == DeviceType.desktop).toList();
  }

  /// 清空缓存
  void clearCache() {
    _devices = [];
    _lastUpdated = null;
  }

  /// 检查是否有可用设备
  bool get hasAvailableDevices {
    return _devices.any((device) => device.isAvailable);
  }

  /// 获取设备数量
  int get deviceCount => _devices.length;

  /// 获取可用设备数量
  int get availableDeviceCount =>
      _devices.where((device) => device.isAvailable).length;
}
