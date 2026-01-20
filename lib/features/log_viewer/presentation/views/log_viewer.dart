import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';

/// 日志查看器 - macOS Terminal Design
class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _autoScroll = true;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
    return Consumer<CommandViewModel>(
      builder: (context, viewModel, child) {
        final logs = viewModel.filteredLogs;
        final error = viewModel.error;
        final filter = viewModel.logFilter;
        final hasFilter = filter != LogFilter.all || viewModel.searchKeyword.isNotEmpty;

        // New logs arrive, auto scroll
        if (logs.isNotEmpty && _autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar
            _LogViewerToolbar(
              logCount: hasFilter
                  ? '${viewModel.filteredLogCount}/${viewModel.logs.length}'
                  : '${viewModel.logs.length}',
              hasFilter: hasFilter,
              currentFilter: filter,
              showSearch: _showSearch,
              autoScroll: _autoScroll,
              searchController: _searchController,
              onFilterChanged: (f) => viewModel.setLogFilter(f),
              onToggleSearch: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    viewModel.setSearchKeyword('');
                  }
                });
              },
              onToggleAutoScroll: () {
                setState(() {
                  _autoScroll = !_autoScroll;
                  if (_autoScroll) _scrollToBottom();
                });
              },
              onClear: () {
                viewModel.clearLogs();
                viewModel.clearFilters();
                _searchController.clear();
              },
              onSearchChanged: (value) {
                viewModel.setSearchKeyword(value);
              },
            ),

            const SizedBox(height: MacOSTheme.paddingM),

            // Error banner
            if (error != null) ...[
              _ErrorBanner(error: error),
              const SizedBox(height: MacOSTheme.paddingM),
            ],

            // Log content area with dark terminal background
            Container(
              padding: const EdgeInsets.all(MacOSTheme.paddingL),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E), // Always dark terminal background
                borderRadius: BorderRadius.all(
                  Radius.circular(MacOSTheme.radiusMedium),
                ),
              ),
              child: SizedBox(
                height: 200, // Minimum height for log viewer
                child: _LogContent(
                  logs: logs,
                  hasFilter: hasFilter,
                  scrollController: _scrollController,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Log viewer toolbar
class _LogViewerToolbar extends StatelessWidget {
  final String logCount;
  final bool hasFilter;
  final LogFilter currentFilter;
  final bool showSearch;
  final bool autoScroll;
  final TextEditingController searchController;
  final Function(LogFilter) onFilterChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onClear;
  final Function(String) onSearchChanged;

  const _LogViewerToolbar({
    required this.logCount,
    required this.hasFilter,
    required this.currentFilter,
    required this.showSearch,
    required this.autoScroll,
    required this.searchController,
    required this.onFilterChanged,
    required this.onToggleSearch,
    required this.onToggleAutoScroll,
    required this.onClear,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: label, count, actions
        Row(
          children: [
            const Text(
              '日志',
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption2,
                fontWeight: MacOSTheme.weightMedium,
                color: MacOSTheme.systemGray3,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            Text(
              '$logCount 条',
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeCaption1,
                color: hasFilter
                    ? MacOSTheme.systemBlue
                    : MacOSTheme.systemGray3,
              ),
            ),
            const Spacer(),
            _ToolbarIconButton(
              icon: currentFilter == LogFilter.all
                  ? Icons.filter_list_outlined
                  : Icons.filter_list,
              isActive: currentFilter != LogFilter.all,
              onPressed: () => _showFilterMenu(context),
              tooltip: '过滤',
            ),
            const SizedBox(width: MacOSTheme.paddingXS),
            _ToolbarIconButton(
              icon: showSearch ? Icons.search : Icons.search_outlined,
              isActive: showSearch,
              onPressed: onToggleSearch,
              tooltip: '搜索',
            ),
            const SizedBox(width: MacOSTheme.paddingXS),
            _ToolbarIconButton(
              icon: autoScroll ? Icons.arrow_downward : Icons.arrow_downward_outlined,
              isActive: autoScroll,
              onPressed: onToggleAutoScroll,
              tooltip: autoScroll ? '自动滚动：开' : '自动滚动：关',
            ),
            const SizedBox(width: MacOSTheme.paddingXS),
            _ToolbarIconButton(
              icon: Icons.delete_outlined,
              isActive: false,
              onPressed: onClear,
              tooltip: '清空日志',
            ),
          ],
        ),

        // Search field
        if (showSearch) ...[
          const SizedBox(height: MacOSTheme.paddingM),
          _SearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      ],
    );
  }

  void _showFilterMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + button.size.height + 4,
      offset.dx + button.size.width,
      offset.dy + button.size.height + 200,
    );

    showMenu<LogFilter>(
      context: context,
      position: position,
      items: [
        _buildMenuItem(LogFilter.all, '全部日志', Icons.list),
        _buildMenuItem(LogFilter.errors, '仅错误', Icons.error, MacOSTheme.errorRed),
        _buildMenuItem(LogFilter.warnings, '仅警告', Icons.warning_amber, MacOSTheme.warningOrange),
        _buildMenuItem(LogFilter.info, '仅信息', Icons.info_outline, MacOSTheme.systemBlue),
        _buildMenuItem(LogFilter.flutter, 'Flutter', Icons.flutter_dash, const Color(0xFF40C4FF)),
      ],
    ).then((selected) {
      if (selected != null) {
        onFilterChanged(selected);
      }
    });
  }

  PopupMenuEntry<LogFilter> _buildMenuItem(
    LogFilter filter,
    String label,
    IconData icon, [
    Color? color,
  ]) {
    final isSelected = currentFilter == filter;
    return PopupMenuItem<LogFilter>(
      value: filter,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MacOSTheme.paddingS,
          vertical: MacOSTheme.paddingXS,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? MacOSTheme.systemGray),
            const SizedBox(width: MacOSTheme.paddingM),
            Text(
              label,
              style: TextStyle(
                fontSize: MacOSTheme.fontSizeFootnote,
                color: isSelected ? (color ?? MacOSTheme.systemBlue) : MacOSTheme.textPrimary,
                fontWeight: isSelected ? MacOSTheme.weightSemibold : MacOSTheme.weightMedium,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: color ?? MacOSTheme.systemBlue,
              ),
          ],
        ),
      ),
    );
  }
}

/// Toolbar icon button
class _ToolbarIconButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToolbarIconButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: const BorderRadius.all(
            Radius.circular(MacOSTheme.radiusSmall - 2),
          ),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovering
                  ? Colors.white.withValues(alpha: 0.1)
                  : (widget.isActive ? MacOSTheme.systemBlue.withValues(alpha: 0.2) : null),
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall - 2),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.isActive
                  ? MacOSTheme.systemBlue
                  : MacOSTheme.systemGray3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Search field
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        border: Border.all(
          color: const Color(0xFF38383A),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: MacOSTheme.fontSizeCaption2,
          color: MacOSTheme.systemGray3,
          fontFamily: 'Menlo',
        ),
        decoration: InputDecoration(
          hintText: '搜索日志...',
          hintStyle: const TextStyle(
            color: MacOSTheme.systemGray3,
            fontSize: MacOSTheme.fontSizeCaption2,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 14,
            color: MacOSTheme.systemGray3,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MacOSTheme.paddingS,
            vertical: MacOSTheme.paddingXS,
          ),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Error banner
class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MacOSTheme.paddingS),
      decoration: BoxDecoration(
        color: MacOSTheme.errorRed.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(
          Radius.circular(MacOSTheme.radiusSmall - 2),
        ),
        border: Border.all(
          color: MacOSTheme.errorRed.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: MacOSTheme.errorRed,
            size: 14,
          ),
          const SizedBox(width: MacOSTheme.paddingS),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: MacOSTheme.errorRed,
                fontSize: MacOSTheme.fontSizeCaption2,
                fontFamily: 'Menlo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Log content
class _LogContent extends StatelessWidget {
  final List<String> logs;
  final bool hasFilter;
  final ScrollController scrollController;

  const _LogContent({
    required this.logs,
    required this.hasFilter,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Text(
          hasFilter ? '没有匹配的日志' : '暂无日志输出',
          style: const TextStyle(
            color: MacOSTheme.systemGray3,
            fontSize: MacOSTheme.fontSizeCaption2,
            fontFamily: 'Menlo',
          ),
        ),
      );
    }

    // 使用 SelectionArea 允许多行选择
    return SelectionArea(
      child: ListView.builder(
        controller: scrollController,
        itemCount: logs.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _LogLine(
            log: log,
            index: index,
          );
        },
      ),
    );
  }
}

/// Log line with syntax highlighting
class _LogLine extends StatelessWidget {
  final String log;
  final int index;

  const _LogLine({
    required this.log,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      log,
      style: TextStyle(
        fontFamily: 'Menlo',
        fontSize: MacOSTheme.fontSizeCaption2,
        height: 1.5,
        color: _getLogColor(log),
      ),
    );
  }

  Color _getLogColor(String log) {
    // Terminal-style syntax highlighting
    if (log.contains('[ERROR]') || log.contains('Error:') || log.contains('error:')) {
      return MacOSTheme.errorRed;
    } else if (log.contains('[WARNING]') || log.contains('Warning:') || log.contains('warning:')) {
      return MacOSTheme.warningOrange;
    } else if (log.contains('[INFO]') || log.contains('info:')) {
      return const Color(0xFF60A5FA);
    } else if (log.contains('Hot reload') || log.contains('Hot restart')) {
      return const Color(0xFF4ADE80);
    } else if (log.contains('Flutter run') || log.contains('Running')) {
      return MacOSTheme.systemBlue;
    } else if (log.contains('Successfully')) {
      return const Color(0xFF4ADE80);
    } else if (log.contains('Exception') || log.contains('failed')) {
      return MacOSTheme.errorRed;
    } else if (log.contains('Note:')) {
      return const Color(0xFFFBBF24);
    } else if (log.contains('•')) {
      return MacOSTheme.systemGray3;
    }
    return const Color(0xFFD1D5DB);
  }
}
