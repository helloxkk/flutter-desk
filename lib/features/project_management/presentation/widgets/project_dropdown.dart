import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/shared/models/flutter_project.dart';

/// Project dropdown button
///
/// A macOS-style dropdown for selecting a Flutter project.
/// Displays project name with optional icon and expand indicator.
class ProjectDropdown extends StatelessWidget {
  /// List of available projects
  final List<FlutterProject> projects;

  /// Currently selected project
  final FlutterProject? selectedProject;

  /// Callback when a project is selected
  final ValueChanged<FlutterProject> onProjectSelected;

  const ProjectDropdown({
    super.key,
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
