import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/core/utils/constants.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';

/// Dialog for running build_runner commands
///
/// macOS native dialog design:
/// - Clean title without icon background
/// - Card-based command buttons
/// - Info section with light blue background
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
  BuildRunnerCommand? _runningCommand;

  Future<void> _runCommand(BuildRunnerCommand command) async {
    setState(() {
      _isRunning = true;
      _runningCommand = command;
    });

    try {
      final commandVm = context.read<CommandViewModel>();
      await commandVm.runBuildRunner(
        widget.projectPath,
        command: command,
        deleteConflictingOutputs: true,
      );

      if (mounted) {
        // Watch 命令保持弹窗打开，其他命令关闭弹窗
        if (command != BuildRunnerCommand.watch) {
          Navigator.of(context).pop();
          _showSuccess(_getCommandMessage(command));
        } else {
          setState(() {
            _isRunning = false;
            _runningCommand = null;
          });
          _showSuccess('代码监听已启动，日志显示在主界面');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _runningCommand = null;
        });
        _showError(e.toString());
      }
    }
  }

  // 取消正在运行的命令
  Future<void> _cancelRunningCommand() async {
    final commandVm = context.read<CommandViewModel>();
    await commandVm.stopLongRunningProcess();
    setState(() {
      _isRunning = false;
      _runningCommand = null;
    });
  }

  void _showError(String error) {
    _showMacOSNotification(
      context,
      icon: Icons.error_outline,
      title: '错误',
      message: error,
      isError: true,
    );
  }

  void _showSuccess(String message) {
    _showMacOSNotification(
      context,
      icon: Icons.check_circle_outline,
      title: '成功',
      message: message,
    );
  }

  void _showMacOSNotification(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _MacOSBanner(
        icon: icon,
        title: title,
        message: message,
        isError: isError,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 3秒后自动消失
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
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

  String _getCommandLabel(BuildRunnerCommand? command) {
    if (command == null) return '';
    switch (command) {
      case BuildRunnerCommand.build:
        return '构建';
      case BuildRunnerCommand.clean:
        return '清理';
      case BuildRunnerCommand.watch:
        return '监听';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
        decoration: BoxDecoration(
          color: colors.isDark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: colors.isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: MacOSTheme.systemBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.code_rounded,
                      size: 18,
                      color: MacOSTheme.systemBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '代码生成',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'build_runner',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Command buttons
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MacOSActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Build',
                            description: '生成代码',
                            isRunning: _isRunning,
                            onPressed: () => _runCommand(BuildRunnerCommand.build),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MacOSActionButton(
                            icon: Icons.cleaning_services_rounded,
                            label: 'Clean',
                            description: '清理生成',
                            isRunning: _isRunning,
                            onPressed: () => _runCommand(BuildRunnerCommand.clean),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MacOSActionButton(
                            icon: Icons.remove_red_eye_rounded,
                            label: 'Watch',
                            description: '监听变化',
                            isRunning: _isRunning,
                            onPressed: () => _runCommand(BuildRunnerCommand.watch),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Info text
                  Text(
                    'build_runner 用于生成 JSON 序列化代码、路由代码等。Build 命令会自动解决冲突。',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isRunning && _runningCommand != null)
                    _MacOSButton(
                      isSecondary: true,
                      onPressed: _cancelRunningCommand,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('取消${_getCommandLabel(_runningCommand)}'),
                        ],
                      ),
                    )
                  else
                    _MacOSButton(
                      isSecondary: true,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// macOS-style action button for codegen dialog
class _MacOSActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isRunning;
  final VoidCallback onPressed;

  const _MacOSActionButton({
    required this.icon,
    required this.label,
    required this.description,
    this.isRunning = false,
    required this.onPressed,
  });

  @override
  State<_MacOSActionButton> createState() => _MacOSActionButtonState();
}

class _MacOSActionButtonState extends State<_MacOSActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final bool isEnabled = !widget.isRunning;

    return MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovering = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovering = false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 80,
          decoration: BoxDecoration(
            color: _isPressed
                ? MacOSTheme.systemBlue.withValues(alpha: 0.8)
                : _isHovering
                    ? MacOSTheme.systemBlue.withValues(alpha: 0.08)
                    : colors.isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering
                  ? MacOSTheme.systemBlue.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isEnabled ? 1.0 : 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 24,
                  color: _isHovering
                      ? MacOSTheme.systemBlue
                      : colors.textPrimary,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isHovering
                        ? MacOSTheme.systemBlue
                        : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
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

/// macOS-style button for dialog footer
class _MacOSButton extends StatefulWidget {
  final bool isSecondary;
  final VoidCallback? onPressed;
  final Widget child;

  const _MacOSButton({
    this.isSecondary = false,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_MacOSButton> createState() => _MacOSButtonState();
}

class _MacOSButtonState extends State<_MacOSButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final bool isEnabled = widget.onPressed != null;

    return MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovering = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovering = false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovering
                ? MacOSTheme.systemBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovering
                  ? MacOSTheme.systemBlue.withValues(alpha: 0.5)
                  : colors.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD1D1D6),
              width: 1,
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isEnabled
                  ? MacOSTheme.systemBlue
                  : colors.textSecondary.withValues(alpha: 0.5),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}


/// macOS-style center notification
/// Appears in center of screen with fade + scale animation
class _MacOSBanner extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _MacOSBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_MacOSBanner> createState() => _MacOSBannerState();
}

class _MacOSBannerState extends State<_MacOSBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colors.isDark
                    ? const Color(0xFF2C2C2E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 32,
                    color: widget.isError
                        ? MacOSTheme.errorRed
                        : MacOSTheme.successGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
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

