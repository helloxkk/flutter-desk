import 'package:json_annotation/json_annotation.dart';

part 'flutter_project.g.dart';

/// Flutter 项目模型
@JsonSerializable()
class FlutterProject {
  /// 项目名称（从 pubspec.yaml 读取）
  final String name;

  /// 项目绝对路径
  final String path;

  /// 项目描述
  final String? description;

  /// 是否为当前选中的项目
  final bool isActive;

  FlutterProject({
    required this.name,
    required this.path,
    this.description,
    this.isActive = false,
  });

  /// 从 JSON 创建
  factory FlutterProject.fromJson(Map<String, dynamic> json) =>
      _$FlutterProjectFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$FlutterProjectToJson(this);

  /// 复制并修改部分属性
  FlutterProject copyWith({
    String? name,
    String? path,
    String? description,
    bool? isActive,
  }) {
    return FlutterProject(
      name: name ?? this.name,
      path: path ?? this.path,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'FlutterProject(name: $name, path: $path, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlutterProject && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
