import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/shared/models/build_config.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';

/// Dialog for configuring and executing Flutter builds
///
/// macOS native design with:
/// - Proper spacing using MacOSTheme padding constants
/// - Typography hierarchy with SF Pro scale
/// - Visual hierarchy with borders and backgrounds
class BuildConfigDialog extends StatefulWidget {
  final String projectPath;

  const BuildConfigDialog({
    super.key,
    required this.projectPath,
  });

  @override
  State<BuildConfigDialog> createState() => _BuildConfigDialogState();
}

class _BuildConfigDialogState extends State<BuildConfigDialog> {
  BuildType _selectedType = BuildType.macos;
  bool _isRelease = true;
  final TextEditingController _extraArgsController = TextEditingController();
  bool _isBuilding = false;

  @override
  void dispose() {
    _extraArgsController.dispose();
    super.dispose();
  }

  BuildConfig get _config => BuildConfig(
        type: _selectedType,
        isRelease: _isRelease,
        extraArgs: _parseExtraArgs(),
      );

  List<String> _parseExtraArgs() {
    final text = _extraArgsController.text.trim();
    if (text.isEmpty) return [];
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _startBuild() async {
    setState(() => _isBuilding = true);

    try {
      final commandVm = context.read<CommandViewModel>();
      await commandVm.build(widget.projectPath, _config);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess('构建完成: ${_config.displayName}');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isBuilding = false);
      }
    }
  }

  Future<void> _openOutput() async {
    try {
      final commandVm = context.read<CommandViewModel>();
      await commandVm.openBuildOutput(widget.projectPath, _config);
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
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
              Icons.build_rounded,
              size: 18,
              color: MacOSTheme.systemBlue,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '构建配置',
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
            // Platform selection section
            _SectionLabel(
              icon: Icons.devices_rounded,
              label: '平台',
              colors: colors,
            ),
            const SizedBox(height: MacOSTheme.paddingM),
            Container(
              padding: const EdgeInsets.all(MacOSTheme.paddingM),
              decoration: BoxDecoration(
                color: colors.secondaryBackground,
                borderRadius: BorderRadius.circular(MacOSTheme.radiusMedium),
                border: Border.all(
                  color: colors.border,
                  width: 0.5,
                ),
              ),
              child: Wrap(
                spacing: MacOSTheme.paddingS,
                runSpacing: MacOSTheme.paddingS,
                children: BuildType.values.map((type) {
                  return _PlatformChip(
                    type: type,
                    isSelected: _selectedType == type,
                    onTap: () => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: MacOSTheme.paddingL),

            // Build mode section
            _SectionLabel(
              icon: Icons.tune_rounded,
              label: '构建模式',
              colors: colors,
            ),
            const SizedBox(height: MacOSTheme.paddingM),
            Container(
              decoration: BoxDecoration(
                color: colors.secondaryBackground,
                borderRadius: BorderRadius.circular(MacOSTheme.radiusMedium),
                border: Border.all(
                  color: colors.border,
                  width: 0.5,
                ),
              ),
              child: SegmentedButton<bool>(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return MacOSTheme.systemBlue;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return colors.textPrimary;
                  }),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      horizontal: MacOSTheme.paddingL,
                      vertical: MacOSTheme.paddingM,
                    ),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MacOSTheme.radiusMedium),
                    ),
                  ),
                ),
                selected: {_isRelease},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() => _isRelease = newSelection.first);
                },
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Debug'),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Release'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MacOSTheme.paddingL),

            // Extra args section
            _SectionLabel(
              icon: Icons.terminal_rounded,
              label: '额外参数',
              colors: colors,
            ),
            const SizedBox(height: MacOSTheme.paddingM),
            TextField(
              controller: _extraArgsController,
              decoration: InputDecoration(
                hintText: '例如: --no-pub',
                hintStyle: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  color: colors.textSecondary,
                ),
                filled: true,
                fillColor: colors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
                  borderSide: BorderSide(
                    color: colors.border,
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
                  borderSide: const BorderSide(
                    color: MacOSTheme.systemBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MacOSTheme.paddingM,
                  vertical: MacOSTheme.paddingS + 2,
                ),
              ),
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeFootnote,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBuilding ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              fontWeight: MacOSTheme.weightMedium,
            ),
          ),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _isBuilding ? null : _openOutput,
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              fontWeight: MacOSTheme.weightMedium,
            ),
          ),
          child: const Text('打开输出'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isBuilding ? null : _startBuild,
          style: ElevatedButton.styleFrom(
            backgroundColor: MacOSTheme.systemBlue,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              fontWeight: MacOSTheme.weightMedium,
            ),
          ),
          child: _isBuilding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('开始构建'),
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

/// Section label with icon
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final MacOSColors colors;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: MacOSTheme.fontSizeFootnote,
            fontWeight: MacOSTheme.weightMedium,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Platform selection chip
class _PlatformChip extends StatefulWidget {
  final BuildType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlatformChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PlatformChip> createState() => _PlatformChipState();
}

class _PlatformChipState extends State<_PlatformChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;

    if (widget.isSelected) {
      bgColor = MacOSTheme.systemBlue;
      borderColor = MacOSTheme.systemBlue;
      iconColor = Colors.white;
      textColor = Colors.white;
    } else {
      bgColor = _isHovering ? colors.hoverColor : Colors.transparent;
      borderColor = colors.border;
      iconColor = colors.textSecondary;
      textColor = colors.textPrimary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: MacOSTheme.paddingM,
            vertical: MacOSTheme.paddingS + 2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForType(widget.type),
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                _getLabelForType(widget.type),
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  fontWeight:
                      widget.isSelected ? MacOSTheme.weightSemibold : MacOSTheme.weightMedium,
                  color: textColor,
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
