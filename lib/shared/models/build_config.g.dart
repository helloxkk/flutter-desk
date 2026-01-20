// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildConfig _$BuildConfigFromJson(Map<String, dynamic> json) => BuildConfig(
      type: $enumDecode(_$BuildTypeEnumMap, json['type']),
      isRelease: json['isRelease'] as bool? ?? true,
      splitDebugInfo: json['splitDebugInfo'] as String?,
      splitPerAbi: json['splitPerAbi'] as bool?,
      outputPath: json['output_path'] as String?,
      extraArgs: (json['extraArgs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BuildConfigToJson(BuildConfig instance) =>
    <String, dynamic>{
      'type': _$BuildTypeEnumMap[instance.type]!,
      'isRelease': instance.isRelease,
      'splitDebugInfo': instance.splitDebugInfo,
      'splitPerAbi': instance.splitPerAbi,
      'output_path': instance.outputPath,
      'extraArgs': instance.extraArgs,
    };

const _$BuildTypeEnumMap = {
  BuildType.apk: 'apk',
  BuildType.ipa: 'ipa',
  BuildType.appBundle: 'appBundle',
  BuildType.macos: 'macos',
  BuildType.windows: 'windows',
  BuildType.linux: 'linux',
  BuildType.web: 'web',
};
