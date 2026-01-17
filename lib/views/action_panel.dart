import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';
import 'package:flutter_desk/models/flutter_project.dart';
import 'package:flutter_desk/utils/constants.dart';

/// 操作按钮面板 - macOS Native Design
class ActionPanel extends StatelessWidget {
  const ActionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProjectViewModel, DeviceViewModel, CommandViewModel>(
      builder: (context, projectVm, deviceVm, commandVm, child) {
        final canRun = projectVm.selectedProject != null &&
            deviceVm.selectedDevice != null &&
            !commandVm.isRunning;

        final canOperate = commandVm.canOperate;

        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.play_arrow_rounded,
                label: '运行',
                isEnabled: canRun,
                isPrimary: true,
                onPressed: () async {
                  final project = projectVm.selectedProject!;
                  final device = deviceVm.selectedDevice!;
                  try {
                    await commandVm.run(project, device);
                  } catch (e) {
                    if (context.mounted) {
                      _showError(context, e.toString());
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            Expanded(
              child: _ActionButton(
                icon: Icons.bolt_rounded,
                label: '热重载',
                isEnabled: canOperate,
                onPressed: () async {
                  try {
                    await commandVm.hotReload();
                  } catch (e) {
                    if (context.mounted) {
                      _showError(context, e.toString());
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            Expanded(
              child: _ActionButton(
                icon: Icons.restart_alt_rounded,
                label: '热重启',
                isEnabled: canOperate,
                onPressed: () async {
                  try {
                    await commandVm.hotRestart();
                  } catch (e) {
                    if (context.mounted) {
                      _showError(context, e.toString());
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            Expanded(
              child: _ActionButton(
                icon: Icons.stop_rounded,
                label: '停止',
                isEnabled: commandVm.isRunning,
                isDestructive: true,
                onPressed: () async {
                  try {
                    await commandVm.stop();
                  } catch (e) {
                    if (context.mounted) {
                      _showError(context, e.toString());
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            // 工具菜单按钮
            _ToolMenuButton(
              project: projectVm.selectedProject,
              isBusy: commandVm.state.isBusy,
              onCommand: (command) async {
                final project = projectVm.selectedProject;
                if (project == null) return;

                try {
                  switch (command) {
                    case ToolCommand.clean:
                      await commandVm.cleanProject(project.path);
                      break;
                    case ToolCommand.pubGet:
                      await commandVm.getDependencies(project.path);
                      break;
                    case ToolCommand.pubUpgrade:
                      await commandVm.upgradeDependencies(project.path);
                      break;
                    case ToolCommand.pubOutdated:
                      await commandVm.pubOutdated(project.path);
                      break;
                  }
                  if (context.mounted) {
                    _showSuccess(context, _getCommandMessage(command));
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showError(context, e.toString());
                  }
                }
              },
            ),
          ],
        );
      },
    );
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

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MacOSTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getCommandMessage(ToolCommand command) {
    final messageKey = command.name;
    return AppConstants.toolCommandMessages[messageKey] ?? '操作完成';
  }
}

/// macOS-style action button
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isPrimary;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    this.isPrimary = false,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color hoverColor;

    if (widget.isDestructive) {
      bgColor = MacOSTheme.errorRed.withOpacity(0.1);
      fgColor = MacOSTheme.errorRed;
      hoverColor = MacOSTheme.errorRed.withOpacity(0.2);
    } else if (widget.isPrimary) {
      bgColor = MacOSTheme.systemBlue;
      fgColor = Colors.white;
      hoverColor = const Color(0xFF0066CC);
    } else {
      bgColor = isDark
          ? const Color(0xFF2C2C2E)
          : Colors.white;
      fgColor = MacOSTheme.textPrimary;
      hoverColor = isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05);
    }

    final opacity = widget.isEnabled ? 1.0 : 0.4;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.isEnabled) {
            widget.onPressed();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 32,
            decoration: BoxDecoration(
              color: _isPressed
                  ? hoverColor.withOpacity(0.5)
                  : (_isHovering ? hoverColor : bgColor),
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
              border: Border.all(
                color: widget.isPrimary || widget.isDestructive
                    ? Colors.transparent
                    : MacOSTheme.borderMedium,
                width: 0.5,
              ),
              boxShadow: widget.isPrimary && _isHovering
                  ? MacOSTheme.shadowCard
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: fgColor.withOpacity(opacity),
                ),
                const SizedBox(width: MacOSTheme.paddingXS),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeFootnote,
                    fontWeight: widget.isPrimary
                        ? MacOSTheme.weightSemibold
                        : MacOSTheme.weightMedium,
                    color: fgColor.withOpacity(opacity),
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

/// 工具命令枚举
enum ToolCommand {
  clean,
  pubGet,
  pubUpgrade,
  pubOutdated,
}

/// 工具菜单按钮 - macOS Native Dropdown
class _ToolMenuButton extends StatefulWidget {
  final FlutterProject? project;
  final bool isBusy;
  final Function(ToolCommand) onCommand;

  const _ToolMenuButton({
    required this.project,
    required this.isBusy,
    required this.onCommand,
  });

  @override
  State<_ToolMenuButton> createState() => _ToolMenuButtonState();
}

class _ToolMenuButtonState extends State<_ToolMenuButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.project != null && !widget.isBusy;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: isEnabled ? () => _showMenu(context) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          decoration: BoxDecoration(
            color: _isHovering && isEnabled
                ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05))
                : Colors.transparent,
            borderRadius: const BorderRadius.all(
              Radius.circular(MacOSTheme.radiusSmall),
            ),
            border: Border.all(
              color: MacOSTheme.borderMedium,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                size: 16,
                color: MacOSTheme.textSecondary.withOpacity(isEnabled ? 1.0 : 0.4),
              ),
              const SizedBox(width: MacOSTheme.paddingXS),
              Text(
                '工具',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  fontWeight: MacOSTheme.weightMedium,
                  color: MacOSTheme.textSecondary.withOpacity(isEnabled ? 1.0 : 0.4),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: MacOSTheme.textSecondary.withOpacity(isEnabled ? 1.0 : 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 40, 0, 0),
      items: [
        PopupMenuItem(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cleaning_services_rounded, size: 18),
            title: Text(
              'Flutter Clean',
              style: TextStyle(fontSize: MacOSTheme.fontSizeFootnote),
            ),
          ),
          onTap: () => widget.onCommand(ToolCommand.clean),
        ),
        PopupMenuItem(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_rounded, size: 18),
            title: Text(
              'Flutter Pub Get',
              style: TextStyle(fontSize: MacOSTheme.fontSizeFootnote),
            ),
          ),
          onTap: () => widget.onCommand(ToolCommand.pubGet),
        ),
        PopupMenuItem(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.system_update_alt_rounded, size: 18),
            title: Text(
              'Flutter Pub Upgrade',
              style: TextStyle(fontSize: MacOSTheme.fontSizeFootnote),
            ),
          ),
          onTap: () => widget.onCommand(ToolCommand.pubUpgrade),
        ),
        PopupMenuItem(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded, size: 18),
            title: Text(
              'Flutter Pub Outdated',
              style: TextStyle(fontSize: MacOSTheme.fontSizeFootnote),
            ),
          ),
          onTap: () => widget.onCommand(ToolCommand.pubOutdated),
        ),
      ],
    );
  }
}
