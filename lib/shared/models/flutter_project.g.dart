// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlutterProject _$FlutterProjectFromJson(Map<String, dynamic> json) =>
    FlutterProject(
      name: json['name'] as String,
      path: json['path'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$FlutterProjectToJson(FlutterProject instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'description': instance.description,
      'isActive': instance.isActive,
    };
