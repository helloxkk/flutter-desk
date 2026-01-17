import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';

/// macOS-style segmented control for log filtering
///
/// Two segments: "所有信息" (All Logs) and "错误和故障" (Errors Only)
class SegmentedFilter extends StatelessWidget {
  const SegmentedFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Consumer<CommandViewModel>(
        builder: (context, viewModel, _) {
          final filter = viewModel.logFilter;
          final showAll = filter == LogFilter.all;

          return Row(
            children: [
              // Segmented control
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _SegmentButton(
                      label: '所有信息',
                      isSelected: showAll,
                      onPressed: () => viewModel.setLogFilter(LogFilter.all),
                    ),
                    _SegmentButton(
                      label: '错误和故障',
                      isSelected: !showAll,
                      onPressed: () => viewModel.setLogFilter(LogFilter.errors),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Log count indicator
              _LogCountIndicator(
                count: viewModel.logs.length,
                filteredCount: viewModel.filteredLogCount,
                hasFilter: filter != LogFilter.all || viewModel.searchKeyword.isNotEmpty,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Segment button
class _SegmentButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.cardBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeCaption2,
              fontWeight: widget.isSelected
                  ? MacOSTheme.weightMedium
                  : MacOSTheme.weightRegular,
              color: widget.isSelected
                  ? colors.textPrimary
                  : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Log count indicator
class _LogCountIndicator extends StatelessWidget {
  final int count;
  final int filteredCount;
  final bool hasFilter;

  const _LogCountIndicator({
    required this.count,
    required this.filteredCount,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    final displayCount = hasFilter ? filteredCount : count;
    final text = hasFilter
        ? '$filteredCount / $count 条'
        : '$count 条';

    return Text(
      text,
      style: TextStyle(
        fontSize: MacOSTheme.fontSizeCaption2,
        color: hasFilter
            ? MacOSTheme.systemBlue
            : colors.textSecondary,
      ),
    );
  }
}
