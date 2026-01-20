/// 应用常量
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  /// 应用名称
  static const String appName = 'FlutterDesk';

  /// 默认项目名称
  static const String defaultProjectName = '未命名项目';

  /// SharedPreferences 键
  static const String keyProjects = 'flutter_projects';
  static const String keyLastProject = 'last_project_id';
  static const String keyLastDevice = 'last_device_id';

  /// 热重载命令
  static const String hotReloadCommand = 'r';

  /// 热重启命令
  static const String hotRestartCommand = 'R';

  /// 停止命令
  static const String stopCommand = 'q';

  /// Flutter 命令超时（秒）
  static const int flutterCommandTimeout = 300;

  /// 最大日志条数
  static const int maxLogLines = 1000;

  /// 默认 Flutter 项目路径
  static const String defaultFlutterPath = '/Users/kun/CursorProjects';

  /// 支持的 Flutter 项目标识文件
  static const List<String> flutterProjectMarkers = [
    'pubspec.yaml',
    'lib/main.dart',
  ];

  /// 工具命令成功提示消息
  static const Map<String, String> toolCommandMessages = {
    'clean': '项目清理完成',
    'pubGet': '依赖安装完成',
    'pubUpgrade': '依赖升级完成',
    'pubOutdated': '依赖检查完成',
  };
}

/// 应用日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// build_runner 命令枚举
enum BuildRunnerCommand {
  /// 执行一次性构建
  build,

  /// 清理生成的文件
  clean,

  /// 监视文件变化并自动构建
  watch,
}
