import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/models/flutter_project.dart';

/// 项目选择器 - macOS Native Design (Simplified)
class ProjectSelector extends StatelessWidget {
  const ProjectSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const _LoadingState();
        }

        if (viewModel.error != null) {
          return _ErrorState(
            error: viewModel.error!,
            onRetry: viewModel.refresh,
          );
        }

        if (!viewModel.hasProjects) {
          return _EmptyState(
            onAdd: () => _showAddProjectDialog(context, viewModel),
          );
        }

        return _ProjectSelectorRow(
          projects: viewModel.projects,
          selectedProject: viewModel.selectedProject,
          onProjectSelected: viewModel.selectProject,
          onRefresh: viewModel.refresh,
          onAdd: () => _showAddProjectDialog(context, viewModel),
        );
      },
    );
  }

  void _showAddProjectDialog(BuildContext context, ProjectViewModel viewModel) async {
    try {
      const confirmButtonText = '选择';
      final selectedDirectory = await getDirectoryPath(
        confirmButtonText: confirmButtonText,
        initialDirectory: '/Users/kun/CursorProjects',
      );

      if (selectedDirectory != null && context.mounted) {
        final success = await viewModel.addProject(selectedDirectory);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.error ?? '添加失败'),
              backgroundColor: MacOSTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件夹失败: $e'),
            backgroundColor: MacOSTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(MacOSTheme.systemBlue),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MacOSTheme.paddingM),
      decoration: BoxDecoration(
        color: MacOSTheme.errorRed.withOpacity(0.08),
        borderRadius: const BorderRadius.all(
          Radius.circular(MacOSTheme.radiusSmall),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: MacOSTheme.errorRed,
          ),
          const SizedBox(width: MacOSTheme.paddingM),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: MacOSTheme.fontSizeFootnote,
                color: MacOSTheme.errorRed,
              ),
            ),
          ),
          _IconButton(
            icon: Icons.refresh_outlined,
            onPressed: onRetry,
            tooltip: '重试',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.folder_outlined,
          size: 18,
          color: MacOSTheme.systemGray,
        ),
        const SizedBox(width: MacOSTheme.paddingM),
        const Expanded(
          child: Text(
            '暂无项目，请添加 Flutter 项目',
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              color: MacOSTheme.textSecondary,
            ),
          ),
        ),
        _TextButton(
          label: '添加',
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _ProjectSelectorRow extends StatelessWidget {
  final List<FlutterProject> projects;
  final FlutterProject? selectedProject;
  final Function(FlutterProject) onProjectSelected;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _ProjectSelectorRow({
    required this.projects,
    required this.selectedProject,
    required this.onProjectSelected,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          '项目',
          style: TextStyle(
            fontSize: MacOSTheme.fontSizeCaption2,
            fontWeight: MacOSTheme.weightMedium,
            color: MacOSTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: MacOSTheme.paddingS),

        // Selector row
        Row(
          children: [
            Expanded(
              child: _ProjectDropdownButton(
                projects: projects,
                selectedProject: selectedProject,
                onProjectSelected: onProjectSelected,
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            _IconButton(
              icon: Icons.refresh_outlined,
              onPressed: onRefresh,
              tooltip: '刷新',
            ),
            const SizedBox(width: 2),
            _IconButton(
              icon: Icons.add_outlined,
              onPressed: onAdd,
              tooltip: '添加项目',
            ),
          ],
        ),

        // Project count
        if (projects.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: MacOSTheme.paddingS),
            child: Text(
              '共 ${projects.length} 个项目',
              style: const TextStyle(
                fontSize: MacOSTheme.fontSizeCaption1,
                color: MacOSTheme.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProjectDropdownButton extends StatelessWidget {
  final List<FlutterProject> projects;
  final FlutterProject? selectedProject;
  final Function(FlutterProject) onProjectSelected;

  const _ProjectDropdownButton({
    required this.projects,
    required this.selectedProject,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<FlutterProject>(
      initialValue: selectedProject,
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MacOSTheme.radiusMedium),
        ),
        side: BorderSide(
          color: MacOSTheme.borderLight,
          width: 0.5,
        ),
      ),
      onSelected: onProjectSelected,
      itemBuilder: (context) {
        return projects.map((project) {
          final isSelected = selectedProject?.path == project.path;
          return PopupMenuItem<FlutterProject>(
            value: project,
            padding: EdgeInsets.zero,
            height: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MacOSTheme.paddingM,
                vertical: MacOSTheme.paddingS,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? MacOSTheme.systemBlue.withOpacity(0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.folder : Icons.folder_outlined,
                    size: 16,
                    color: isSelected
                        ? MacOSTheme.systemBlue
                        : MacOSTheme.systemGray,
                  ),
                  const SizedBox(width: MacOSTheme.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          project.name,
                          style: TextStyle(
                            fontSize: MacOSTheme.fontSizeFootnote,
                            fontWeight: isSelected
                                ? MacOSTheme.weightSemibold
                                : MacOSTheme.weightMedium,
                            color: isSelected
                                ? MacOSTheme.systemBlue
                                : MacOSTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.path,
                          style: const TextStyle(
                            fontSize: MacOSTheme.fontSizeCaption1,
                            color: MacOSTheme.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: MacOSTheme.systemBlue,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(
          horizontal: MacOSTheme.paddingM,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : MacOSTheme.systemGray6,
          borderRadius: const BorderRadius.all(
            Radius.circular(MacOSTheme.radiusSmall),
          ),
          border: Border.all(
            color: MacOSTheme.borderMedium,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            if (selectedProject != null) ...[
              Icon(
                Icons.folder,
                size: 16,
                color: MacOSTheme.systemBlue,
              ),
              const SizedBox(width: MacOSTheme.paddingS),
            ],
            Expanded(
              child: Text(
                selectedProject?.name ?? '请选择项目',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  color: selectedProject != null
                      ? MacOSTheme.textPrimary
                      : MacOSTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 16,
              color: MacOSTheme.systemGray,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
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
            Radius.circular(MacOSTheme.radiusSmall),
          ),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _isHovering ? MacOSTheme.systemGray6 : null,
              borderRadius: const BorderRadius.all(
                Radius.circular(MacOSTheme.radiusSmall),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: MacOSTheme.systemGray,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TextButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: MacOSTheme.systemBlue,
        padding: const EdgeInsets.symmetric(
          horizontal: MacOSTheme.paddingM,
          vertical: MacOSTheme.paddingS,
        ),
        minimumSize: const Size(0, 26),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: MacOSTheme.fontSizeFootnote,
          fontWeight: MacOSTheme.weightMedium,
        ),
      ),
      child: Text(label),
    );
  }
}
