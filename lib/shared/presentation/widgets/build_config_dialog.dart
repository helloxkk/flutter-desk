import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/shared/models/build_config.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/features/log_viewer/presentation/widgets/log_line.dart';

/// Build status for a single platform
class _PlatformBuildStatus {
  final BuildType type;
  final _DialogBuildStatus status;
  final double progress;
  final DateTime? startTime;
  final List<String> logs;

  _PlatformBuildStatus({
    required this.type,
    required this.status,
    this.progress = 0.0,
    this.startTime,
    this.logs = const [],
  });

  _PlatformBuildStatus copyWith({
    BuildType? type,
    _DialogBuildStatus? status,
    double? progress,
    DateTime? startTime,
    List<String>? logs,
  }) {
    return _PlatformBuildStatus(
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startTime: startTime ?? this.startTime,
      logs: logs ?? this.logs,
    );
  }

  /// Calculate progress based on elapsed time
  double calculateProgress() {
    if (status != _DialogBuildStatus.building || startTime == null) {
      return progress;
    }

    final elapsed = DateTime.now().difference(startTime!).inSeconds;
    const maxExpectedSeconds = 120;
    final calculated = (elapsed / maxExpectedSeconds).clamp(0.0, 0.95);
    return calculated;
  }
}

/// Overall build status for the dialog
enum _DialogBuildStatus {
  notStarted,
  building,
  success,
  failure,
  partial,
}

/// Dialog for configuring and executing Flutter builds
///
/// macOS native dialog design:
/// - Multi-platform selection and parallel building
/// - Individual log button for each platform
/// - Progress bars for each platform
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
  // Multi-platform selection
  final Set<BuildType> _selectedTypes = {};
  bool _isRelease = true;
  final TextEditingController _extraArgsController = TextEditingController();
  bool _showExtraArgs = false;

  _DialogBuildStatus _overallBuildStatus = _DialogBuildStatus.notStarted;
  final Map<BuildType, _PlatformBuildStatus> _platformStatus = {};
  Timer? _progressTimer;
  Timer? _logCollectionTimer;

  // Track initial log count before building
  int _initialLogCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize log count
    final commandVm = context.read<CommandViewModel>();
    _initialLogCount = commandVm.state.logs.length;
  }

  @override
  void dispose() {
    _extraArgsController.dispose();
    _progressTimer?.cancel();
    _logCollectionTimer?.cancel();
    super.dispose();
  }

  List<String> _parseExtraArgs() {
    final text = _extraArgsController.text.trim();
    if (text.isEmpty) return [];
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final stillBuilding = _platformStatus.values.any(
        (status) => status.status == _DialogBuildStatus.building,
      );

      if (!stillBuilding) {
        timer.cancel();
        return;
      }

      setState(() {
        for (final entry in _platformStatus.entries) {
          if (entry.value.status == _DialogBuildStatus.building) {
            final currentProgress = entry.value.calculateProgress();
            _platformStatus[entry.key] = entry.value.copyWith(
              progress: currentProgress,
            );
          }
        }
      });
    });
  }

  void _startLogCollection() {
    _logCollectionTimer?.cancel();
    _logCollectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final stillBuilding = _platformStatus.values.any(
        (status) => status.status == _DialogBuildStatus.building,
      );

      if (!stillBuilding) {
        timer.cancel();
        return;
      }

      // Collect new logs for all building platforms
      final commandVm = context.read<CommandViewModel>();
      final currentLogs = commandVm.state.logs;

      if (currentLogs.length > _initialLogCount) {
        final newLogs = currentLogs.sublist(_initialLogCount);
        // First, update the initial log count to prevent re-adding the same logs
        _initialLogCount = currentLogs.length;

        // Then distribute new logs to all building platforms
        setState(() {
          for (final entry in _platformStatus.entries) {
            if (entry.value.status == _DialogBuildStatus.building) {
              _platformStatus[entry.key] = entry.value.copyWith(
                logs: [...entry.value.logs, ...newLogs],
              );
            }
          }
        });
      }
    });
  }

  Future<void> _startBuild() async {
    final now = DateTime.now();
    final commandVm = context.read<CommandViewModel>();

    setState(() {
      _overallBuildStatus = _DialogBuildStatus.building;
      _platformStatus.clear();

      for (final type in _selectedTypes) {
        _platformStatus[type] = _PlatformBuildStatus(
          type: type,
          status: _DialogBuildStatus.building,
          progress: 0.0,
          startTime: now,
          logs: [],
        );
      }
    });

    // Reset initial log count for this build
    _initialLogCount = commandVm.state.logs.length;

    _startProgressTimer();
    _startLogCollection();

    // Build platforms sequentially (since FlutterService only supports one build at a time)
    final results = <bool>[];
    for (final type in _selectedTypes) {
      final result = await _buildSinglePlatform(type);
      results.add(result);
    }

    _progressTimer?.cancel();
    _logCollectionTimer?.cancel();

    final successCount = results.where((r) => r == true).length;
    final failureCount = results.where((r) => r == false).length;

    if (mounted) {
      setState(() {
        if (failureCount == 0) {
          _overallBuildStatus = _DialogBuildStatus.success;
        } else if (successCount == 0) {
          _overallBuildStatus = _DialogBuildStatus.failure;
        } else {
          _overallBuildStatus = _DialogBuildStatus.partial;
        }

        for (final type in _selectedTypes) {
          final status = _platformStatus[type];
          if (status != null && status.status == _DialogBuildStatus.building) {
            _platformStatus[type] = status.copyWith(
              status: _overallBuildStatus,
              progress: 1.0,
            );
          }
        }
      });
    }
  }

  Future<bool> _buildSinglePlatform(BuildType type) async {
    final config = BuildConfig(
      type: type,
      isRelease: _isRelease,
      extraArgs: _parseExtraArgs(),
    );

    try {
      final commandVm = context.read<CommandViewModel>();
      await commandVm.build(widget.projectPath, config);

      if (mounted) {
        setState(() {
          final status = _platformStatus[type];
          if (status != null) {
            _platformStatus[type] = status.copyWith(
              status: _DialogBuildStatus.success,
              progress: 1.0,
            );
          }
        });
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          final status = _platformStatus[type];
          if (status != null) {
            _platformStatus[type] = status.copyWith(
              status: _DialogBuildStatus.failure,
              logs: [...status.logs, '[ERROR] ${e.toString()}'],
            );
          }
        });
      }
      return false;
    }
  }

  void _showPlatformLogs(BuildType type) {
    final status = _platformStatus[type];
    if (status == null) return;

    showDialog(
      context: context,
      builder: (context) => _PlatformLogDialog(
        platformType: type,
        logs: status.logs,
        isBuilding: status.status == _DialogBuildStatus.building,
      ),
    );
  }

  bool get _isBuilding => _overallBuildStatus == _DialogBuildStatus.building;

  String get _primaryButtonText {
    switch (_overallBuildStatus) {
      case _DialogBuildStatus.notStarted:
        return '构建';
      case _DialogBuildStatus.building:
        return '构建中...';
      case _DialogBuildStatus.success:
      case _DialogBuildStatus.partial:
      case _DialogBuildStatus.failure:
        return '关闭';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return AlertDialog(
      title: Text(
        '构建配置',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform selection
              Text(
                '平台',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: MacOSTheme.weightMedium,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              AbsorbPointer(
                absorbing: _isBuilding,
                child: Opacity(
                  opacity: _isBuilding ? 0.5 : 1.0,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: BuildType.values.map((type) {
                      return _PlatformChip(
                        type: type,
                        isSelected: _selectedTypes.contains(type),
                        status: _platformStatus[type],
                        onTap: _isBuilding
                            ? null
                            : () {
                                setState(() {
                                  if (_selectedTypes.contains(type)) {
                                    _selectedTypes.remove(type);
                                  } else {
                                    _selectedTypes.add(type);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Build mode
              Text(
                '构建模式',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: MacOSTheme.weightMedium,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              AbsorbPointer(
                absorbing: _isBuilding,
                child: Opacity(
                  opacity: _isBuilding ? 0.5 : 1.0,
                  child: _MacOSSegmentedControl(
                    selected: _isRelease,
                    onChanged: _isBuilding
                        ? null
                        : (value) {
                            setState(() => _isRelease = value);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Extra args checkbox
              AbsorbPointer(
                absorbing: _isBuilding,
                child: Opacity(
                  opacity: _isBuilding ? 0.5 : 1.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showExtraArgs = !_showExtraArgs);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: _showExtraArgs,
                            onChanged: _isBuilding
                                ? null
                                : (value) {
                                    setState(() => _showExtraArgs = value ?? false);
                                  },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            side: BorderSide(
                              color: colors.border,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '额外参数',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Extra args input field (conditional)
              if (_showExtraArgs) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _extraArgsController,
                  enabled: !_isBuilding,
                  decoration: InputDecoration(
                    hintText: '例如: --no-pub',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                    filled: true,
                    fillColor: colors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: colors.border,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: MacOSTheme.systemBlue,
                        width: 1,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: colors.border,
                        width: 0.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ],

              // Platform build status and progress
              if (_platformStatus.isNotEmpty) ...[
                const SizedBox(height: MacOSTheme.paddingL),
                const Divider(),
                const SizedBox(height: MacOSTheme.paddingL),
                Text(
                  '构建进度',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightMedium,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: MacOSTheme.paddingM),
                ..._platformStatus.entries.map((entry) {
                  return _PlatformBuildCard(
                    status: entry.value,
                    onShowLogs: () => _showPlatformLogs(entry.key),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBuilding ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: MacOSTheme.systemBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: const Size(70, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isBuilding
              ? null
              : (_overallBuildStatus == _DialogBuildStatus.notStarted
                  ? _selectedTypes.isEmpty ? null : _startBuild
                  : () => Navigator.of(context).pop()),
          style: ElevatedButton.styleFrom(
            backgroundColor: MacOSTheme.systemBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            minimumSize: const Size(70, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          child: _isBuilding
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _primaryButtonText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
    );
  }
}

/// Platform selection chip
class _PlatformChip extends StatefulWidget {
  final BuildType type;
  final bool isSelected;
  final _PlatformBuildStatus? status;
  final VoidCallback? onTap;

  const _PlatformChip({
    required this.type,
    required this.isSelected,
    this.status,
    this.onTap,
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
      if (widget.status?.status == _DialogBuildStatus.success) {
        bgColor = MacOSTheme.successGreen.withValues(alpha: 0.15);
        borderColor = MacOSTheme.successGreen;
        iconColor = MacOSTheme.successGreen;
        textColor = MacOSTheme.successGreen;
      } else if (widget.status?.status == _DialogBuildStatus.failure) {
        bgColor = MacOSTheme.errorRed.withValues(alpha: 0.15);
        borderColor = MacOSTheme.errorRed;
        iconColor = MacOSTheme.errorRed;
        textColor = MacOSTheme.errorRed;
      } else {
        bgColor = colors.isDark
            ? MacOSTheme.systemBlue.withValues(alpha: 0.8)
            : MacOSTheme.systemBlue.withValues(alpha: 0.1);
        borderColor = MacOSTheme.systemBlue;
        iconColor = MacOSTheme.systemBlue;
        textColor = MacOSTheme.systemBlue;
      }
    } else {
      bgColor = _isHovering
          ? (colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05))
          : (colors.isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02));
      borderColor = colors.isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08);
      iconColor = colors.textSecondary;
      textColor = colors.textPrimary;
    }

    return MouseRegion(
      onEnter: widget.onTap != null ? (_) => setState(() => _isHovering = true) : null,
      onExit: widget.onTap != null ? (_) => setState(() => _isHovering = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 26,
          constraints: const BoxConstraints(minWidth: 70),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.status?.status == _DialogBuildStatus.success)
                Icon(
                  Icons.check_circle,
                  size: 13,
                  color: MacOSTheme.successGreen,
                )
              else if (widget.status?.status == _DialogBuildStatus.failure)
                Icon(
                  Icons.error,
                  size: 13,
                  color: MacOSTheme.errorRed,
                )
              else if (widget.status?.status == _DialogBuildStatus.building)
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(MacOSTheme.systemBlue),
                  ),
                )
              else
                Icon(
                  _getIconForType(widget.type),
                  size: 14,
                  color: iconColor,
                ),
              const SizedBox(width: 4),
              Text(
                _getLabelForType(widget.type),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (widget.status?.status == _DialogBuildStatus.building) ...[
                const SizedBox(width: 4),
                Text(
                  '${(widget.status!.calculateProgress() * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary,
                  ),
                ),
              ],
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

/// Platform build status card
class _PlatformBuildCard extends StatelessWidget {
  final _PlatformBuildStatus status;
  final VoidCallback onShowLogs;

  const _PlatformBuildCard({
    required this.status,
    required this.onShowLogs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final progress = status.calculateProgress();

    return Container(
      margin: const EdgeInsets.only(bottom: MacOSTheme.paddingM),
      padding: const EdgeInsets.all(MacOSTheme.paddingM),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
        border: Border.all(
          color: colors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status icon
              if (status.status == _DialogBuildStatus.success)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: MacOSTheme.successGreen,
                )
              else if (status.status == _DialogBuildStatus.failure)
                Icon(
                  Icons.error,
                  size: 16,
                  color: MacOSTheme.errorRed,
                )
              else if (status.status == _DialogBuildStatus.building)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MacOSTheme.systemBlue),
                  ),
                )
              else
                Icon(
                  _getIconForType(status.type),
                  size: 16,
                  color: colors.textSecondary,
                ),
              const SizedBox(width: 8),
              // Platform name
              Text(
                _getLabelForType(status.type),
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  fontWeight: MacOSTheme.weightSemibold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              // Progress percentage
              if (status.status == _DialogBuildStatus.building ||
                  status.status == _DialogBuildStatus.success)
                Text(
                  status.status == _DialogBuildStatus.success ? '100%' : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightSemibold,
                    color: status.status == _DialogBuildStatus.success
                        ? MacOSTheme.successGreen
                        : MacOSTheme.systemBlue,
                  ),
                ),
            ],
          ),
          // Progress bar
          if (status.status == _DialogBuildStatus.building ||
              status.status == _DialogBuildStatus.success) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: status.status == _DialogBuildStatus.building
                    ? (progress > 0 ? progress : null)
                    : 1.0,
                backgroundColor: colors.isDark
                    ? colors.secondaryBackground
                    : const Color(0xFFE5E5E5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  status.status == _DialogBuildStatus.failure
                      ? MacOSTheme.errorRed
                      : status.status == _DialogBuildStatus.success
                          ? MacOSTheme.successGreen
                          : MacOSTheme.systemBlue,
                ),
                minHeight: 3,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Log button
          TextButton.icon(
            onPressed: onShowLogs,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: MacOSTheme.paddingS,
                vertical: 4,
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              Icons.terminal,
              size: 14,
              color: colors.textSecondary,
            ),
            label: Text(
              '查看日志',
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption2,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
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

/// Platform-specific log dialog
class _PlatformLogDialog extends StatefulWidget {
  final BuildType platformType;
  final List<String> logs;
  final bool isBuilding;

  const _PlatformLogDialog({
    required this.platformType,
    required this.logs,
    required this.isBuilding,
  });

  @override
  State<_PlatformLogDialog> createState() => _PlatformLogDialogState();
}

class _PlatformLogDialogState extends State<_PlatformLogDialog> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.isBuilding) {
      _startAutoScroll();
    }
  }

  @override
  void didUpdateWidget(_PlatformLogDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBuilding && !oldWidget.isBuilding) {
      _startAutoScroll();
    } else if (!widget.isBuilding) {
      _stopAutoScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stopAutoScroll();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _copyAllLogs() {
    final allLogs = widget.logs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
  }

  void _copySelectedLog() {
    // 复制最后一条日志（或者可以改为复制当前选中的日志）
    if (widget.logs.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.logs.last));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getIconForType(widget.platformType),
            size: 16,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_getLabelForType(widget.platformType)} 构建日志',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (widget.isBuilding)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(MacOSTheme.systemBlue),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      content: SizedBox(
        width: 560,
        height: 360,
        child: Container(
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colors.isDark
                  ? colors.border
                  : const Color(0xFFD1D1D1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: widget.logs.isEmpty
                ? Center(
                    child: Text(
                      widget.isBuilding ? '等待构建开始...' : '暂无日志',
                      style: TextStyle(
                        fontFamily: 'Menlo',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.logs.length,
                    itemBuilder: (context, index) {
                      return LogLine(log: widget.logs[index]);
                    },
                  ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.logs.isEmpty ? null : _copySelectedLog,
          style: TextButton.styleFrom(
            foregroundColor: MacOSTheme.systemBlue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            '复制最新',
            style: TextStyle(fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: widget.logs.isEmpty ? null : _copyAllLogs,
          style: TextButton.styleFrom(
            foregroundColor: MacOSTheme.systemBlue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            '全部复制',
            style: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 4),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: MacOSTheme.systemBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(60, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          child: const Text(
            '关闭',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
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

/// macOS-style segmented control for Debug/Release toggle
class _MacOSSegmentedControl extends StatefulWidget {
  final bool selected;
  final ValueChanged<bool>? onChanged;

  const _MacOSSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_MacOSSegmentedControl> createState() => _MacOSSegmentedControlState();
}

class _MacOSSegmentedControlState extends State<_MacOSSegmentedControl> {
  bool _isHoveringDebug = false;
  bool _isHoveringRelease = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final isEnabled = widget.onChanged != null;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: colors.isDark
            ? const Color(0xFF3A3A3C)
            : const Color(0xFFE9E9EB),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Debug segment
          _SegmentItem(
            label: 'Debug',
            isSelected: !widget.selected,
            isHovering: _isHoveringDebug,
            isEnabled: isEnabled,
            onTap: isEnabled
                ? () {
                    widget.onChanged!(false);
                  }
                : null,
            onHoverChanged: (value) {
              if (isEnabled) {
                setState(() => _isHoveringDebug = value);
              }
            },
          ),
          // Release segment
          _SegmentItem(
            label: 'Release',
            isSelected: widget.selected,
            isHovering: _isHoveringRelease,
            isEnabled: isEnabled,
            onTap: isEnabled
                ? () {
                    widget.onChanged!(true);
                  }
                : null,
            onHoverChanged: (value) {
              if (isEnabled) {
                setState(() => _isHoveringRelease = value);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Individual segment in the macOS segmented control
class _SegmentItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isHovering;
  final bool isEnabled;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHoverChanged;

  const _SegmentItem({
    required this.label,
    required this.isSelected,
    required this.isHovering,
    required this.isEnabled,
    required this.onTap,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.white;
    } else if (isHovering && isEnabled) {
      backgroundColor = colors.isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.4);
    } else {
      backgroundColor = Colors.transparent;
    }

    Color textColor;
    if (isSelected) {
      textColor = const Color(0xFF0A84FF);
    } else {
      textColor = colors.isDark
          ? const Color(0xFF98989D)
          : const Color(0xFF1D1D1F);
    }

    return MouseRegion(
      onEnter: isEnabled ? (_) => onHoverChanged?.call(true) : null,
      onExit: isEnabled ? (_) => onHoverChanged?.call(false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(
            minWidth: 56,
            minHeight: 20,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.0,
              letterSpacing: -0.05,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
