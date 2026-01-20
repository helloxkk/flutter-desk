# Task Plan: Integrate BuildPanel and CodeGenPanel into Main Window

## Goal
Add build and code generation quick action buttons to the console toolbar, providing a streamlined user experience with dialog-based configuration and quick menu shortcuts.

## Phases
- [x] Phase 1: Analyze current codebase structure
- [x] Phase 2: Create QuickActionButtons component with build and codegen buttons
- [x] Phase 3: Create BuildConfigDialog for build configuration
- [x] Phase 4: Create CodeGenDialog for code generation commands
- [x] Phase 5: Integrate QuickActionButtons into ConsoleToolbar
- [x] Phase 6: Test and verify all functionality

## Key Questions
1. Should the buttons show status indicators? Yes - show last result status ✅
2. Left click vs right click? Left = dialog, Right = quick menu ✅
3. What quick presets to show? macOS Debug/Release, and common build_runner commands ✅

## Design Decisions
- **Button style**: Match CompactIconButton design (28x28) ✅
- **Status indicators**: Corner badge for success/fail ✅
- **Dialog approach**: Use AlertDialog with form controls ✅
- **Quick menu**: PopupMenuItem with common presets ✅

## Files Created
- ✅ `lib/shared/presentation/widgets/quick_action_buttons.dart`
- ✅ `lib/shared/presentation/widgets/build_config_dialog.dart`
- ✅ `lib/shared/presentation/widgets/codegen_dialog.dart`

## Files Modified
- ✅ `lib/features/run_control/presentation/views/console_toolbar.dart` - Added QuickActionButtons
- ✅ `lib/features/run_control/presentation/viewmodels/run_control_viewmodel.dart` - Added status tracking (lastBuildStatus, lastCodeGenStatus)
- ✅ `lib/core/utils/constants.dart` - Added QuickActionStatus enum

## Status
**✅ 完成** - Implementation complete, build successful!

### Verification
- ✅ `flutter analyze` - No issues
- ✅ `flutter build macos --debug` - Success

## Summary

Added two quick action buttons (Build 🔨 and CodeGen ⚙️) to the console toolbar:

1. **Left click** opens a dialog with full configuration options
2. **Right click** shows a quick menu with common presets
3. **Status indicators** show ✓ or ✗ badge in corner based on last operation result

### Build Dialog Features
- Platform selection (macOS, iOS, Android APK/Bundle, Windows, Linux, Web)
- Debug/Release mode toggle
- Extra arguments text field
- "开始构建" and "打开输出" buttons

### CodeGen Dialog Features
- Build, Clean, Watch buttons
- Descriptions for each command
- Info box explaining build_runner usage
