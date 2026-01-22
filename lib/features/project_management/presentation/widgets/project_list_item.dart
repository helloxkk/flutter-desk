import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/core/utils/app_icons.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';

/// Sidebar project list item
///
/// A selectable list item displaying a Flutter project with:
/// - Folder icon
/// - Project name
/// - Hover and selection states
/// - Context menu for remove and show in finder
class ProjectListItem extends StatefulWidget {
  /// The project to display
  final FlutterProject project;

  /// Whether this item is selected
  final bool isSelected;

  /// Callback when item is tapped
  final VoidCallback onTap;

  const ProjectListItem({
    super.key,
    required this.project,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ProjectListItem> createState() => _ProjectListItemState();
}

class _ProjectListItemState extends State<ProjectListItem> {
  bool _isHovering = false;

  void _showContextMenu(BuildContext context, TapDownDetails details) async {
    final viewModel = context.read<ProjectViewModel>();
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    // Get global tap position
    final tapPosition = details.globalPosition;

    await showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx,
        tapPosition.dy,
      ),
      items: [
        PopupMenuItem<void>(
          height: 36,
          child: Row(
            children: [
              AppIcons.deleteIcon(size: 16),
              const SizedBox(width: 8),
              Text('移除项目', style: TextStyle(fontSize: 12, color: MacOSTheme.errorRed)),
            ],
          ),
          onTap: () async {
            // Delay execution to allow menu to close
            await Future.delayed(const Duration(milliseconds: 100));
            if (context.mounted) {
              _confirmRemoveProject(context, viewModel);
            }
          },
        ),
        PopupMenuItem<void>(
          height: 36,
          child: Row(
            children: [
              AppIcons.iconWidget(
                AppIcons.folderOpen,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text('在 Finder 中显示', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            ],
          ),
          onTap: () {
            viewModel.openInFinder(widget.project.path);
          },
        ),
      ],
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 8,
    );
  }

  void _confirmRemoveProject(BuildContext context, ProjectViewModel viewModel) {
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '移除项目',
          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: MacOSTheme.weightSemibold),
        ),
        content: Text(
          '确定要从列表中移除 "${widget.project.name}" 吗？\n\n项目文件不会被删除。',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: MacOSTheme.systemBlue, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeProject(widget.project);
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              '移除',
              style: TextStyle(color: MacOSTheme.errorRed, fontSize: 12, fontWeight: MacOSTheme.weightMedium),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) => _showContextMenu(context, details),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F6))
                : (_isHovering ? colors.hoverColor : null),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              AppIcons.folderIcon(context, isSelected: widget.isSelected),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? MacOSTheme.weightMedium
                        : MacOSTheme.weightRegular,
                    color: widget.isSelected
                        ? const Color(0xFF017AFF)
                        : colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
