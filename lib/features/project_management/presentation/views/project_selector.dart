import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/project_management/presentation/widgets/project_dropdown.dart';
import 'package:flutter_desk/shared/presentation/widgets/status_state.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';

/// Project selector - macOS Native Design (Simplified)
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
          return InlineErrorState(
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
              child: ProjectDropdown(
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
