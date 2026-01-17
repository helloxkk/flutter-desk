import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/models/flutter_project.dart';
import 'package:flutter_desk/models/flutter_device.dart';
import 'package:file_selector/file_selector.dart';

/// Console-style sidebar with projects and devices sections
///
/// macOS Console app inspired design with two collapsible sections
class ConsoleSidebar extends StatelessWidget {
  const ConsoleSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    return Container(
      margin: const EdgeInsets.all(12),
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: MacOSTheme.shadowCard,
      ),
      child: const Column(
        children: [
          // Projects section
          Expanded(
            child: _SidebarSection(
              title: '项目',
              child: _ProjectsSection(),
            ),
          ),

          Divider(height: 1, thickness: 0.5),

          // Devices section
          Expanded(
            child: _SidebarSection(
              title: '设备',
              child: _DevicesSection(),
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

  const _SidebarSection({
    required this.title,
    required this.child,
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
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: MacOSTheme.weightSemibold,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
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
          return const _LoadingIndicator();
        }

        if (viewModel.error != null) {
          return _ErrorState(
            error: viewModel.error!,
            onRetry: viewModel.refresh,
          );
        }

        if (!viewModel.hasProjects) {
          return _EmptyProjectsState(
            onAdd: () => _showAddProjectDialog(context),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: viewModel.projects.length,
          itemBuilder: (context, index) {
            final project = viewModel.projects[index];
            final isSelected = viewModel.selectedProject?.path == project.path;
            return _SidebarProjectItem(
              project: project,
              isSelected: isSelected,
              onTap: () => viewModel.selectProject(project),
            );
          },
        );
      },
    );
  }

  void _showAddProjectDialog(BuildContext context) async {
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
}

/// Devices section content
class _DevicesSection extends StatelessWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const _LoadingIndicator();
        }

        if (viewModel.error != null) {
          return _ErrorState(
            error: viewModel.error!,
            onRetry: () => viewModel.refreshDevices(forceRefresh: true),
          );
        }

        if (!viewModel.hasDevices) {
          return _EmptyDevicesState(
            onRefresh: () => viewModel.refreshDevices(forceRefresh: true),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: viewModel.devices.length,
          itemBuilder: (context, index) {
            final device = viewModel.devices[index];
            final isSelected = viewModel.selectedDevice?.id == device.id;
            return _SidebarDeviceItem(
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

/// Loading indicator
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(MacOSTheme.systemBlue),
          ),
        ),
      ),
    );
  }
}

/// Error state
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: MacOSTheme.errorRed,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                '重试',
                style: const TextStyle(
                  fontSize: 11,
                  color: MacOSTheme.systemBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty projects state
class _EmptyProjectsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyProjectsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 24,
              color: colors.iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无项目',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onAdd,
              child: Text(
                '+ 添加',
                style: const TextStyle(
                  fontSize: 11,
                  color: MacOSTheme.systemBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty devices state
class _EmptyDevicesState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyDevicesState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other_outlined,
              size: 24,
              color: colors.iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              '未检测到设备',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Text(
                '刷新',
                style: const TextStyle(
                  fontSize: 11,
                  color: MacOSTheme.systemBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar project item
class _SidebarProjectItem extends StatefulWidget {
  final FlutterProject project;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarProjectItem({
    required this.project,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarProjectItem> createState() => _SidebarProjectItemState();
}

class _SidebarProjectItemState extends State<_SidebarProjectItem> {
  bool _isHovering = false;

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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? MacOSTheme.systemBlue.withOpacity(0.15)
                : (_isHovering ? colors.hoverColor : null),
            borderRadius: BorderRadius.circular(4),
            border: widget.isSelected
                ? Border.all(
                    color: MacOSTheme.systemBlue.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: widget.isSelected
                    ? MacOSTheme.systemBlue
                    : colors.textSecondary,
              ),
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
                        ? MacOSTheme.systemBlue
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

/// Sidebar device item
class _SidebarDeviceItem extends StatefulWidget {
  final FlutterDevice device;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarDeviceItem({
    required this.device,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarDeviceItem> createState() => _SidebarDeviceItemState();
}

class _SidebarDeviceItemState extends State<_SidebarDeviceItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? MacOSTheme.systemBlue.withOpacity(0.15)
                : (_isHovering ? colors.hoverColor : null),
            borderRadius: BorderRadius.circular(4),
            border: widget.isSelected
                ? Border.all(
                    color: MacOSTheme.systemBlue.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Text(
                widget.device.platformIcon,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.device.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? MacOSTheme.weightMedium
                        : MacOSTheme.weightRegular,
                    color: widget.isSelected
                        ? MacOSTheme.systemBlue
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
