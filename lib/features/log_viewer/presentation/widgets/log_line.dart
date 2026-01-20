import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';

/// Single log line with syntax highlighting
///
/// Displays a log line with terminal-style syntax highlighting.
/// Color coding includes:
/// - Red for errors
/// - Orange for warnings
/// - Blue for info
/// - Green for success messages
/// - Yellow for notes
/// - Gray for bullet points
class LogLine extends StatelessWidget {
  /// The log text to display
  final String log;

  const LogLine({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Text(
      log,
      style: TextStyle(
        fontFamily: 'Menlo',
        fontSize: MacOSTheme.fontSizeCaption2,
        height: 1.5,
        color: _getLogColor(log, colors),
      ),
    );
  }

  Color _getLogColor(String log, MacOSColors colors) {
    final isDark = colors.isDark;

    // Terminal-style syntax highlighting with theme awareness
    if (log.contains('[ERROR]') || log.contains('Error:') || log.contains('error:')) {
      return MacOSTheme.errorRed;
    } else if (log.contains('[WARNING]') || log.contains('Warning:') || log.contains('warning:')) {
      return MacOSTheme.warningOrange;
    } else if (log.contains('[INFO]') || log.contains('info:')) {
      return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    } else if (log.contains('Hot reload') || log.contains('Hot restart')) {
      return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    } else if (log.contains('Flutter run') || log.contains('Running')) {
      return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    } else if (log.contains('Successfully')) {
      return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    } else if (log.contains('Exception') || log.contains('failed')) {
      return MacOSTheme.errorRed;
    } else if (log.contains('Note:')) {
      return const Color(0xFFFBBF24);
    } else if (log.contains('•')) {
      return isDark ? MacOSTheme.systemGray3 : MacOSTheme.systemGray;
    }
    // Default log color - lighter in dark mode, darker in light mode
    return isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
  }
}
