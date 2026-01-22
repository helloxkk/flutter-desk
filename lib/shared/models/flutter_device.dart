import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flutter_device.g.dart';

/// Flutter 设备类型
enum DeviceType {
  /// 物理设备
  physical,

  /// 模拟器
  emulator,

  /// 桌面平台
  desktop,
}

/// Flutter 设备平台
enum DevicePlatform {
  ios,
  android,
  macos,
  windows,
  linux,
  web,
}

/// Flutter 设备模型
@JsonSerializable()
class FlutterDevice {
  /// 设备 ID
  final String id;

  /// 设备名称
  final String name;

  /// 设备平台
  final DevicePlatform platform;

  /// 设备类型
  final DeviceType type;

  /// 是否为当前选中的设备
  final bool isActive;

  /// 是否可用
  final bool isAvailable;

  FlutterDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.type,
    this.isActive = false,
    this.isAvailable = true,
  });

  /// 从 flutter devices --machine 输出创建
  factory FlutterDevice.fromFlutterJson(Map<String, dynamic> json) {
    // 解析设备 ID
    final id = json['id'] as String;

    // 解析设备名称
    final name = json['name'] as String;

    // 解析平台 - 检查多个可能的字段
    final platformStr = json['targetPlatform'] as String? ??
                        json['platform'] as String? ??
                        json['category'] as String? ?? 'unknown';

    DevicePlatform platform;
    final platformLower = platformStr.toLowerCase();

    // 使用更灵活的匹配逻辑
    if (platformLower == 'ios') {
      platform = DevicePlatform.ios;
    } else if (platformLower.startsWith('android')) {
      platform = DevicePlatform.android;
    } else if (platformLower == 'darwin' || platformLower == 'macos') {
      platform = DevicePlatform.macos;
    } else if (platformLower == 'windows') {
      platform = DevicePlatform.windows;
    } else if (platformLower == 'linux') {
      platform = DevicePlatform.linux;
    } else if (platformLower.startsWith('web')) {
      platform = DevicePlatform.web;
    } else {
      platform = DevicePlatform.ios;
    }

    // 判断设备类型
    final type = name.toLowerCase().contains('simulator') ||
                name.toLowerCase().contains('emulator')
        ? DeviceType.emulator
        : (platform == DevicePlatform.macos ||
           platform == DevicePlatform.windows ||
           platform == DevicePlatform.linux)
            ? DeviceType.desktop
            : DeviceType.physical;

    // 检查是否可用
    final isAvailable = json['enabled'] as bool? ?? true;

    return FlutterDevice(
      id: id,
      name: name,
      platform: platform,
      type: type,
      isAvailable: isAvailable,
    );
  }

  /// 从 JSON 创建
  factory FlutterDevice.fromJson(Map<String, dynamic> json) =>
      _$FlutterDeviceFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$FlutterDeviceToJson(this);

  /// 复制并修改部分属性
  FlutterDevice copyWith({
    String? id,
    String? name,
    DevicePlatform? platform,
    DeviceType? type,
    bool? isActive,
    bool? isAvailable,
  }) {
    return FlutterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  /// 获取设备图标（考虑平台和设备类型）
  String get platformIcon {
    // 桌面平台
    if (type == DeviceType.desktop) {
      switch (platform) {
        case DevicePlatform.macos:
          return '🍎';  // Apple logo for Mac
        case DevicePlatform.windows:
          return '🪟';
        case DevicePlatform.linux:
          return '🐧';
        default:
          return '🖥️';
      }
    }

    // iOS 设备
    if (platform == DevicePlatform.ios) {
      if (type == DeviceType.emulator) {
        return '📱💻';  // 模拟器（手机+电脑）
      } else if (name.toLowerCase().contains('ipad')) {
        return '📱';  // iPad
      } else {
        return '📱';  // iPhone
      }
    }

    // Android 设备
    if (platform == DevicePlatform.android) {
      if (type == DeviceType.emulator) {
        return '🤖💻';  // 模拟器（机器人+电脑）
      }
      return '🤖';
    }

    // Web
    if (platform == DevicePlatform.web) {
      return '🌐';
    }

    return '📱';  // 默认
  }

  /// 获取设备图标数据（用于 Icon widget）
  IconData get iconData {
    // 桌面平台
    if (type == DeviceType.desktop) {
      switch (platform) {
        case DevicePlatform.macos:
          return Icons.laptop_mac;
        case DevicePlatform.windows:
          return Icons.laptop_windows;
        case DevicePlatform.linux:
          return Icons.computer;
        default:
          return Icons.computer;
      }
    }

    // iOS 设备
    if (platform == DevicePlatform.ios) {
      return Icons.phone_iphone;
    }

    // Android 设备
    if (platform == DevicePlatform.android) {
      return Icons.phone_android;
    }

    // Web
    if (platform == DevicePlatform.web) {
      return Icons.web;
    }

    return Icons.device_unknown;
  }

  /// 获取设备图标资源路径（用于 Image.asset）
  String? get iconAssetPath {
    // iOS 设备
    if (platform == DevicePlatform.ios) {
      if (name.toLowerCase().contains('ipad')) {
        return 'assets/devices/iPad.png';
      }
      return 'assets/devices/iphone.png';
    }

    // Android 设备
    if (platform == DevicePlatform.android) {
      return 'assets/devices/android.png';
    }

    // 桌面平台
    if (type == DeviceType.desktop) {
      switch (platform) {
        case DevicePlatform.macos:
          return 'assets/devices/Laptop.png';
        case DevicePlatform.windows:
        case DevicePlatform.linux:
          return 'assets/devices/Laptop.png';
        default:
          return 'assets/devices/Laptop.png';
      }
    }

    // Web
    if (platform == DevicePlatform.web) {
      return 'assets/devices/iMac.png';
    }

    return null;
  }

  @override
  String toString() {
    return 'FlutterDevice(id: $id, name: $name, platform: $platform, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlutterDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
