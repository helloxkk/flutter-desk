// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandState _$CommandStateFromJson(Map<String, dynamic> json) => CommandState(
      status: $enumDecodeNullable(_$ProcessStatusEnumMap, json['status']) ??
          ProcessStatus.idle,
      projectId: json['projectId'] as String?,
      deviceId: json['deviceId'] as String?,
      pid: (json['pid'] as num?)?.toInt(),
      error: json['error'] as String?,
      logs: (json['logs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CommandStateToJson(CommandState instance) =>
    <String, dynamic>{
      'status': _$ProcessStatusEnumMap[instance.status]!,
      'projectId': instance.projectId,
      'deviceId': instance.deviceId,
      'pid': instance.pid,
      'error': instance.error,
      'logs': instance.logs,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProcessStatusEnumMap = {
  ProcessStatus.idle: 'idle',
  ProcessStatus.starting: 'starting',
  ProcessStatus.running: 'running',
  ProcessStatus.hotReloading: 'hotReloading',
  ProcessStatus.hotRestarting: 'hotRestarting',
  ProcessStatus.building: 'building',
  ProcessStatus.stopping: 'stopping',
  ProcessStatus.stopped: 'stopped',
  ProcessStatus.error: 'error',
};
