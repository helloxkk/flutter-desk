import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/models/flutter_project.dart';
import 'package:flutter_desk/models/flutter_device.dart';
import 'package:file_selector/file_selector.dart';

/// 显示添加项目对话框的辅助函数
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

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 40, bottom: 12),
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: isDark ? colors.border : Colors.white,
          width: 0.5,
        ),
        boxShadow: MacOSTheme.shadowCard,
      ),
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
          const Expanded(
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
  final VoidCallback? onAddAction;

  const _SidebarSection({
    required this.title,
    required this.child,
    this.onAddAction,
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
                      child: Text(
                        '+',
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
            onAdd: () => showAddProjectDialog(context),
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

  void _showContextMenu(BuildContext context, TapDownDetails details) async {
    final viewModel = context.read<ProjectViewModel>();
    final colors = MacOSTheme.of(context);
    final isDark = colors.isDark;

    // 获取鼠标点击的全局位置
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
              const Icon(Icons.delete_outline, size: 16, color: MacOSTheme.errorRed),
              const SizedBox(width: 8),
              Text('移除项目', style: TextStyle(fontSize: 12, color: MacOSTheme.errorRed)),
            ],
          ),
          onTap: () async {
            // 延迟执行，让菜单先关闭
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
              Icon(Icons.folder_open, size: 16, color: colors.textSecondary),
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
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: widget.isSelected
                    ? const Color(0xFF017AFF)
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
                ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F6))
                : (_isHovering ? colors.hoverColor : null),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.device.iconData,
                size: 14,
                color: widget.isSelected
                    ? const Color(0xFF017AFF)
                    : colors.textSecondary,
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
