import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/bootstrap/main_window.dart';
import 'package:flutter_desk/shared/services/tray_service.dart';
import 'package:flutter_desk/bootstrap/providers/theme_viewmodel.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';

void main() {
  runApp(const FlutterManagerApp());
}

class FlutterManagerApp extends StatefulWidget {
  const FlutterManagerApp({super.key});

  @override
  State<FlutterManagerApp> createState() => _FlutterManagerAppState();
}

class _FlutterManagerAppState extends State<FlutterManagerApp> {
  final TrayService _trayService = TrayService();

  @override
  void initState() {
    super.initState();
    _initializeTrayService();
  }

  Future<void> _initializeTrayService() async {
    await _trayService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => ProjectViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => DeviceViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => CommandViewModel()..initialize()),
      ],
      child: _TrayAwareApp(trayService: _trayService),
    );
  }
}

class _TrayAwareApp extends StatefulWidget {
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

  void _setupTrayListeners() {
    final commandVM = context.read<CommandViewModel>();
    final projectVM = context.read<ProjectViewModel>();
    final deviceVM = context.read<DeviceViewModel>();

    // 设置命令执行回调
    widget.trayService.onRunProject = () {
      if (projectVM.selectedProject != null && deviceVM.selectedDevice != null) {
        commandVM.run(projectVM.selectedProject!, deviceVM.selectedDevice!);
      }
    };

    widget.trayService.onHotReload = () => commandVM.hotReload();
    widget.trayService.onHotRestart = () => commandVM.hotRestart();
    widget.trayService.onStopProject = () => commandVM.stop();
    widget.trayService.onShowMainWindow = () {
      // 主窗口将由 Swift 层显示
    };

    // 监听状态变化，同步到托盘
    commandVM.addListener(() {
      _syncStateToTray(commandVM, projectVM, deviceVM);
    });

    // 监听项目和设备变化
    projectVM.addListener(() {
      _syncStateToTray(commandVM, projectVM, deviceVM);
    });

    deviceVM.addListener(() {
      _syncStateToTray(commandVM, projectVM, deviceVM);
    });

    // 初始同步
    _syncStateToTray(commandVM, projectVM, deviceVM);
  }

  /// 同步状态到托盘
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

          // Use macOS theme
          theme: MacOSTheme.lightTheme,
          darkTheme: MacOSTheme.darkTheme,

          // Use theme from ThemeViewModel
          themeMode: themeVM.themeMode,

          home: const MainWindow(),
        );
      },
    );
  }
}
