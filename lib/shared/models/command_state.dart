import 'package:json_annotation/json_annotation.dart';

part 'command_state.g.dart';

/// 最大日志数量限制
const int _maxLogLines = 1000;

/// Flutter 进程状态
enum ProcessStatus {
  /// 未启动
  idle,

  /// 启动中
  starting,

  /// 运行中
  running,

  /// 热重载中
  hotReloading,

  /// 热重启中
  hotRestarting,

  /// 构建中
  building,

  /// 停止中
  stopping,

  /// 已停止
  stopped,

  /// 错误
  error,
}

/// Flutter 命令执行状态
@JsonSerializable()
class CommandState {
  /// 当前状态
  final ProcessStatus status;

  /// 当前执行的项目
  final String? projectId;

  /// 当前使用的设备
  final String? deviceId;

  /// 进程 ID
  final int? pid;

  /// 错误信息
  final String? error;

  /// 最后的日志输出
  final List<String> logs;

  /// 状态更新时间
  final DateTime updatedAt;

  CommandState({
    this.status = ProcessStatus.idle,
    this.projectId,
    this.deviceId,
    this.pid,
    this.error,
    List<String>? logs,
    DateTime? updatedAt,
  })  : logs = logs ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 创建
  factory CommandState.fromJson(Map<String, dynamic> json) =>
      _$CommandStateFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$CommandStateToJson(this);

  /// 复制并修改部分属性
  CommandState copyWith({
    ProcessStatus? status,
    String? projectId,
    String? deviceId,
    int? pid,
    String? error,
    List<String>? logs,
    DateTime? updatedAt,
  }) {
    return CommandState(
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      deviceId: deviceId ?? this.deviceId,
      pid: pid ?? this.pid,
      error: error,
      logs: logs ?? this.logs,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 添加日志（限制最大行数以避免内存问题）
  CommandState addLog(String log) {
    final newLogs = [...logs, log];
    // 如果超过最大行数，移除最旧的日志
    if (newLogs.length > _maxLogLines) {
      final trimmedLogs = newLogs.skip(newLogs.length - _maxLogLines).toList();
      return copyWith(
        logs: trimmedLogs,
        updatedAt: DateTime.now(),
      );
    }
    return copyWith(
      logs: newLogs,
      updatedAt: DateTime.now(),
    );
  }

  /// 清空日志
  CommandState clearLogs() {
    return copyWith(
      logs: [],
      updatedAt: DateTime.now(),
    );
  }

  /// 是否正在运行
  bool get isRunning =>
      status == ProcessStatus.running ||
      status == ProcessStatus.hotReloading ||
      status == ProcessStatus.hotRestarting;

  /// 是否正在执行操作（禁止启动新任务）
  bool get isBusy =>
      status == ProcessStatus.running ||
      status == ProcessStatus.hotReloading ||
      status == ProcessStatus.hotRestarting ||
      status == ProcessStatus.building ||
      status == ProcessStatus.starting ||
      status == ProcessStatus.stopping;

  /// 是否可以执行热重载/热重启操作（仅在完全运行状态下）
  bool get canOperate => status == ProcessStatus.running;

  @override
  String toString() {
    return 'CommandState(status: $status, projectId: $projectId, deviceId: $deviceId, pid: $pid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommandState &&
        other.status == status &&
        other.projectId == projectId &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode => Object.hash(status, projectId, deviceId);
}
