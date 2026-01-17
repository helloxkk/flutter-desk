import 'package:flutter/foundation.dart';
import 'package:flutter_desk/models/flutter_device.dart';
import 'package:flutter_desk/services/device_service.dart';
import 'package:flutter_desk/services/storage_service.dart';

/// 设备管理 ViewModel
class DeviceViewModel extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  final StorageService _storage = StorageService.instance;

  /// 设备列表
  List<FlutterDevice> _devices = [];

  /// 当前选中的设备
  FlutterDevice? _selectedDevice;

  /// 是否正在加载
  bool _isLoading = false;

  /// 错误信息
  String? _error;

  /// 最后更新时间
  DateTime? _lastUpdated;

  /// 设备列表
  List<FlutterDevice> get devices => List.unmodifiable(_devices);

  /// 当前选中的设备
  FlutterDevice? get selectedDevice => _selectedDevice;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get error => _error;

  /// 是否有设备
  bool get hasDevices => _devices.isNotEmpty;

  /// 是否有可用设备
  bool get hasAvailableDevices => _devices.any((d) => d.isAvailable);

  /// 物理设备列表
  List<FlutterDevice> get physicalDevices =>
      _devices.where((d) => d.type == DeviceType.physical).toList();

  /// 模拟器列表
  List<FlutterDevice> get emulators =>
      _devices.where((d) => d.type == DeviceType.emulator).toList();

  /// 桌面设备列表
  List<FlutterDevice> get desktopDevices =>
      _devices.where((d) => d.type == DeviceType.desktop).toList();

  /// 最后更新时间
  DateTime? get lastUpdated => _lastUpdated;

  /// 初始化
  Future<void> initialize() async {
    await refreshDevices();

    // 加载最后选择的设备
    final lastDeviceId = await _storage.loadLastDevice();
    if (lastDeviceId != null) {
      final device = _deviceService.getDeviceById(lastDeviceId);
      if (device != null) {
        selectDevice(device);
      }
    }
  }

  /// 刷新设备列表
  Future<void> refreshDevices({bool forceRefresh = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _deviceService.getDevices(forceRefresh: forceRefresh);
      _lastUpdated = _deviceService.lastUpdated;

      // 如果当前没有选中设备，选择第一个可用设备
      if (_selectedDevice == null && _devices.isNotEmpty) {
        final firstAvailable = _devices.firstWhere(
          (d) => d.isAvailable,
          orElse: () => _devices.first,
        );
        selectDevice(firstAvailable);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 选择设备
  void selectDevice(FlutterDevice device) {
    if (_selectedDevice?.id != device.id) {
      _selectedDevice = device;
      _storage.saveLastDevice(device);
      notifyListeners();
    }
  }

  /// 根据 ID 选择设备
  void selectDeviceById(String deviceId) {
    final device = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => _devices.first,
    );
    selectDevice(device);
  }

  /// 获取 macOS 设备
  FlutterDevice? get macOSDevice {
    try {
      return _devices.firstWhere(
        (d) => d.platform == DevicePlatform.macos,
      );
    } catch (e) {
      return null;
    }
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

}
