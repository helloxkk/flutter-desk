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
  final Set<BuildType> _selectedTypes = {BuildType.macos};
  bool _isRelease = true;
  final TextEditingController _extraArgsController = TextEditingController();

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
      title: const Text(
        '构建配置',
        style: TextStyle(
          fontSize: MacOSTheme.fontSizeTitle3,
          fontWeight: MacOSTheme.weightSemibold,
          color: MacOSTheme.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        MacOSTheme.paddingXL,
        MacOSTheme.paddingM,
        MacOSTheme.paddingXL,
        MacOSTheme.paddingL,
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform selection
              Text(
                '平台 (可多选)',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption2,
                  fontWeight: MacOSTheme.weightMedium,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: MacOSTheme.paddingS),
              Container(
                padding: const EdgeInsets.all(MacOSTheme.paddingS),
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
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
              const SizedBox(height: MacOSTheme.paddingL),

              // Build mode
              Text(
                '构建模式',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption2,
                  fontWeight: MacOSTheme.weightMedium,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: MacOSTheme.paddingS),
              AbsorbPointer(
                absorbing: _isBuilding,
                child: Opacity(
                  opacity: _isBuilding ? 0.5 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.secondaryBackground,
                      borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
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
                            borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
                          ),
                        ),
                      ),
                      selected: {_isRelease},
                      onSelectionChanged: _isBuilding
                          ? null
                          : (Set<bool> newSelection) {
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
                ),
              ),
              const SizedBox(height: MacOSTheme.paddingL),

              // Extra args
              Text(
                '额外参数',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeCaption2,
                  fontWeight: MacOSTheme.weightMedium,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: MacOSTheme.paddingS),
              TextField(
                controller: _extraArgsController,
                enabled: !_isBuilding,
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
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
                    borderSide: BorderSide(
                      color: colors.border,
                      width: 0.5,
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
          child: const Text('取消'),
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
              : Text(_primaryButtonText),
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
        bgColor = MacOSTheme.successGreen.withValues(alpha: 0.2);
        borderColor = MacOSTheme.successGreen;
        iconColor = MacOSTheme.successGreen;
        textColor = MacOSTheme.successGreen;
      } else if (widget.status?.status == _DialogBuildStatus.failure) {
        bgColor = MacOSTheme.errorRed.withValues(alpha: 0.2);
        borderColor = MacOSTheme.errorRed;
        iconColor = MacOSTheme.errorRed;
        textColor = MacOSTheme.errorRed;
      } else {
        bgColor = MacOSTheme.systemBlue;
        borderColor = MacOSTheme.systemBlue;
        iconColor = Colors.white;
        textColor = Colors.white;
      }
    } else {
      bgColor = _isHovering ? colors.hoverColor : Colors.transparent;
      borderColor = colors.border;
      iconColor = colors.textSecondary;
      textColor = colors.textPrimary;
    }

    return MouseRegion(
      onEnter: widget.onTap != null ? (_) => setState(() => _isHovering = true) : null,
      onExit: widget.onTap != null ? (_) => setState(() => _isHovering = false) : null,
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
              if (widget.status?.status == _DialogBuildStatus.success)
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: MacOSTheme.successGreen,
                )
              else if (widget.status?.status == _DialogBuildStatus.failure)
                Icon(
                  Icons.error,
                  size: 14,
                  color: MacOSTheme.errorRed,
                )
              else if (widget.status?.status == _DialogBuildStatus.building)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(MacOSTheme.systemBlue),
                  ),
                )
              else
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
              if (widget.status?.status == _DialogBuildStatus.building) ...[
                const SizedBox(width: 4),
                Text(
                  '${(widget.status!.calculateProgress() * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    fontWeight: MacOSTheme.weightMedium,
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
            size: 18,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_getLabelForType(widget.platformType)} 构建日志',
              style: const TextStyle(
                fontSize: MacOSTheme.fontSizeTitle3,
                fontWeight: MacOSTheme.weightSemibold,
                color: MacOSTheme.textPrimary,
              ),
            ),
          ),
          if (widget.isBuilding)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(MacOSTheme.systemBlue),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        MacOSTheme.paddingXL,
        MacOSTheme.paddingM,
        MacOSTheme.paddingXL,
        MacOSTheme.paddingL,
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Container(
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(MacOSTheme.radiusSmall),
            border: Border.all(
              color: colors.border,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(MacOSTheme.paddingS),
          child: widget.logs.isEmpty
              ? Center(
                  child: Text(
                    widget.isBuilding ? '等待构建开始...' : '暂无日志',
                    style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: MacOSTheme.fontSizeCaption2,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.logs.length,
                  itemBuilder: (context, index) {
                    return LogLine(log: widget.logs[index]);
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.logs.isEmpty ? null : _copySelectedLog,
          child: const Text('复制最新'),
        ),
        TextButton(
          onPressed: widget.logs.isEmpty ? null : _copyAllLogs,
          child: const Text('全部复制'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
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
