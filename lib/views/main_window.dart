import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/theme_viewmodel.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';
import 'package:flutter_desk/views/console_sidebar.dart';
import 'package:flutter_desk/views/console_toolbar.dart';
import 'package:flutter_desk/views/segmented_filter.dart';
import 'package:flutter_desk/views/console_content_area.dart';

/// Main Window - Console-style layout
///
/// Classic three-pane layout: sidebar + toolbar + content area
/// Inspired by macOS Console.app
class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => DeviceViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => CommandViewModel()..initialize()),
      ],
      child: const _MainWindowContent(),
    );
  }
}

class _MainWindowContent extends StatefulWidget {
  const _MainWindowContent();

  @override
  State<_MainWindowContent> createState() => _MainWindowContentState();
}

class _MainWindowContentState extends State<_MainWindowContent> {
  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Scaffold(
      backgroundColor: colors.cardBackground,
      body: Row(
        children: [
          // Left sidebar - Projects and Devices
          const ConsoleSidebar(),

          // Right content area
          Expanded(
            child: Column(
              children: const [
                // Toolbar with title, actions, and search
                ConsoleToolbar(),

                // Segmented filter for logs
                SegmentedFilter(),

                // Log content area
                Expanded(
                  child: ConsoleContentArea(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
