# Task Plan: 优化弹窗 UI 为 macOS 原生风格

## Goal
将 BuildConfigDialog 和 CodeGenDialog 优化为更符合 macOS 原生对话框风格

## 设计要点

### 标题栏
- ✅ 移除图标背景框，只保留纯文字标题
- ✅ 使用 fontSizeTitle3 (20px) + weightSemibold

### 内容区域
- ✅ 增加留白，使用 contentPadding
- ✅ 分组标签用灰色小字 (fontSizeCaption2 - 12px)
- ✅ 平台选择用 Wrap 自动换行
- ✅ 构建模式用 SegmentedButton

### 按钮区域
- ✅ 右对齐布局
- ✅ 主按钮蓝色背景，次按钮无边框
- ✅ 文字大小 fontSizeFootnote (13px)
- ✅ 按钮文字简化："构建" 而非 "开始构建"

## Phases
- [x] Phase 1: 提交当前代码
- [x] Phase 2: 优化 BuildConfigDialog
- [x] Phase 3: 优化 CodeGenDialog
- [x] Phase 4: 测试验证

## Files Modified
- lib/shared/presentation/widgets/build_config_dialog.dart
- lib/shared/presentation/widgets/codegen_dialog.dart

## 主要改动

### BuildConfigDialog
- 标题：移除图标背景框，纯文字
- 分组标签：使用 fontSizeCaption2 (12px) + textSecondary 颜色
- 按钮文字：简化为"构建"（从"开始构建"）

### CodeGenDialog
- 标题：移除图标背景框，纯文字
- 命令按钮：卡片化设计，主按钮 hover 带阴影
- 信息框：浅蓝色背景，fontSizeCaption2 (12px)

## Status
**✅ 完成** - 已按照 macOS 原生风格优化弹窗 UI

### 验证结果
- ✅ `flutter analyze` - 无错误
- ✅ `flutter build macos --debug` - 成功
