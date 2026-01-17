import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/models/command_state.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';
import 'package:flutter_desk/views/project_selector.dart';
import 'package:flutter_desk/views/device_selector.dart';
import 'package:flutter_desk/views/action_panel.dart';
import 'package:flutter_desk/views/log_viewer.dart';
import 'package:flutter_desk/views/build_panel.dart';
import 'package:flutter_desk/views/codegen_panel.dart';

/// 主窗口 - macOS Native Window Style (Flat)
class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
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

class _MainWindowContent extends StatefulWidget {
  const _MainWindowContent();

  @override
  State<_MainWindowContent> createState() => _MainWindowContentState();
}

class _MainWindowContentState extends State<_MainWindowContent> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : MacOSTheme.cardBackground,
      body: Column(
        children: [
          // Header - Fixed at top
          _Header(),
          const Divider(height: 1, thickness: 0.5),

          // Content - Fills remaining space
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MacOSTheme.paddingXXL,
                    ),
                    child: TabBar(
                      tabs: const [
                        Tab(text: '运行'),
                        Tab(text: '构建'),
                        Tab(text: '代码生成'),
                      ],
                      labelColor: MacOSTheme.systemBlue,
                      unselectedLabelColor: MacOSTheme.textSecondary,
                      indicatorColor: MacOSTheme.systemBlue,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontSize: MacOSTheme.fontSizeFootnote,
                        fontWeight: MacOSTheme.weightSemibold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: MacOSTheme.fontSizeFootnote,
                        fontWeight: MacOSTheme.weightMedium,
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 运行 Tab
                        ListView(
                          padding: const EdgeInsets.all(MacOSTheme.paddingXXL),
                          children: const [
                            ProjectSelector(),
                            SizedBox(height: MacOSTheme.paddingL),

                            DeviceSelector(),
                            SizedBox(height: MacOSTheme.paddingXL),

                            ActionPanel(),
                            SizedBox(height: MacOSTheme.paddingL),

                            LogViewer(),
                          ],
                        ),

                        // 构建 Tab
                        ListView(
                          padding: const EdgeInsets.all(MacOSTheme.paddingXXL),
                          children: const [
                            ProjectSelector(),
                            SizedBox(height: MacOSTheme.paddingL),

                            BuildPanel(),
                            SizedBox(height: MacOSTheme.paddingL),

                            LogViewer(),
                          ],
                        ),

                        // 代码生成 Tab
                        ListView(
                          padding: const EdgeInsets.all(MacOSTheme.paddingXXL),
                          children: const [
                            ProjectSelector(),
                            SizedBox(height: MacOSTheme.paddingL),

                            CodegenPanel(),
                            SizedBox(height: MacOSTheme.paddingL),

                            LogViewer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header with title and status - Unified with macOS titlebar
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.only(
        left: 20, // Closer to traffic light buttons
        right: MacOSTheme.paddingXXL,
        top: MacOSTheme.paddingS,
        bottom: MacOSTheme.paddingS,
      ),
      color: isDark
          ? const Color(0xFF2C2C2E).withOpacity(0.5)
          : MacOSTheme.systemGray6.withOpacity(0.5),
      child: Row(
        children: [
          // App icon
          _AppIcon(),
          SizedBox(width: MacOSTheme.paddingM),

          // Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FlutterDesk',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeHeadline,
                    fontWeight: MacOSTheme.weightSemibold,
                    color: MacOSTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Flutter Project Management',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightRegular,
                    color: MacOSTheme.textSecondary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          _StatusIndicator(),
        ],
      ),
    );
  }
}

/// App icon with gradient background
class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF007AFF),
            Color(0xFF5856D6),
          ],
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(MacOSTheme.radiusSmall),
        ),
      ),
      child: const Center(
        child: Text(
          'F',
          style: TextStyle(
            fontSize: 20,
            fontWeight: MacOSTheme.weightBold,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Status indicator showing process state
class _StatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CommandViewModel>(
      builder: (context, vm, _) {
        final status = vm.state.status;
        final isRunning = vm.isRunning;

        Color dotColor;
        String statusText;

        switch (status) {
          case ProcessStatus.idle:
            dotColor = MacOSTheme.systemGray3;
            statusText = 'Idle';
            break;
          case ProcessStatus.starting:
            dotColor = MacOSTheme.warningOrange;
            statusText = 'Starting...';
            break;
          case ProcessStatus.running:
          case ProcessStatus.hotReloading:
          case ProcessStatus.hotRestarting:
            dotColor = MacOSTheme.successGreen;
            statusText = 'Running';
            break;
          case ProcessStatus.building:
            dotColor = MacOSTheme.systemBlue;
            statusText = 'Building...';
            break;
          case ProcessStatus.stopping:
            dotColor = MacOSTheme.warningOrange;
            statusText = 'Stopping...';
            break;
          case ProcessStatus.stopped:
            dotColor = MacOSTheme.systemGray3;
            statusText = 'Stopped';
            break;
          case ProcessStatus.error:
            dotColor = MacOSTheme.errorRed;
            statusText = 'Error';
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MacOSTheme.paddingM,
            vertical: MacOSTheme.paddingXS,
          ),
          decoration: BoxDecoration(
            color: MacOSTheme.systemGray6.withOpacity(0.5),
            borderRadius: const BorderRadius.all(
              Radius.circular(MacOSTheme.radiusSmall),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated dot
              _StatusDot(color: dotColor, isRunning: isRunning),
              const SizedBox(width: MacOSTheme.paddingS),

              // Status text
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption2,
                  fontWeight: MacOSTheme.weightMedium,
                  color: MacOSTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated status dot
class _StatusDot extends StatefulWidget {
  final Color color;
  final bool isRunning;

  const _StatusDot({
    required this.color,
    required this.isRunning,
  });

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isRunning) {
      _controller.repeat(reverse: true);
    }

    // 标记初始化完成，避免 didUpdateWidget 首次调用时的竞态条件
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 只在初始化完成后才响应状态变化，避免与 initState 产生竞态条件
    if (!_isInitialized) return;

    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(
              widget.isRunning ? _animation.value : 1.0,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
