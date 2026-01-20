import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/features/project_management/presentation/views/console_sidebar.dart';
import 'package:flutter_desk/features/run_control/presentation/views/console_toolbar.dart';
import 'package:flutter_desk/features/log_viewer/presentation/widgets/segmented_filter.dart';
import 'package:flutter_desk/features/log_viewer/presentation/views/console_content_area.dart';

/// 主窗口 - 控制台风格布局
///
/// 采用 macOS Console.app 的设计风格，经典的三栏布局：
/// - 左侧边栏：项目和设备管理
/// - 右侧上部：工具栏（标题、操作按钮、搜索）
/// - 右侧中部：日志过滤器
/// - 右侧下部：日志内容显示区域
class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    // 为窗口级别的功能创建独立的 Provider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => DeviceViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => CommandViewModel()..initialize()),
      ],
      child: const _MainWindowContent(),
    );
  }
}

/// 主窗口内容 - 实际渲染的 UI 结构
///
/// 使用 Row + Column 的组合实现三栏布局：
/// - 左侧固定宽度的边栏
/// - 右侧自适应的内容区域
class _MainWindowContent extends StatefulWidget {
  const _MainWindowContent();

  @override
  State<_MainWindowContent> createState() => _MainWindowContentState();
}

class _MainWindowContentState extends State<_MainWindowContent> {
  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Scaffold(
      backgroundColor: colors.cardBackground,
      body: Row(
        children: [
          // 左侧边栏 - 显示项目和设备列表
          const ConsoleSidebar(),

          // 右侧内容区域
          Expanded(
            child: Column(
              children: const [
                // 工具栏 - 包含标题、操作按钮和搜索框
                ConsoleToolbar(),

                // 分段过滤器 - 用于过滤不同类型的日志
                SegmentedFilter(),

                // 日志内容显示区域
                Expanded(
                  child: ConsoleContentArea(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
