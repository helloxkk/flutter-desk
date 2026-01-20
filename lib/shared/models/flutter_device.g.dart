// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlutterDevice _$FlutterDeviceFromJson(Map<String, dynamic> json) =>
    FlutterDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: $enumDecode(_$DevicePlatformEnumMap, json['platform']),
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      isActive: json['isActive'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );

Map<String, dynamic> _$FlutterDeviceToJson(FlutterDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'platform': _$DevicePlatformEnumMap[instance.platform]!,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'isActive': instance.isActive,
      'isAvailable': instance.isAvailable,
    };

const _$DevicePlatformEnumMap = {
  DevicePlatform.ios: 'ios',
  DevicePlatform.android: 'android',
  DevicePlatform.macos: 'macos',
  DevicePlatform.windows: 'windows',
  DevicePlatform.linux: 'linux',
  DevicePlatform.web: 'web',
};

const _$DeviceTypeEnumMap = {
  DeviceType.physical: 'physical',
  DeviceType.emulator: 'emulator',
  DeviceType.desktop: 'desktop',
};
