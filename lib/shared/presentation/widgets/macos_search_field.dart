import 'package:flutter/material.dart';
import 'package:flutter_desk/core/theme/macos_theme.dart';

/// macOS-style search field
///
/// A rounded search input field with:
/// - Search icon prefix
/// - Clear button that appears when text is entered
/// - Rounded corners (macOS style)
/// - Consistent styling across the app
class MacOSSearchField extends StatefulWidget {
  /// Placeholder text shown when field is empty
  final String hintText;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when clear button is tapped
  final VoidCallback? onClear;

  /// Initial text value
  final String? initialValue;

  /// Width of the search field (default 160)
  final double? width;

  const MacOSSearchField({
    super.key,
    this.hintText = '搜索...',
    this.onChanged,
    this.onClear,
    this.initialValue,
    this.width,
  });

  @override
  State<MacOSSearchField> createState() => _MacOSSearchFieldState();
}

class _MacOSSearchFieldState extends State<MacOSSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    // 移除 FocusNode listener，避免循环依赖
  }

  @override
  void didUpdateWidget(MacOSSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = MacOSTheme.of(context);

    return Container(
      width: widget.width ?? 160,
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: MacOSTheme.fontSizeCaption2,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: MacOSTheme.fontSizeCaption2,
            color: colors.textSecondary,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Icon(
              Icons.search,
              size: 14,
              color: colors.iconColor,
            ),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: _handleClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 14,
                )
              : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          widget.onChanged?.call(value);
          setState(() {});
        },
      ),
    );
  }
}
