import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/features/project_management/presentation/widgets/project_list_item.dart';
import 'package:flutter_desk/features/device_management/presentation/widgets/device_list_item.dart';
import 'package:flutter_desk/shared/presentation/widgets/status_state.dart';
import 'package:flutter_desk/shared/presentation/widgets/sidebar_card.dart';
import 'package:file_selector/file_selector.dart';

/// Display add project dialog
void showAddProjectDialog(BuildContext context) async {
  final viewModel = context.read<ProjectViewModel>();
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

/// Console-style sidebar with projects and devices sections
///
/// macOS Console app inspired design with two collapsible sections
class ConsoleSidebar extends StatelessWidget {
  const ConsoleSidebar({super.key});

  void _refreshDevices(BuildContext context) {
    context.read<DeviceViewModel>().refreshDevices(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return SidebarCard(
      child: Column(
        children: [
          // Projects section
          Expanded(
            child: _SidebarSection(
              title: '项目',
              child: const _ProjectsSection(),
              onAddAction: () => showAddProjectDialog(context),
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Devices section
          Expanded(
            child: _SidebarSection(
              title: '设备',
              child: const _DevicesSection(),
              onAddAction: () => _refreshDevices(context),
              actionIcon: Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar section with header and content
class _SidebarSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onAddAction;
  final String? actionLabel;
  final IconData? actionIcon;

  const _SidebarSection({
    required this.title,
    required this.child,
    this.onAddAction,
    this.actionLabel,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: MacOSTheme.weightSemibold,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (onAddAction != null)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onAddAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: actionIcon != null
                          ? Icon(
                              actionIcon,
                              size: 14,
                              color: MacOSTheme.systemBlue,
                            )
                          : Text(
                              actionLabel ?? '+',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: MacOSTheme.weightMedium,
                                color: MacOSTheme.systemBlue,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Section content
        Expanded(child: child),
      ],
    );
  }
}

/// Projects section content
class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const LoadingState();
        }

        if (viewModel.error != null) {
          return ErrorState(
            error: viewModel.error!,
            onRetry: viewModel.refresh,
          );
        }

        if (!viewModel.hasProjects) {
          return EmptyState(
            message: '暂无项目',
            actionLabel: '+ 添加',
            onAction: () => showAddProjectDialog(context),
            icon: Icons.folder_off_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: viewModel.projects.length,
          itemBuilder: (context, index) {
            final project = viewModel.projects[index];
            final isSelected = viewModel.selectedProject?.path == project.path;
            return ProjectListItem(
              project: project,
              isSelected: isSelected,
              onTap: () => viewModel.selectProject(project),
            );
          },
        );
      },
    );
  }
}

/// Devices section content
class _DevicesSection extends StatelessWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const LoadingState();
        }

        if (viewModel.error != null) {
          return ErrorState(
            error: viewModel.error!,
            onRetry: () => viewModel.refreshDevices(forceRefresh: true),
          );
        }

        if (!viewModel.hasDevices) {
          return EmptyState(
            message: '未检测到设备',
            actionLabel: '刷新',
            onAction: () => viewModel.refreshDevices(forceRefresh: true),
            icon: Icons.devices_other_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: viewModel.devices.length,
          itemBuilder: (context, index) {
            final device = viewModel.devices[index];
            final isSelected = viewModel.selectedDevice?.id == device.id;
            return DeviceListItem(
              device: device,
              isSelected: isSelected,
              onTap: () => viewModel.selectDevice(device),
            );
          },
        );
      },
    );
  }
}
