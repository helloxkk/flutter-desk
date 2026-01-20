import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/core/utils/constants.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';

/// Dialog for running build_runner commands
///
/// macOS native design with:
/// - Visual card-based command buttons
/// - Clear visual hierarchy
/// - Proper spacing and typography
class CodeGenDialog extends StatefulWidget {
  final String projectPath;

  const CodeGenDialog({
    super.key,
    required this.projectPath,
  });

  @override
  State<CodeGenDialog> createState() => _CodeGenDialogState();
}

class _CodeGenDialogState extends State<CodeGenDialog> {
  bool _isRunning = false;

  Future<void> _runCommand(BuildRunnerCommand command) async {
    setState(() => _isRunning = true);

    try {
      final commandVm = context.read<CommandViewModel>();
      await commandVm.runBuildRunner(
        widget.projectPath,
        command: command,
        deleteConflictingOutputs: true,
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess(_getCommandMessage(command));
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: MacOSTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
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

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MacOSTheme.systemBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
            ),
            child: Icon(
              Icons.code_rounded,
              size: 18,
              color: MacOSTheme.systemBlue,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '代码生成',
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeTitle3,
              fontWeight: MacOSTheme.weightSemibold,
              color: MacOSTheme.textPrimary,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.only(
        left: MacOSTheme.paddingXL,
        right: MacOSTheme.paddingXL,
        top: MacOSTheme.paddingM,
        bottom: MacOSTheme.paddingL,
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Command buttons section
            Text(
              'build_runner',
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeFootnote,
                fontWeight: MacOSTheme.weightMedium,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: MacOSTheme.paddingM),

            // Command buttons
            Row(
              children: [
                Expanded(
                  child: _CommandButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Build',
                    description: '生成代码',
                    isPrimary: true,
                    isRunning: _isRunning,
                    onPressed: () => _runCommand(BuildRunnerCommand.build),
                  ),
                ),
                const SizedBox(width: MacOSTheme.paddingM),
                Expanded(
                  child: _CommandButton(
                    icon: Icons.cleaning_services_rounded,
                    label: 'Clean',
                    description: '清理生成',
                    isRunning: _isRunning,
                    onPressed: () => _runCommand(BuildRunnerCommand.clean),
                  ),
                ),
                const SizedBox(width: MacOSTheme.paddingM),
                Expanded(
                  child: _CommandButton(
                    icon: Icons.remove_red_eye_rounded,
                    label: 'Watch',
                    description: '监听变化',
                    isRunning: _isRunning,
                    onPressed: () => _runCommand(BuildRunnerCommand.watch),
                  ),
                ),
              ],
            ),

            const SizedBox(height: MacOSTheme.paddingL),

            // Info box
            Container(
              padding: const EdgeInsets.all(MacOSTheme.paddingM),
              decoration: BoxDecoration(
                color: MacOSTheme.systemBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(MacOSTheme.radiusMedium),
                border: Border.all(
                  color: MacOSTheme.systemBlue.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: MacOSTheme.systemBlue,
                  ),
                  const SizedBox(width: MacOSTheme.paddingS),
                  Expanded(
                    child: Text(
                      'build_runner 用于生成 JSON 序列化代码、路由代码等。\n'
                      'Build 命令会使用 --delete-conflicting-outputs 参数自动解决冲突。',
                      style: TextStyle(
                        fontSize: MacOSTheme.fontSizeCaption2,
                        color: colors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRunning ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              fontWeight: MacOSTheme.weightMedium,
            ),
          ),
          child: const Text('取消'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        MacOSTheme.paddingXL,
        MacOSTheme.paddingM,
        MacOSTheme.paddingXL,
        MacOSTheme.paddingL,
      ),
    );
  }
}

/// Command action button
class _CommandButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isPrimary;
  final bool isRunning;
  final VoidCallback onPressed;

  const _CommandButton({
    required this.icon,
    required this.label,
    required this.description,
    this.isPrimary = false,
    this.isRunning = false,
    required this.onPressed,
  });

  @override
  State<_CommandButton> createState() => _CommandButtonState();
}

class _CommandButtonState extends State<_CommandButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final bool isEnabled = !widget.isRunning;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (widget.isPrimary) {
      if (_isPressed) {
        bgColor = MacOSTheme.systemBlue.withValues(alpha: 0.8);
      } else if (_isHovering) {
        bgColor = const Color(0xFF0066CC);
      } else {
        bgColor = MacOSTheme.systemBlue;
      }
      fgColor = Colors.white;
      borderColor = Colors.transparent;
    } else {
      if (_isPressed) {
        bgColor = colors.hoverColor;
      } else if (_isHovering) {
        bgColor = colors.hoverColor;
      } else {
        bgColor = colors.buttonBackground;
      }
      fgColor = colors.textPrimary;
      borderColor = colors.border;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isEnabled ? 1.0 : 0.4,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(MacOSTheme.paddingM),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(MacOSTheme.radiusMedium),
              border: Border.all(
                color: borderColor,
                width: 0.5,
              ),
              boxShadow: _isHovering && widget.isPrimary
                  ? [
                      BoxShadow(
                        color: MacOSTheme.systemBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: fgColor,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeFootnote,
                    fontWeight:
                        widget.isPrimary ? MacOSTheme.weightSemibold : MacOSTheme.weightMedium,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightRegular,
                    color: colors.textSecondary,
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
