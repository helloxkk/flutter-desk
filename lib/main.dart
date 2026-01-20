import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/bootstrap/main_window.dart';
import 'package:flutter_desk/shared/services/tray_service.dart';
import 'package:flutter_desk/bootstrap/providers/theme_viewmodel.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';

/// 应用程序入口点
///
/// 初始化并运行 FlutterDesk 应用，这是一个用于管理 Flutter 项目的桌面工具。
void main() {
  runApp(const FlutterManagerApp());
}

/// FlutterDesk 应用根组件
///
/// 负责初始化系统托盘服务，并创建应用的 Provider 层级结构。
/// 这是整个应用的根 Widget，管理全局状态和服务。
class FlutterManagerApp extends StatefulWidget {
  const FlutterManagerApp({super.key});

  @override
  State<FlutterManagerApp> createState() => _FlutterManagerAppState();
}

class _FlutterManagerAppState extends State<FlutterManagerApp> {
  /// 系统托盘服务实例，用于与 macOS 托盘图标通信
  final TrayService _trayService = TrayService();

  @override
  void initState() {
    super.initState();
    _initializeTrayService();
  }

  /// 初始化系统托盘服务
  ///
  /// 建立与 Swift 原生层的通信桥梁，实现托盘菜单功能。
  Future<void> _initializeTrayService() async {
    await _trayService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 MultiProvider 管理多个全局状态
    return MultiProvider(
      providers: [
        // 主题管理 - 控制明暗模式切换
        ChangeNotifierProvider(create: (_) => ThemeViewModel()..initialize()),
        // 项目管理 - 管理 Flutter 项目列表和选择
        ChangeNotifierProvider(create: (_) => ProjectViewModel()..initialize()),
        // 设备管理 - 管理可用设备列表和选择
        ChangeNotifierProvider(create: (_) => DeviceViewModel()..initialize()),
        // 命令执行 - 管理 Flutter 进程和日志
        ChangeNotifierProvider(create: (_) => CommandViewModel()..initialize()),
      ],
      child: _TrayAwareApp(trayService: _trayService),
    );
  }
}

/// 托盘感知的应用包装器
///
/// 负责设置托盘菜单回调，并同步应用状态到系统托盘。
/// 延迟到 Provider 初始化完成后建立监听，确保可以访问 ViewModel。
class _TrayAwareApp extends StatefulWidget {
  /// 托盘服务实例
  final TrayService trayService;

  const _TrayAwareApp({required this.trayService});

  @override
  State<_TrayAwareApp> createState() => _TrayAwareAppState();
}

class _TrayAwareAppState extends State<_TrayAwareApp> {
  @override
  void initState() {
    super.initState();
    // 延迟到第一次 build 后设置监听，确保 Provider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupTrayListeners();
    });
  }

  /// 设置系统托盘菜单的回调函数
  ///
  /// 将托盘菜单的各种操作连接到对应的 ViewModel 方法。
  void _setupTrayListeners() {
    final commandVM = context.read<CommandViewModel>();
    final projectVM = context.read<ProjectViewModel>();
    final deviceVM = context.read<DeviceViewModel>();

    // 设置命令执行回调 - 运行 Flutter 项目
    widget.trayService.onRunProject = () {
      if (projectVM.selectedProject != null && deviceVM.selectedDevice != null) {
        commandVM.run(projectVM.selectedProject!, deviceVM.selectedDevice!);
      }
    };

    // 热重载回调
    widget.trayService.onHotReload = () => commandVM.hotReload();
    // 热重启回调
    widget.trayService.onHotRestart = () => commandVM.hotRestart();
    // 停止项目回调
    widget.trayService.onStopProject = () => commandVM.stop();
    // 显示主窗口回调（由 Swift 层处理）
    widget.trayService.onShowMainWindow = () {
      // 主窗口将由 Swift 层显示
    };

    // 监听命令状态变化，同步到托盘
    commandVM.addListener(() {
      _syncStateToTray(commandVM, projectVM, deviceVM);
    });

    // 监听项目选择变化
    projectVM.addListener(() {
      _syncStateToTray(commandVM, projectVM, deviceVM);
    });

    // 监听设备选择变化
    deviceVM.addListener(() {
      _syncStateToTray(commandVM, projectVM, deviceVM);
    });

    // 初始同步
    _syncStateToTray(commandVM, projectVM, deviceVM);
  }

  /// 同步应用状态到系统托盘
  ///
  /// 将当前的运行状态、选中的项目和设备信息发送到托盘服务，
  /// 以便托盘菜单能够显示正确的状态。
  void _syncStateToTray(
    CommandViewModel commandVM,
    ProjectViewModel projectVM,
    DeviceViewModel deviceVM,
  ) {
    widget.trayService.updateState(
      status: commandVM.state.status,
      project: projectVM.selectedProject,
      device: deviceVM.selectedDevice,
      isRunning: commandVM.isRunning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeVM, child) {
        return MaterialApp(
          title: 'Flutter Manager',
          debugShowCheckedModeBanner: false,

          // 使用 macOS 原生主题
          theme: MacOSTheme.lightTheme,
          darkTheme: MacOSTheme.darkTheme,

          // 根据用户选择的主题模式显示
          themeMode: themeVM.themeMode,

          home: const MainWindow(),
        );
      },
    );
  }
}
