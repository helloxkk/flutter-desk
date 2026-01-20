import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/shared/models/build_config.dart';
import 'package:flutter_desk/shared/models/command_state.dart';
import 'package:flutter_desk/core/utils/constants.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/shared/presentation/widgets/build_config_dialog.dart';
import 'package:flutter_desk/shared/presentation/widgets/codegen_dialog.dart';

// Re-export QuickActionStatus for convenience
export 'package:flutter_desk/core/utils/constants.dart' show QuickActionStatus;

/// Quick action buttons for build and code generation
///
/// Two compact buttons that open dialogs for build and code generation operations.
/// Left click opens the full dialog, right click shows a quick menu.
class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectViewModel, CommandViewModel>(
      builder: (context, projectVm, commandVm, _) {
        final project = projectVm.selectedProject;
        final canBuild = project != null && !commandVm.state.isBusy;
        final isBuilding = commandVm.state.status == ProcessStatus.building;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickActionButton(
              icon: Icons.build_rounded,
              tooltip: '构建',
              isEnabled: canBuild,
              isRunning: isBuilding,
              lastStatus: commandVm.lastBuildStatus,
              onPressed: canBuild
                  ? () => _showBuildDialog(context, project.path)
                  : null,
              onSecondaryTap: canBuild
                  ? () => _showBuildQuickMenu(context, project.path)
                  : null,
            ),
            const SizedBox(width: 2),
            _QuickActionButton(
              icon: Icons.code_rounded,
              tooltip: '代码生成',
              isEnabled: canBuild,
              isRunning: isBuilding,
              lastStatus: commandVm.lastCodeGenStatus,
              onPressed: canBuild
                  ? () => _showCodeGenDialog(context, project.path)
                  : null,
              onSecondaryTap: canBuild
                  ? () => _showCodeGenQuickMenu(context, project.path)
                  : null,
            ),
          ],
        );
      },
    );
  }

  void _showBuildDialog(BuildContext context, String projectPath) {
    showDialog(
      context: context,
      builder: (context) => BuildConfigDialog(projectPath: projectPath),
    );
  }

  void _showBuildQuickMenu(BuildContext context, String projectPath) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy + button.size.height * 2,
      ),
      items: [
        _buildMenuItem(
          context,
          'macOS Debug',
          Icons.laptop_mac,
          projectPath,
          BuildConfig(type: BuildType.macos, isRelease: false),
        ),
        _buildMenuItem(
          context,
          'macOS Release',
          Icons.laptop_mac,
          projectPath,
          BuildConfig(type: BuildType.macos, isRelease: true),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          enabled: false,
          height: 0,
          child: Text(
            '更多配置...',
            style: TextStyle(
              fontSize: 12,
              color: MacOSTheme.of(context).textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<void> _buildMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    String projectPath,
    BuildConfig config,
  ) {
    return PopupMenuItem<void>(
      onTap: () {
        final commandVm = context.read<CommandViewModel>();
        commandVm.build(projectPath, config);
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: MacOSTheme.of(context).iconColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showCodeGenDialog(BuildContext context, String projectPath) {
    showDialog(
      context: context,
      builder: (context) => CodeGenDialog(projectPath: projectPath),
    );
  }

  void _showCodeGenQuickMenu(BuildContext context, String projectPath) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy + button.size.height * 2,
      ),
      items: [
        _codeGenMenuItem(
          context,
          'Build',
          Icons.play_arrow,
          projectPath,
          BuildRunnerCommand.build,
        ),
        _codeGenMenuItem(
          context,
          'Clean',
          Icons.cleaning_services,
          projectPath,
          BuildRunnerCommand.clean,
        ),
        _codeGenMenuItem(
          context,
          'Watch',
          Icons.remove_red_eye,
          projectPath,
          BuildRunnerCommand.watch,
        ),
      ],
    );
  }

  PopupMenuItem<void> _codeGenMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    String projectPath,
    BuildRunnerCommand command,
  ) {
    return PopupMenuItem<void>(
      onTap: () {
        final commandVm = context.read<CommandViewModel>();
        commandVm.runBuildRunner(
          projectPath,
          command: command,
          deleteConflictingOutputs: true,
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: MacOSTheme.of(context).iconColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Single quick action button with status indicator
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final bool isRunning;
  final QuickActionStatus? lastStatus;
  final VoidCallback? onPressed;
  final VoidCallback? onSecondaryTap;

  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    this.isRunning = false,
    this.lastStatus,
    this.onPressed,
    this.onSecondaryTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        onSecondaryTapDown: widget.onSecondaryTap != null
            ? (_) => widget.onSecondaryTap!()
            : null,
        child: Opacity(
          opacity: opacity,
          child: Tooltip(
            message: widget.tooltip,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _isHovering && widget.isEnabled
                    ? colors.hoverColor
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main icon
                  Center(
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                  // Status indicator in corner
                  if (!_isHovering &&
                      widget.lastStatus != null &&
                      widget.lastStatus != QuickActionStatus.none)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _StatusIndicator(status: widget.lastStatus!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status indicator badge
class _StatusIndicator extends StatelessWidget {
  final QuickActionStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case QuickActionStatus.success:
        color = MacOSTheme.successGreen;
        text = '✓';
        break;
      case QuickActionStatus.failure:
        color = MacOSTheme.errorRed;
        text = '✗';
        break;
      case QuickActionStatus.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// QuickActionStatus is now defined in core/utils/constants.dart
