# Task Plan: Flutter Manager 功能扩展

## 目标
为 links2-flutter-manager 添加四大新功能：构建模块、代码生成工具、多设备同时运行、清洁与依赖管理

## 项目信息
- **项目路径**: `/Users/kun/CursorProjects/links2-flutter-manager`
- **当前架构**: MVVM + Provider 模式
- **技术栈**: Flutter 3.6.2+, Dart 3.0+

## Phases

### Phase 1: 清洁与依赖管理（最简单）
- [x] 1.1 扩展 `FlutterService` 添加命令执行方法
  - [x] `cleanProject()` - flutter clean
  - [x] `getDependencies()` - flutter pub get
  - [x] `upgradeDependencies()` - flutter pub upgrade
  - [x] `pubOutdated()` - flutter pub outdated
- [x] 1.2 扩展 `CommandViewModel` 添加调用接口
- [x] 1.3 扩展 `CommandState` 添加新状态类型
- [x] 1.4 修改 `ActionPanel` 添加工具菜单
- [x] 1.5 测试验证

### Phase 2: 构建模块
- [x] 2.1 创建 `BuildConfig` 模型 (`lib/models/build_config.dart`)
  - [x] 定义 `BuildType` 枚举
  - [x] 实现 `BuildConfig` 类
- [x] 2.2 扩展 `FlutterService`
  - [x] 添加 `build()` 方法
  - [x] 添加构建进度跟踪
- [x] 2.3 扩展 `CommandViewModel`
  - [x] 添加 `startBuild()` 方法
  - [x] 添加构建状态 `ProcessStatus.building`
- [x] 2.4 扩展 `CommandState`
  - [x] 添加构建相关状态字段
- [x] 2.5 创建 `BuildPanel` UI 组件
- [x] 2.6 集成到主窗口
- [x] 2.7 测试验证

### Phase 3: 代码生成工具
- [x] 3.1 扩展 `FlutterService`
  - [x] 添加 `runBuildRunner()` 方法
  - [x] 支持 build/clean/watch 命令
- [x] 3.2 扩展 `CommandViewModel`
  - [x] 添加 `runBuildRunner()` 方法
- [x] 3.3 创建 `CodegenPanel` UI 组件
- [x] 3.4 集成到主窗口
- [x] 3.5 测试验证

### Phase 4: 多设备同时运行（最复杂）
- [ ] 4.1 创建 `MultiDeviceState` 模型
- [ ] 4.2 重构 `FlutterService` 支持多进程
  - [ ] 使用 `Map<String, Process>` 管理多设备
  - [ ] 实现 `runOnMultipleDevices()` 方法
  - [ ] 实现 `hotReloadAll()` 方法
- [ ] 4.3 扩展 `CommandState`
  - [ ] 添加 `Map<String, ProcessStatus>` 每设备状态
- [ ] 4.4 扩展 `CommandViewModel`
  - [ ] 添加多设备状态管理
- [ ] 4.5 创建 `MultiDevicePanel` UI 组件
- [ ] 4.6 集成到主窗口
- [ ] 4.7 测试验证

### Phase 5: UI 整合与优化
- [ ] 5.1 实现 Tab 布局组织多个功能模块
- [ ] 5.2 更新 `MainWindow` 集成所有新面板
- [ ] 5.3 添加常量到 `constants.dart`
- [ ] 5.4 全面测试

## Key Questions
1. 如何在现有 MVVM 架构下优雅地添加新功能？
2. 多设备同时运行时如何保证性能？
3. 构建过程如何实现进度跟踪和取消功能？
4. UI 如何组织多个功能模块？

## Decisions Made
- [实施顺序]: 从简单到复杂，先实现清洁与依赖管理，最后实现多设备运行
- [UI架构]: 使用 Tab 布局组织多个功能模块（运行/构建/工具）
- [多进程管理]: 使用 `Map<String, Process>` 存储多设备进程，设备 ID 作为 key

## 文件清单

### 新建文件
- [ ] `lib/models/build_config.dart` - 构建配置模型
- [ ] `lib/models/multi_device_state.dart` - 多设备状态模型
- [ ] `lib/views/build_panel.dart` - 构建面板 UI
- [ ] `lib/views/codegen_panel.dart` - 代码生成面板 UI
- [ ] `lib/views/multi_device_panel.dart` - 多设备面板 UI

### 修改文件
- [ ] `lib/services/flutter_service.dart` - 添加新命令执行方法
- [ ] `lib/viewmodels/command_viewmodel.dart` - 添加新功能调用接口
- [ ] `lib/models/command_state.dart` - 添加新状态类型
- [ ] `lib/views/action_panel.dart` - 添加工具菜单
- [ ] `lib/utils/constants.dart` - 添加新命令常量
- [ ] `lib/views/main_window.dart` - 集成新面板

## 验收标准

### 构建模块
- [ ] 可以选择构建类型（APK/IPA/AppBundle）
- [ ] 构建过程日志实时显示
- [ ] 构建完成后显示输出路径
- [ ] 构建失败时显示错误信息

### 代码生成工具
- [ ] build_runner build 命令正常执行
- [ ] build_runner clean 命令正常执行
- [ ] 生成过程日志实时显示

### 多设备运行
- [ ] 可以选择多个设备
- [ ] 在多个设备上同时启动项目
- [ ] 每个设备独立显示运行状态
- [ ] 可以对所有设备执行热重载

### 清洁与依赖
- [ ] flutter clean 命令正常执行
- [ ] flutter pub get 命令正常执行
- [ ] flutter pub upgrade 命令正常执行
- [ ] 命令执行日志显示正常

## Errors Encountered
*（待更新）*

## Status
**Currently in Phase 4** - Phase 1-3 已完成，Phase 4（多设备同时运行）暂未实现（复杂度较高，需要后续完成）
