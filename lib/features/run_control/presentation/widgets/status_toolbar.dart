import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/shared/models/command_state.dart';

/// Status toolbar showing app title and process status
///
/// Displays:
/// - App name "FlutterDesk"
/// - Current process status with color-coded text
/// - Log count when idle
class StatusToolbar extends StatelessWidget {
  const StatusToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FlutterDesk',
          style: TextStyle(
            fontSize: MacOSTheme.fontSizeSubheadline,
            fontWeight: MacOSTheme.weightSemibold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Consumer<CommandViewModel>(
          builder: (context, vm, _) {
            final status = vm.state.status;
            String subtitle;
            Color subtitleColor;

            switch (status) {
              case ProcessStatus.idle:
              case ProcessStatus.stopped:
                subtitle = '${vm.logs.length} 条信息';
                subtitleColor = colors.textSecondary;
                break;
              case ProcessStatus.starting:
                subtitle = '启动中...';
                subtitleColor = MacOSTheme.warningOrange;
                break;
              case ProcessStatus.running:
              case ProcessStatus.hotReloading:
              case ProcessStatus.hotRestarting:
                subtitle = '运行中';
                subtitleColor = MacOSTheme.successGreen;
                break;
              case ProcessStatus.building:
                subtitle = '构建中...';
                subtitleColor = MacOSTheme.systemBlue;
                break;
              case ProcessStatus.stopping:
                subtitle = '停止中...';
                subtitleColor = MacOSTheme.warningOrange;
                break;
              case ProcessStatus.error:
                subtitle = '错误';
                subtitleColor = MacOSTheme.errorRed;
                break;
            }

            return Text(
              subtitle,
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption1,
                color: subtitleColor,
              ),
            );
          },
        ),
      ],
    );
  }
}
