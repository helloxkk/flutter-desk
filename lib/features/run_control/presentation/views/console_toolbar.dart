import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/bootstrap/providers/theme_viewmodel.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/shared/models/command_state.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';

/// Console-style toolbar with title, actions, and search
///
/// macOS Console app inspired design with three zones:
/// - Left: Title and status
/// - Center: Action buttons
/// - Right: Search field
class ConsoleToolbar extends StatelessWidget {
  const ConsoleToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left zone: Title and status
          const _TitleZone(),
          const SizedBox(width: 24),

          // Center zone: Action buttons
          const Expanded(child: _ActionsZone()),

          // Right zone: Search and theme toggle
          const _RightZone(),
        ],
      ),
    );
  }
}

/// Title zone with app name and status
class _TitleZone extends StatelessWidget {
  const _TitleZone();

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FlutterDesk',
          style: TextStyle(
            fontSize: MacOSTheme.fontSizeSubheadline,
            fontWeight: MacOSTheme.weightSemibold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Consumer<CommandViewModel>(
          builder: (context, vm, _) {
            final status = vm.state.status;
            String subtitle;
            Color subtitleColor;

            switch (status) {
              case ProcessStatus.idle:
              case ProcessStatus.stopped:
                subtitle = '${vm.logs.length} 条信息';
                subtitleColor = colors.textSecondary;
                break;
              case ProcessStatus.starting:
                subtitle = '启动中...';
                subtitleColor = MacOSTheme.warningOrange;
                break;
              case ProcessStatus.running:
              case ProcessStatus.hotReloading:
              case ProcessStatus.hotRestarting:
                subtitle = '运行中';
                subtitleColor = MacOSTheme.successGreen;
                break;
              case ProcessStatus.building:
                subtitle = '构建中...';
                subtitleColor = MacOSTheme.systemBlue;
                break;
              case ProcessStatus.stopping:
                subtitle = '停止中...';
                subtitleColor = MacOSTheme.warningOrange;
                break;
              case ProcessStatus.error:
                subtitle = '错误';
                subtitleColor = MacOSTheme.errorRed;
                break;
            }

            return Text(
              subtitle,
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption1,
                color: subtitleColor,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Actions zone with control buttons
class _ActionsZone extends StatelessWidget {
  const _ActionsZone();

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProjectViewModel, DeviceViewModel, CommandViewModel>(
      builder: (context, projectVm, deviceVm, commandVm, _) {
        final canRun = projectVm.selectedProject != null &&
            deviceVm.selectedDevice != null &&
            !commandVm.isRunning;

        final canOperate = commandVm.canOperate;
        final isRunning = commandVm.isRunning;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompactToolbarButton(
              icon: Icons.play_arrow_rounded,
              tooltip: '开始',
              isEnabled: canRun,
              color: const Color(0xFF34C759), // 绿色
              onPressed: () => _handleRun(context, projectVm.selectedProject!, deviceVm.selectedDevice!),
            ),
            const SizedBox(width: 2),
            _CompactToolbarButton(
              icon: Icons.bolt_rounded,
              tooltip: '热重载',
              isEnabled: canOperate,
              color: const Color(0xFFFFCC00), // 闪电黄
              onPressed: () => _handleHotReload(context),
            ),
            const SizedBox(width: 2),
            _CompactToolbarButton(
              icon: Icons.refresh_rounded,
              tooltip: '热重启',
              isEnabled: canOperate,
              color: const Color(0xFF007AFF), // 蓝色
              onPressed: () => _handleHotRestart(context),
            ),
            const SizedBox(width: 2),
            _CompactToolbarButton(
              icon: Icons.stop_rounded,
              tooltip: '停止',
              isEnabled: isRunning,
              isDestructive: true, // 保持红色
              onPressed: () => _handleStop(context),
            ),
            const SizedBox(width: 2),
            _CompactToolbarButton(
              icon: Icons.clear_rounded,
              tooltip: '清除',
              isEnabled: commandVm.logs.isNotEmpty,
              onPressed: () => _handleClear(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRun(BuildContext context, FlutterProject project, device) async {
    final commandVm = context.read<CommandViewModel>();
    try {
      await commandVm.run(project, device);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  Future<void> _handleHotReload(BuildContext context) async {
    final commandVm = context.read<CommandViewModel>();
    try {
      await commandVm.hotReload();
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  Future<void> _handleHotRestart(BuildContext context) async {
    final commandVm = context.read<CommandViewModel>();
    try {
      await commandVm.hotRestart();
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  Future<void> _handleStop(BuildContext context) async {
    final commandVm = context.read<CommandViewModel>();
    try {
      await commandVm.stop();
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  void _handleClear(BuildContext context) {
    final commandVm = context.read<CommandViewModel>();
    commandVm.clearLogs();
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: MacOSTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Right zone with search and theme toggle
class _RightZone extends StatelessWidget {
  const _RightZone();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SearchField(),
        SizedBox(width: 12),
        _ThemeToggleButton(),
      ],
    );
  }
}

/// Toolbar button
class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onPressed : null,
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isHovering && widget.isEnabled
                  ? colors.hoverColor
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isDestructive
                      ? MacOSTheme.errorRed
                      : colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightMedium,
                    color: widget.isDestructive
                        ? MacOSTheme.errorRed
                        : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact toolbar button (icon only)
class _CompactToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final bool isDestructive;
  final Color? color;
  final VoidCallback onPressed;

  const _CompactToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    this.isDestructive = false,
    this.color,
    required this.onPressed,
  });

  @override
  State<_CompactToolbarButton> createState() => _CompactToolbarButtonState();
}

class _CompactToolbarButtonState extends State<_CompactToolbarButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    // 确定图标颜色
    Color iconColor;
    if (widget.color != null) {
      iconColor = widget.color!;
    } else if (widget.isDestructive) {
      iconColor = MacOSTheme.errorRed;
    } else {
      iconColor = colors.textSecondary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onPressed : null,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _isHovering && widget.isEnabled
                    ? colors.hoverColor
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search field
class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      width: 160,
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: MacOSTheme.fontSizeCaption2,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '搜索日志...',
          hintStyle: TextStyle(
            fontSize: MacOSTheme.fontSizeCaption2,
            color: colors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 14,
            color: colors.iconColor,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () {
                    _controller.clear();
                    context.read<CommandViewModel>().setSearchKeyword('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          context.read<CommandViewModel>().setSearchKeyword(value);
          setState(() {});
        },
      ),
    );
  }
}

/// Theme toggle button
class _ThemeToggleButton extends StatefulWidget {
  const _ThemeToggleButton();

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final colors = MacOSTheme.of(context);
    final isDark = themeVM.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => themeVM.toggleTheme(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovering ? colors.hoverColor : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 16,
            color: colors.iconColor,
          ),
        ),
      ),
    );
  }
}
