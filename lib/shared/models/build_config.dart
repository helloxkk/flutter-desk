import 'package:json_annotation/json_annotation.dart';

part 'build_config.g.dart';

/// 构建类型枚举
enum BuildType {
  /// APK (Android)
  apk,

  /// IPA (iOS)
  ipa,

  /// App Bundle (Android)
  appBundle,

  /// macOS
  macos,

  /// Windows
  windows,

  /// Linux
  linux,

  /// Web
  web,
}

/// 构建配置模型
@JsonSerializable()
class BuildConfig {
  /// 构建类型
  final BuildType type;

  /// 是否为 Release 构建
  final bool isRelease;

  /// Split debug info 路径（可选）
  final String? splitDebugInfo;

  /// Split per ABI（仅 Android）
  final bool? splitPerAbi;

  /// 构建输出路径（可选）
  final String? output_path;

  /// 额外的构建参数
  final List<String> extraArgs;

  const BuildConfig({
    required this.type,
    this.isRelease = true,
    this.splitDebugInfo,
    this.splitPerAbi,
    this.output_path,
    this.extraArgs = const [],
  });

  /// 从 JSON 创建
  factory BuildConfig.fromJson(Map<String, dynamic> json) =>
      _$BuildConfigFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$BuildConfigToJson(this);

  /// 复制并修改部分属性
  BuildConfig copyWith({
    BuildType? type,
    bool? isRelease,
    String? splitDebugInfo,
    bool? splitPerAbi,
    String? output_path,
    List<String>? extraArgs,
  }) {
    return BuildConfig(
      type: type ?? this.type,
      isRelease: isRelease ?? this.isRelease,
      splitDebugInfo: splitDebugInfo ?? this.splitDebugInfo,
      splitPerAbi: splitPerAbi ?? this.splitPerAbi,
      output_path: output_path ?? this.output_path,
      extraArgs: extraArgs ?? this.extraArgs,
    );
  }

  /// 获取构建命令
  List<String> get buildCommand {
    final command = <String>['build'];

    // 添加平台特定的子命令
    switch (type) {
      case BuildType.apk:
        command.add('apk');
        break;
      case BuildType.ipa:
        command.add('ios');
        break;
      case BuildType.appBundle:
        command.add('appbundle');
        break;
      case BuildType.macos:
        command.add('macos');
        break;
      case BuildType.windows:
        command.add('windows');
        break;
      case BuildType.linux:
        command.add('linux');
        break;
      case BuildType.web:
        command.add('web');
        break;
    }

    // 添加 Debug/Release 标志
    if (isRelease) {
      command.add('--release');
    } else {
      command.add('--debug');
    }

    // 添加 split debug info
    if (splitDebugInfo != null) {
      command.addAll(['--split-debug-info', splitDebugInfo!]);
    }

    // 添加 split per abi
    if (splitPerAbi == true) {
      command.add('--split-per-abi');
    }

    // 添加输出路径
    if (output_path != null) {
      command.addAll(['--build-output', output_path!]);
    }

    // 添加额外参数
    command.addAll(extraArgs);

    return command;
  }

  /// 获取构建产物的输出路径（相对于项目路径）
  String get outputRelativePath {
    switch (type) {
      case BuildType.apk:
        return 'build/app/outputs/flutter-apk/app-release.apk';
      case BuildType.ipa:
        return 'build/ios/archive/Runner.xcarchive';
      case BuildType.appBundle:
        return 'build/app/outputs/bundle/release/app.aab';
      case BuildType.macos:
        return 'build/macos/Build/Products/Release/Runner.app';
      case BuildType.windows:
        return 'build/windows/runner/Release/Runner.exe';
      case BuildType.linux:
        return 'build/linux/x64/release/bundle';
      case BuildType.web:
        return 'build/web';
    }
  }

  /// 获取构建产物的目录路径（相对于项目路径）
  String get outputDirectory {
    switch (type) {
      case BuildType.apk:
        return 'build/app/outputs/flutter-apk';
      case BuildType.ipa:
        return 'build/ios/archive';
      case BuildType.appBundle:
        return 'build/app/outputs/bundle/release';
      case BuildType.macos:
        return 'build/macos/Build/Products/Release';
      case BuildType.windows:
        return 'build/windows/runner/Release';
      case BuildType.linux:
        return 'build/linux/x64/release/bundle';
      case BuildType.web:
        return 'build/web';
    }
  }

  /// 获取输出文件模式（用于查找构建产物）
  String get outputPattern {
    switch (type) {
      case BuildType.apk:
        return 'build/app/outputs/flutter-apk/*.apk';
      case BuildType.ipa:
        return 'build/ios/archive/*.xcarchive';
      case BuildType.appBundle:
        return 'build/app/outputs/bundle/release/*.aab';
      case BuildType.macos:
        return 'build/macos/Build/Products/Release/*.app';
      case BuildType.windows:
        return 'build/windows/runner/Release/*.exe';
      case BuildType.linux:
        return 'build/linux/*/release/bundle';
      case BuildType.web:
        return 'build/web';
    }
  }

  /// 获取显示名称
  String get displayName {
    final mode = isRelease ? 'Release' : 'Debug';
    switch (type) {
      case BuildType.apk:
        return 'APK ($mode)';
      case BuildType.ipa:
        return 'IPA ($mode)';
      case BuildType.appBundle:
        return 'App Bundle ($mode)';
      case BuildType.macos:
        return 'macOS ($mode)';
      case BuildType.windows:
        return 'Windows ($mode)';
      case BuildType.linux:
        return 'Linux ($mode)';
      case BuildType.web:
        return 'Web ($mode)';
    }
  }

  @override
  String toString() {
    return 'BuildConfig(type: $type, isRelease: $isRelease)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuildConfig &&
        other.type == type &&
        other.isRelease == isRelease;
  }

  @override
  int get hashCode => Object.hash(type, isRelease);
}

/// 预设的构建配置
class BuildPresets {
  /// Android APK (Release)
  static const androidApkRelease = BuildConfig(
    type: BuildType.apk,
    isRelease: true,
  );

  /// Android APK (Debug)
  static const androidApkDebug = BuildConfig(
    type: BuildType.apk,
    isRelease: false,
  );

  /// Android App Bundle (Release)
  static const androidAppBundleRelease = BuildConfig(
    type: BuildType.appBundle,
    isRelease: true,
  );

  /// iOS IPA (Release)
  static const iosIpaRelease = BuildConfig(
    type: BuildType.ipa,
    isRelease: true,
  );

  /// macOS (Release)
  static const macosRelease = BuildConfig(
    type: BuildType.macos,
    isRelease: true,
  );

  /// Web (Release)
  static const webRelease = BuildConfig(
    type: BuildType.web,
    isRelease: true,
  );

  /// 所有预设配置
  static const List<BuildConfig> all = [
    androidApkRelease,
    androidApkDebug,
    androidAppBundleRelease,
    iosIpaRelease,
    macosRelease,
    webRelease,
  ];

  /// Android 构建配置
  static const List<BuildConfig> android = [
    androidApkRelease,
    androidApkDebug,
    androidAppBundleRelease,
  ];

  /// iOS 构建配置
  static const List<BuildConfig> ios = [
    iosIpaRelease,
  ];

  /// Desktop 构建配置
  static const List<BuildConfig> desktop = [
    macosRelease,
  ];

  /// Web 构建配置
  static const List<BuildConfig> web = [
    webRelease,
  ];
}
