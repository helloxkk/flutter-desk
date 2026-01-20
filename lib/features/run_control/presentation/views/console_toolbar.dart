import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';
import 'package:flutter_desk/bootstrap/providers/theme_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel.dart';
import 'package:flutter_desk/features/run_control/presentation/widgets/status_toolbar.dart';
import 'package:flutter_desk/features/run_control/presentation/widgets/action_button_group.dart';
import 'package:flutter_desk/shared/presentation/widgets/macos_search_field.dart';
import 'package:flutter_desk/shared/presentation/widgets/quick_action_buttons.dart';

/// Console-style toolbar with title, actions, and search
///
/// macOS Console app inspired design with three zones:
/// - Left: Title and status
/// - Center: Action buttons
/// - Right: Search field
class ConsoleToolbar extends StatelessWidget {
  const ConsoleToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left zone: Title and status
          const StatusToolbar(),
          const SizedBox(width: 24),

          // Center zone: Action buttons
          const Expanded(child: ActionButtonGroup()),

          const SizedBox(width: 8),

          // Quick action buttons: Build and CodeGen
          const QuickActionButtons(),

          const SizedBox(width: 16),

          // Right zone: Search and theme toggle
          const _RightZone(),
        ],
      ),
    );
  }
}

/// Right zone with search and theme toggle
class _RightZone extends StatelessWidget {
  const _RightZone();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SearchWrapper(),
        SizedBox(width: 12),
        _ThemeToggleButton(),
      ],
    );
  }
}

/// Search field wrapper
class _SearchWrapper extends StatelessWidget {
  const _SearchWrapper();

  @override
  Widget build(BuildContext context) {
    return MacOSSearchField(
      hintText: '搜索日志...',
      onChanged: (value) {
        context.read<CommandViewModel>().setSearchKeyword(value);
      },
    );
  }
}

/// Theme toggle button
class _ThemeToggleButton extends StatefulWidget {
  const _ThemeToggleButton();

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final colors = MacOSTheme.of(context);
    final isDark = themeVM.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => themeVM.toggleTheme(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovering ? colors.hoverColor : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 16,
            color: colors.iconColor,
          ),
        ),
      ),
    );
  }
}
