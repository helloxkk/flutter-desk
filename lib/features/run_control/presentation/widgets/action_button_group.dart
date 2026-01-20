import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/shared/presentation/widgets/compact_icon_button.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';
import 'package:flutter_desk/shared/models/flutter_device.dart';

/// Action button group for run control
///
/// A row of compact action buttons for:
/// - Run (green)
/// - Hot reload (yellow)
/// - Hot restart (blue)
/// - Stop (red)
/// - Clear logs
class ActionButtonGroup extends StatelessWidget {
  /// Callback for run button
  final Future<void> Function(FlutterProject project, dynamic device)? onRun;

  /// Callback for hot reload button
  final Future<void> Function()? onHotReload;

  /// Callback for hot restart button
  final Future<void> Function()? onHotRestart;

  /// Callback for stop button
  final Future<void> Function()? onStop;

  /// Callback for clear button
  final void Function()? onClear;

  const ActionButtonGroup({
    super.key,
    this.onRun,
    this.onHotReload,
    this.onHotRestart,
    this.onStop,
    this.onClear,
  });

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
            CompactIconButton(
              icon: Icons.play_arrow_rounded,
              tooltip: '开始',
              isEnabled: canRun,
              color: const Color(0xFF34C759), // Green
              onPressed: () => _handleRun(context, projectVm.selectedProject!, deviceVm.selectedDevice!),
            ),
            const SizedBox(width: 2),
            CompactIconButton(
              icon: Icons.bolt_rounded,
              tooltip: '热重载',
              isEnabled: canOperate,
              color: const Color(0xFFFFCC00), // Yellow
              onPressed: () => _handleAction(context, onHotReload),
            ),
            const SizedBox(width: 2),
            CompactIconButton(
              icon: Icons.refresh_rounded,
              tooltip: '热重启',
              isEnabled: canOperate,
              color: const Color(0xFF007AFF), // Blue
              onPressed: () => _handleAction(context, onHotRestart),
            ),
            const SizedBox(width: 2),
            CompactIconButton(
              icon: Icons.stop_rounded,
              tooltip: '停止',
              isEnabled: isRunning,
              isDestructive: true, // Red
              onPressed: () => _handleAction(context, onStop),
            ),
            const SizedBox(width: 2),
            CompactIconButton(
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

  Future<void> _handleRun(BuildContext context, FlutterProject project, dynamic device) async {
    if (onRun != null) {
      try {
        await onRun!(project, device);
      } catch (e) {
        if (context.mounted) {
          _showError(context, e.toString());
        }
      }
    } else {
      final commandVm = context.read<CommandViewModel>();
      try {
        await commandVm.run(project, device);
      } catch (e) {
        if (context.mounted) {
          _showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleAction(BuildContext context, Future<void> Function()? action) async {
    if (action != null) {
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          _showError(context, e.toString());
        }
      }
    }
  }

  void _handleClear(BuildContext context) {
    if (onClear != null) {
      onClear!();
    } else {
      context.read<CommandViewModel>().clearLogs();
    }
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
