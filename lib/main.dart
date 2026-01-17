import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/views/main_window.dart';
import 'package:flutter_desk/services/tray_service.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';

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
    return MaterialApp(
      title: 'Flutter Manager',
      debugShowCheckedModeBanner: false,

      // Use macOS theme
      theme: MacOSTheme.lightTheme,
      darkTheme: MacOSTheme.darkTheme,

      // Follow system theme mode
      themeMode: ThemeMode.system,

      home: const MainWindow(),
    );
  }
}
