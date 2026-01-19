# TODO - 待实现功能

## 功能完整度概览

```
后端实现: ████████████████████ 100% (所有核心功能已实现)
前端显示: ████████░░░░░░░░░░░░  50% (基础功能已显示)
```

## ✅ 已实现的功能

### 基础功能
- [x] 项目列表显示和选择
- [x] 设备列表显示和选择
- [x] 添加项目（文件夹选择器）
- [x] 移除项目（右键菜单 + 确认对话框）
- [x] 在 Finder 中显示项目
- [x] 运行 Flutter 项目
- [x] 热重载/热重启
- [x] 停止运行
- [x] 清除日志
- [x] 日志搜索
- [x] 日志过滤（全部/错误/警告/信息/Flutter）
- [x] 暗色模式切换
- [x] macOS 原生界面风格

---

## 🔧 后端已实现但前端未显示的功能

### 1. 构建面板 (`BuildPanel`)
**状态**: UI 组件已完整实现，只需集成到主窗口

**功能**:
- [ ] 多平台构建支持
  - [ ] APK (Android)
  - [ ] IPA (iOS)
  - [ ] App Bundle (Android)
  - [ ] macOS
  - [ ] Windows
  - [ ] Linux
  - [ ] Web
- [ ] Debug/Release 模式切换
- [ ] 构建按钮
- [ ] 打开构建输出目录
- [ ] 构建进度指示器

**相关文件**:
- `lib/views/build_panel.dart` (UI 组件已完整实现)
- `lib/viewmodels/command_viewmodel.dart` (ViewModel 方法已实现)
- `lib/services/flutter_service.dart` (服务层已实现)

**集成方式**:
在 `MainWindow` 中添加 `BuildPanel` 组件到布局中

---

### 2. 代码生成面板 (`CodegenPanel`)
**状态**: UI 组件已完整实现，只需集成到主窗口

**功能**:
- [ ] build_runner build (生成代码)
- [ ] build_runner clean (清理生成)
- [ ] build_runner watch (监听文件变化)
- [ ] 运行中指示器
- [ ] 停止按钮（用于停止 watch 命令）

**相关文件**:
- `lib/views/codegen_panel.dart` (UI 组件已完整实现)
- `lib/viewmodels/command_viewmodel.dart` (ViewModel 方法已实现)
- `lib/services/flutter_service.dart` (服务层已实现)
- `lib/utils/constants.dart` (BuildRunnerCommand 枚举已定义)

**集成方式**:
在 `MainWindow` 中添加 `CodegenPanel` 组件到布局中

---

### 3. 依赖管理功能
**状态**: ViewModel 方法已实现，需要创建 UI 组件

**功能**:
- [ ] Flutter Clean (清理构建产物)
- [ ] Pub Get (获取依赖)
- [ ] Pub Upgrade (升级依赖)
- [ ] Pub Outdated (检查过期依赖)

**相关文件**:
- `lib/viewmodels/command_viewmodel.dart` (方法已实现)
  - `cleanProject()`
  - `getDependencies()`
  - `upgradeDependencies()`
  - `pubOutdated()`
- `lib/services/flutter_service.dart` (服务层已实现)

**实现方式**:
创建新的 UI 组件（如 `DependencyPanel`），添加按钮调用对应的 ViewModel 方法

---

## 🚀 未来计划功能

### 优先级 P1 (高)
- [ ] 构建面板集成
- [ ] 代码生成面板集成

### 优先级 P2 (中)
- [ ] 依赖管理面板
- [ ] 项目配置编辑（如默认设备、环境变量等）

### 优先级 P3 (低)
- [ ] 自定义构建配置保存
- [ ] 构建历史记录
- [ ] 一键发布到应用商店

---

## 📋 UI 改进建议

### 当前可优化的地方
- [ ] 添加 Tab 导航或侧边栏来组织多个功能面板
- [ ] 添加快捷键支持
- [ ] 添加全局菜单栏菜单
- [ ] 添加通知提示（构建完成、错误等）
- [ ] 添加启动项配置

---

## 🔗 相关文件

### 主窗口
- `lib/views/main_window.dart` - 当前只有侧边栏 + 工具栏 + 日志区域

### 待集成的面板
- `lib/views/build_panel.dart` - 构建面板（已实现）
- `lib/views/codegen_panel.dart` - 代码生成面板（已实现）

### ViewModel 层
- `lib/viewmodels/command_viewmodel.dart` - 包含所有未显示功能的 ViewModel 方法

### 服务层
- `lib/services/flutter_service.dart` - 包含所有 Flutter 命令执行逻辑

---

## 📝 开发注意事项

1. **构建面板和代码生成面板** 的 UI 组件已经完整实现，只需要在 `MainWindow` 中引入并布局即可

2. **依赖管理功能** 需要创建新的 UI 组件，可以参考 `BuildPanel` 的设计风格

3. 所有后端功能都已经在 `CommandViewModel` 和 `FlutterService` 中实现，不需要修改后端代码

4. 集成时注意处理状态同步（如构建中、运行中等状态）
