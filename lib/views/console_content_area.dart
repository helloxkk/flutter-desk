import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';

/// Console-style content area for log display
///
/// Terminal-style log viewer with dark background and syntax highlighting
class ConsoleContentArea extends StatefulWidget {
  const ConsoleContentArea({super.key});

  @override
  State<ConsoleContentArea> createState() => _ConsoleContentAreaState();
}

class _ConsoleContentAreaState extends State<ConsoleContentArea> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _autoScroll) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Consumer<CommandViewModel>(
      builder: (context, viewModel, _) {
        final logs = viewModel.filteredLogs;

        // Auto scroll when new logs arrive
        if (logs.isNotEmpty && _autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        return Container(
          color: colors.cardBackground,
          child: logs.isEmpty
              ? _EmptyState(
                  hasFilter: viewModel.logFilter != LogFilter.all ||
                      viewModel.searchKeyword.isNotEmpty,
                )
              : Column(
                  children: [
                    Expanded(
                      child: _LogContent(
                        logs: logs,
                        scrollController: _scrollController,
                      ),
                    ),
                    // Auto-scroll toggle at bottom
                    _AutoScrollToggle(
                      autoScroll: _autoScroll,
                      onToggle: () {
                        setState(() {
                          _autoScroll = !_autoScroll;
                          if (_autoScroll) _scrollToBottom();
                        });
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Empty state when no logs
class _EmptyState extends StatelessWidget {
  final bool hasFilter;

  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.terminal_outlined,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? '没有匹配的日志' : '暂无日志输出',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: MacOSTheme.fontSizeFootnote,
              fontFamily: 'Menlo',
            ),
          ),
        ],
      ),
    );
  }
}

/// Log content display
class _LogContent extends StatelessWidget {
  final List<String> logs;
  final ScrollController scrollController;

  const _LogContent({
    required this.logs,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      color: colors.isDark
          ? const Color(0xFF1C1C1E)  // Dark mode: dark background
          : const Color(0xFFF5F5F7),  // Light mode: light background
      child: SelectionArea(
        child: ListView.builder(
          controller: scrollController,
          itemCount: logs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _LogLine(log: log);
          },
        ),
      ),
    );
  }
}

/// Single log line with syntax highlighting
class _LogLine extends StatelessWidget {
  final String log;

  const _LogLine({required this.log});

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

  Color _getLogColor(String log, macOSColors colors) {
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

/// Auto-scroll toggle button
class _AutoScrollToggle extends StatelessWidget {
  final bool autoScroll;
  final VoidCallback onToggle;

  const _AutoScrollToggle({
    required this.autoScroll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            autoScroll ? Icons.arrow_downward : Icons.arrow_downward_outlined,
            size: 14,
            color: autoScroll ? MacOSTheme.systemBlue : colors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            autoScroll ? '自动滚动：开' : '自动滚动：关',
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeCaption2,
              color: autoScroll ? MacOSTheme.systemBlue : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.hoverColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  autoScroll ? '关闭' : '开启',
                  style: TextStyle(
                    fontSize: MacOSTheme.fontSizeCaption2,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
