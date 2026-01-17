import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/models/command_state.dart';
import 'package:flutter_desk/utils/constants.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';

/// 代码生成面板 - macOS Native Design
class CodegenPanel extends StatelessWidget {
  const CodegenPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectViewModel, CommandViewModel>(
      builder: (context, projectVm, commandVm, child) {
        final project = projectVm.selectedProject;
        final canRun = project != null && !commandVm.state.isBusy;
        final isRunning = commandVm.state.status == ProcessStatus.building;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                const Icon(
                  Icons.code_rounded,
                  size: 18,
                  color: MacOSTheme.textSecondary,
                ),
                const SizedBox(width: MacOSTheme.paddingS),
                Text(
                  '代码生成',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeHeadline,
                    fontWeight: MacOSTheme.weightSemibold,
                    color: MacOSTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isRunning)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RunningIndicator(),
                      const SizedBox(width: MacOSTheme.paddingM),
                      _StopButton(
                        onStop: () async {
                          await commandVm.stopLongRunningProcess();
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: MacOSTheme.paddingM),

            // build_runner 操作按钮
            _CodegenActions(
              isEnabled: canRun,
              onCommand: (command) async {
                if (project == null) return;

                try {
                  await commandVm.runBuildRunner(
                    project.path,
                    command: command,
                    deleteConflictingOutputs: true,
                  );
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

  String _getCommandMessage(BuildRunnerCommand command) {
    switch (command) {
      case BuildRunnerCommand.build:
        return '代码生成完成';
      case BuildRunnerCommand.clean:
        return '代码清理完成';
      case BuildRunnerCommand.watch:
        return '代码监听已启动';
    }
  }
}

/// 代码生成操作按钮组
class _CodegenActions extends StatelessWidget {
  final bool isEnabled;
  final Function(BuildRunnerCommand) onCommand;

  const _CodegenActions({
    required this.isEnabled,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(MacOSTheme.paddingM),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : MacOSTheme.systemGray6,
        borderRadius: const BorderRadius.all(
          Radius.circular(MacOSTheme.radiusMedium),
        ),
        border: Border.all(
          color: MacOSTheme.borderMedium,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'build_runner',
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeCaption1,
              fontWeight: MacOSTheme.weightMedium,
              color: MacOSTheme.textSecondary,
            ),
          ),
          const SizedBox(height: MacOSTheme.paddingM),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: _CodegenActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Build',
                  description: '生成代码',
                  isEnabled: isEnabled,
                  isPrimary: true,
                  onPressed: () => onCommand(BuildRunnerCommand.build),
                ),
              ),
              const SizedBox(width: MacOSTheme.paddingS),
              Expanded(
                child: _CodegenActionButton(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Clean',
                  description: '清理生成',
                  isEnabled: isEnabled,
                  onPressed: () => onCommand(BuildRunnerCommand.clean),
                ),
              ),
              const SizedBox(width: MacOSTheme.paddingS),
              Expanded(
                child: _CodegenActionButton(
                  icon: Icons.remove_red_eye_rounded,
                  label: 'Watch',
                  description: '监听变化',
                  isEnabled: isEnabled,
                  onPressed: () => onCommand(BuildRunnerCommand.watch),
                ),
              ),
            ],
          ),

          const SizedBox(height: MacOSTheme.paddingL),

          // 说明文本
          Container(
            padding: const EdgeInsets.all(MacOSTheme.paddingM),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : Colors.white,
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
              border: Border.all(
                color: MacOSTheme.borderLight,
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: MacOSTheme.systemBlue,
                ),
                const SizedBox(width: MacOSTheme.paddingS),
                Expanded(
                  child: Text(
                    'build_runner 用于生成 JSON 序列化代码、路由代码等。'
                    'Build 命令会使用 --delete-conflicting-outputs 参数自动解决冲突。',
                    style: TextStyle(
                      fontSize: MacOSTheme.fontSizeCaption2,
                      color: MacOSTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 代码生成操作按钮
class _CodegenActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isEnabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _CodegenActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.isEnabled,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  State<_CodegenActionButton> createState() => _CodegenActionButtonState();
}

class _CodegenActionButtonState extends State<_CodegenActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    Color bgColor;
    Color fgColor;

    if (widget.isPrimary) {
      bgColor = MacOSTheme.systemBlue;
      fgColor = Colors.white;
    } else {
      bgColor = isDark
          ? const Color(0xFF2C2C2E)
          : Colors.white;
      fgColor = MacOSTheme.textPrimary;
    }

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(MacOSTheme.paddingM),
            decoration: BoxDecoration(
              color: _isPressed
                  ? bgColor.withOpacity(0.8)
                  : (_isHovering && !widget.isPrimary
                      ? (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05))
                      : bgColor),
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
              border: Border.all(
                color: widget.isPrimary
                    ? Colors.transparent
                    : MacOSTheme.borderMedium,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: fgColor.withOpacity(opacity),
                ),
                const SizedBox(height: MacOSTheme.paddingXS),
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
                const SizedBox(height: 2),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    color: MacOSTheme.textSecondary.withOpacity(opacity * 0.8),
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

/// 运行中指示器
class _RunningIndicator extends StatefulWidget {
  @override
  State<_RunningIndicator> createState() => _RunningIndicatorState();
}

class _RunningIndicatorState extends State<_RunningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  MacOSTheme.systemBlue,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: MacOSTheme.paddingS),
        Text(
          '运行中...',
          style: TextStyle(
            fontSize: MacOSTheme.fontSizeCaption2,
            fontWeight: MacOSTheme.weightMedium,
            color: MacOSTheme.systemBlue,
          ),
        ),
      ],
    );
  }
}

/// 停止按钮
class _StopButton extends StatefulWidget {
  final VoidCallback onStop;

  const _StopButton({
    required this.onStop,
  });

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onStop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: MacOSTheme.paddingM,
            vertical: MacOSTheme.paddingXS,
          ),
          decoration: BoxDecoration(
            color: _isHovering
                ? MacOSTheme.errorRed.withOpacity(0.2)
                : MacOSTheme.errorRed.withOpacity(0.1),
            borderRadius: const BorderRadius.all(
              Radius.circular(MacOSTheme.radiusSmall),
            ),
            border: Border.all(
              color: MacOSTheme.errorRed,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stop_rounded,
                size: 12,
                color: MacOSTheme.errorRed,
              ),
              const SizedBox(width: 4),
              Text(
                '停止',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption2,
                  fontWeight: MacOSTheme.weightMedium,
                  color: MacOSTheme.errorRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

