import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/theme/macos_theme.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/models/flutter_device.dart';

/// 设备选择器 - macOS Native Design
class DeviceSelector extends StatelessWidget {
  const DeviceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const _LoadingState();
        }

        if (viewModel.error != null) {
          return _ErrorState(
            error: viewModel.error!,
            onRetry: () => viewModel.refreshDevices(forceRefresh: true),
          );
        }

        if (!viewModel.hasDevices) {
          return _EmptyState(
            onRefresh: () => viewModel.refreshDevices(forceRefresh: true),
          );
        }

        return _DeviceSelectorRow(
          devices: viewModel.devices,
          selectedDevice: viewModel.selectedDevice,
          onDeviceSelected: viewModel.selectDevice,
          onRefresh: () => viewModel.refreshDevices(forceRefresh: true),
        );
      },
    );
  }
}

/// Loading state
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

/// Empty state
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.devices_other_outlined,
          size: 18,
          color: MacOSTheme.systemGray,
        ),
        const SizedBox(width: MacOSTheme.paddingM),
        const Expanded(
          child: Text(
            '未检测到设备，请连接设备或刷新',
            style: TextStyle(
              fontSize: MacOSTheme.fontSizeFootnote,
              color: MacOSTheme.textSecondary,
            ),
          ),
        ),
        _IconButton(
          icon: Icons.refresh_outlined,
          onPressed: onRefresh,
          tooltip: '刷新',
        ),
      ],
    );
  }
}

/// Device selector row
class _DeviceSelectorRow extends StatelessWidget {
  final List<FlutterDevice> devices;
  final FlutterDevice? selectedDevice;
  final Function(FlutterDevice) onDeviceSelected;
  final VoidCallback onRefresh;

  const _DeviceSelectorRow({
    required this.devices,
    required this.selectedDevice,
    required this.onDeviceSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          '设备',
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
              child: _DeviceDropdownButton(
                devices: devices,
                selectedDevice: selectedDevice,
                onDeviceSelected: onDeviceSelected,
              ),
            ),
            const SizedBox(width: MacOSTheme.paddingS),
            _IconButton(
              icon: Icons.refresh_outlined,
              onPressed: onRefresh,
              tooltip: '刷新',
            ),
          ],
        ),

        // Device count
        if (devices.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: MacOSTheme.paddingS),
            child: Text(
              '共 ${devices.length} 个设备',
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

/// Device dropdown button
class _DeviceDropdownButton extends StatelessWidget {
  final List<FlutterDevice> devices;
  final FlutterDevice? selectedDevice;
  final Function(FlutterDevice) onDeviceSelected;

  const _DeviceDropdownButton({
    required this.devices,
    required this.selectedDevice,
    required this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group devices by type
    final desktopDevices = devices.where((d) => d.type == DeviceType.desktop).toList();
    final physicalDevices = devices.where((d) => d.type == DeviceType.physical).toList();
    final emulators = devices.where((d) => d.type == DeviceType.emulator).toList();

    return PopupMenuButton<FlutterDevice>(
      initialValue: selectedDevice,
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
      onSelected: onDeviceSelected,
      itemBuilder: (context) {
        final items = <PopupMenuEntry<FlutterDevice>>[];

        // Desktop devices
        if (desktopDevices.isNotEmpty) {
          if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 1));
          items.add(_buildSectionHeader('桌面'));
          for (final device in desktopDevices) {
            items.add(_buildDeviceMenuItem(device));
          }
        }

        // Physical devices
        if (physicalDevices.isNotEmpty) {
          if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 1));
          items.add(_buildSectionHeader('物理设备'));
          for (final device in physicalDevices) {
            items.add(_buildDeviceMenuItem(device));
          }
        }

        // Emulators
        if (emulators.isNotEmpty) {
          if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 1));
          items.add(_buildSectionHeader('模拟器'));
          for (final device in emulators) {
            items.add(_buildDeviceMenuItem(device));
          }
        }

        return items;
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
            if (selectedDevice != null) ...[
              Text(
                selectedDevice!.platformIcon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: MacOSTheme.paddingS),
            ],
            Expanded(
              child: Text(
                selectedDevice?.name ?? '请选择设备',
                style: TextStyle(
                  fontSize: MacOSTheme.fontSizeFootnote,
                  color: selectedDevice != null
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

  PopupMenuEntry<FlutterDevice> _buildSectionHeader(String title) {
    return PopupMenuItem<FlutterDevice>(
      enabled: false,
      padding: const EdgeInsets.symmetric(
        horizontal: MacOSTheme.paddingM,
        vertical: MacOSTheme.paddingXS,
      ),
      height: 28,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: MacOSTheme.fontSizeCaption1,
          fontWeight: MacOSTheme.weightSemibold,
          color: MacOSTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  PopupMenuItem<FlutterDevice> _buildDeviceMenuItem(FlutterDevice device) {
    final isSelected = selectedDevice?.id == device.id;
    return PopupMenuItem<FlutterDevice>(
      value: device,
      padding: EdgeInsets.zero,
      height: 56,
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
            Text(
              device.platformIcon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: MacOSTheme.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    device.name,
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
                    device.id,
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
  }
}

/// macOS-style icon button
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
