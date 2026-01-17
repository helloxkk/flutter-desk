import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/models/build_config.dart';
import 'package:flutter_desk/models/command_state.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';

/// 构建面板 - macOS Native Design
class BuildPanel extends StatelessWidget {
  const BuildPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectViewModel, CommandViewModel>(
      builder: (context, projectVm, commandVm, child) {
        final project = projectVm.selectedProject;
        final canBuild = project != null && !commandVm.state.isBusy;
        final isBuilding = commandVm.state.status == ProcessStatus.building;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  Icons.build_rounded,
                  size: 18,
                  color: MacOSTheme.of(context).textSecondary,
                ),
                const SizedBox(width: MacOSTheme.paddingS),
                Text(
                  '构建',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeHeadline,
                    fontWeight: MacOSTheme.weightSemibold,
                    color: MacOSTheme.of(context).textPrimary,
                  ),
                ),
                const Spacer(),
                if (isBuilding)
                  _BuildingIndicator(),
              ],
            ),
            const SizedBox(height: MacOSTheme.paddingM),

            // 构建类型选择
            _BuildTypeSelector(
              isEnabled: canBuild,
              isExecuting: commandVm.isExecuting,
              onBuild: (config) async {
                if (project == null) return;

                try {
                  await commandVm.build(project.path, config);
                  if (context.mounted) {
                    _showSuccess(context, '构建完成: ${config.displayName}');
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showError(context, e.toString());
                  }
                }
              },
              onOpenOutput: (config) async {
                if (project == null) return;

                try {
                  await commandVm.openBuildOutput(project.path, config);
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
}

/// 构建类型选择器
class _BuildTypeSelector extends StatefulWidget {
  final bool isEnabled;
  final bool isExecuting;
  final Function(BuildConfig) onBuild;
  final Function(BuildConfig)? onOpenOutput;

  const _BuildTypeSelector({
    required this.isEnabled,
    required this.onBuild,
    this.isExecuting = false,
    this.onOpenOutput,
  });

  @override
  State<_BuildTypeSelector> createState() => _BuildTypeSelectorState();
}

class _BuildTypeSelectorState extends State<_BuildTypeSelector> {
  BuildType _selectedType = BuildType.apk;
  bool _isRelease = true;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(MacOSTheme.paddingM),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: const BorderRadius.all(
          Radius.circular(MacOSTheme.radiusMedium),
        ),
        border: Border.all(
          color: colors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 平台选择
          Text(
            '平台',
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeCaption1,
              fontWeight: MacOSTheme.weightMedium,
              color: MacOSTheme.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: MacOSTheme.paddingS),

          Wrap(
            spacing: MacOSTheme.paddingS,
            runSpacing: MacOSTheme.paddingS,
            children: BuildType.values.map((type) {
              return _BuildTypeChip(
                type: type,
                isSelected: _selectedType == type,
                isEnabled: widget.isEnabled,
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: MacOSTheme.paddingL),

          // 构建模式选择
          Row(
            children: [
              Text(
                '模式',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption1,
                  fontWeight: MacOSTheme.weightMedium,
                  color: MacOSTheme.of(context).textSecondary,
                ),
              ),
              const SizedBox(width: MacOSTheme.paddingM),
              _ModeToggle(
                label: 'Debug',
                isSelected: !_isRelease,
                isEnabled: widget.isEnabled,
                onTap: () {
                  setState(() {
                    _isRelease = false;
                  });
                },
              ),
              const SizedBox(width: MacOSTheme.paddingS),
              _ModeToggle(
                label: 'Release',
                isSelected: _isRelease,
                isEnabled: widget.isEnabled,
                onTap: () {
                  setState(() {
                    _isRelease = true;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: MacOSTheme.paddingL),

          // 构建按钮和打开输出按钮
          Row(
            children: [
              Expanded(
                child: _BuildButton(
                  config: BuildConfig(
                    type: _selectedType,
                    isRelease: _isRelease,
                  ),
                  isEnabled: widget.isEnabled,
                  onPressed: () {
                    final config = BuildConfig(
                      type: _selectedType,
                      isRelease: _isRelease,
                    );
                    widget.onBuild(config);
                  },
                ),
              ),
              const SizedBox(width: MacOSTheme.paddingS),
              _OpenOutputButton(
                config: BuildConfig(
                  type: _selectedType,
                  isRelease: _isRelease,
                ),
                isEnabled: widget.isEnabled && !widget.isExecuting,
                onPressed: () {
                  final config = BuildConfig(
                    type: _selectedType,
                    isRelease: _isRelease,
                  );
                  widget.onOpenOutput?.call(config);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 构建类型芯片
class _BuildTypeChip extends StatefulWidget {
  final BuildType type;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _BuildTypeChip({
    required this.type,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_BuildTypeChip> createState() => _BuildTypeChipState();
}

class _BuildTypeChipState extends State<_BuildTypeChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    Color bgColor;
    Color fgColor;

    if (widget.isSelected) {
      bgColor = MacOSTheme.systemBlue;
      fgColor = Colors.white;
    } else {
      bgColor = colors.buttonBackground;
      fgColor = colors.textPrimary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: MacOSTheme.paddingM,
            vertical: MacOSTheme.paddingS,
          ),
          decoration: BoxDecoration(
            color: _isHovering && widget.isEnabled && !widget.isSelected
                ? colors.hoverColor
                : bgColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(MacOSTheme.radiusSmall),
            ),
            border: Border.all(
              color: widget.isSelected
                  ? MacOSTheme.systemBlue
                  : colors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForType(widget.type),
                size: 14,
                color: fgColor.withOpacity(opacity),
              ),
              const SizedBox(width: MacOSTheme.paddingXS),
              Text(
                _getLabelForType(widget.type),
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  fontWeight: widget.isSelected
                      ? MacOSTheme.weightSemibold
                      : MacOSTheme.weightMedium,
                  color: fgColor.withOpacity(opacity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(BuildType type) {
    switch (type) {
      case BuildType.apk:
      case BuildType.appBundle:
        return Icons.android_rounded;
      case BuildType.ipa:
        return Icons.phone_iphone_rounded;
      case BuildType.macos:
        return Icons.laptop_mac_rounded;
      case BuildType.windows:
        return Icons.desktop_windows_rounded;
      case BuildType.linux:
        return Icons.computer_rounded;
      case BuildType.web:
        return Icons.language_rounded;
    }
  }

  String _getLabelForType(BuildType type) {
    switch (type) {
      case BuildType.apk:
        return 'APK';
      case BuildType.ipa:
        return 'IPA';
      case BuildType.appBundle:
        return 'Bundle';
      case BuildType.macos:
        return 'macOS';
      case BuildType.windows:
        return 'Windows';
      case BuildType.linux:
        return 'Linux';
      case BuildType.web:
        return 'Web';
    }
  }
}

/// 模式切换按钮
class _ModeToggle extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ModeToggle> createState() => _ModeToggleState();
}

class _ModeToggleState extends State<_ModeToggle> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    Color bgColor;
    Color fgColor;

    if (widget.isSelected) {
      bgColor = MacOSTheme.systemBlue;
      fgColor = Colors.white;
    } else {
      bgColor = colors.buttonBackground;
      fgColor = colors.textPrimary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: MacOSTheme.paddingM,
            vertical: MacOSTheme.paddingXS,
          ),
          decoration: BoxDecoration(
            color: _isHovering && widget.isEnabled && !widget.isSelected
                ? colors.hoverColor
                : bgColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(MacOSTheme.radiusSmall),
            ),
            border: Border.all(
              color: widget.isSelected
                  ? MacOSTheme.systemBlue
                  : colors.border,
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              fontWeight: widget.isSelected
                  ? MacOSTheme.weightSemibold
                  : MacOSTheme.weightMedium,
              color: fgColor.withOpacity(opacity),
            ),
          ),
        ),
      ),
    );
  }
}

/// 构建按钮
class _BuildButton extends StatefulWidget {
  final BuildConfig config;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _BuildButton({
    required this.config,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_BuildButton> createState() => _BuildButtonState();
}

class _BuildButtonState extends State<_BuildButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
            height: 36,
            decoration: BoxDecoration(
              color: _isPressed
                  ? MacOSTheme.systemBlue.withOpacity(0.8)
                  : (_isHovering
                      ? const Color(0xFF0066CC)
                      : MacOSTheme.systemBlue),
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
              boxShadow: _isHovering ? MacOSTheme.shadowCard : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.build_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: MacOSTheme.paddingXS),
                Text(
                  '构建 ${widget.config.displayName}',
                  style: const TextStyle(
                    fontSize: MacOSTheme.fontSizeFootnote,
                    fontWeight: MacOSTheme.weightSemibold,
                    color: Colors.white,
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

/// 构建进行中指示器
class _BuildingIndicator extends StatefulWidget {
  @override
  State<_BuildingIndicator> createState() => _BuildingIndicatorState();
}

class _BuildingIndicatorState extends State<_BuildingIndicator>
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
          '构建中...',
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

/// 打开输出目录按钮
class _OpenOutputButton extends StatefulWidget {
  final BuildConfig config;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _OpenOutputButton({
    required this.config,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_OpenOutputButton> createState() => _OpenOutputButtonState();
}

class _OpenOutputButtonState extends State<_OpenOutputButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = widget.isEnabled ? 1.0 : 0.4;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            decoration: BoxDecoration(
              color: _isHovering && widget.isEnabled
                  ? MacOSTheme.systemBlue.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
              border: Border.all(
                color: MacOSTheme.systemBlue,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 14,
                  color: MacOSTheme.systemBlue.withOpacity(opacity),
                ),
                const SizedBox(width: 4),
                Text(
                  '打开输出',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightMedium,
                    color: MacOSTheme.systemBlue.withOpacity(opacity),
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

