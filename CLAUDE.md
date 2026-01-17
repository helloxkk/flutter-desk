# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**links2-flutter-manager** 是一个 Flutter Desktop for macOS 应用，为开发者提供快捷的 Flutter 项目管理功能。它作为 VSCode Flutter 扩展的替代方案，特别适合使用 Claude Code 进行开发的场景。

### 核心功能
- 快捷操作：运行、热重载、热重启、停止 Flutter 项目
- 设备管理：列出和选择可用的 Flutter 设备（物理设备、模拟器、桌面）
- 项目管理：添加和切换多个 Flutter 项目
- 实时日志：显示 flutter run 输出，支持过滤和搜索
- 菜单栏集成：macOS 状态栏图标（📱）点击切换窗口

## 常用命令

### 开发和构建

```bash
# 运行开发版本
flutter run -d macos

# 构建 Debug 版本
flutter build macos --debug

# 构建 Release 版本
flutter build macos --release

# 生成 JSON 序列化代码（修改模型后需要运行）
flutter pub run build_runner build --delete-conflicting-outputs

# 运行测试
flutter test

# 分析代码
flutter analyze

# 格式化代码
dart format .
```

### 应用位置

- **Debug**: `build/macos/Build/Products/Debug/links2_flutter_manager.app`
- **Release**: `build/macos/Build/Products/Release/links2_flutter_manager.app`

### 直接打开构建的应用

```bash
open build/macos/Build/Products/Debug/links2_flutter_manager.app
```

## 架构设计

### MVVM + Provider 模式

```
lib/
├── main.dart                     # 应用入口
├── models/                       # 数据模型
│   ├── flutter_project.dart     # 项目模型 (JSON 序列化)
│   ├── flutter_device.dart      # 设备模型
│   └── command_state.dart       # 命令执行状态 (不可变状态)
├── viewmodels/                   # 视图模型 (ChangeNotifier)
│   ├── project_viewmodel.dart   # 项目管理状态
│   ├── device_viewmodel.dart    # 设备管理状态
│   └── command_viewmodel.dart   # 命令执行状态 + 日志过滤
├── views/                        # UI 组件 (StatelessWidget)
│   ├── main_window.dart         # 主窗口 (MultiProvider 根节点)
│   ├── project_selector.dart    # 项目选择器
│   ├── device_selector.dart     # 设备选择器
│   ├── action_panel.dart        # 操作按钮面板
│   └── log_viewer.dart          # 日志查看器
├── services/                     # 业务逻辑
│   ├── flutter_service.dart     # Flutter 命令执行 (Process 管理)
│   ├── device_service.dart      # 设备检测 (flutter devices --machine)
│   └── storage_service.dart     # 配置持久化 (SharedPreferences)
└── utils/
    └── constants.dart           # 应用常量
```

### 数据流

```
用户操作 → View → ViewModel → Service → Process/Storage
                      ↓
                 State Update → View Update
```

## 核心技术实现

### 1. Flutter 命令执行 (FlutterService)

Flutter 进程通过 `Process.start()` 启动，热重载/热重启通过 stdin 发送字符命令实现：

```dart
// 启动进程
_process = await Process.start(
  'flutter',
  ['run', '-d', deviceId],
  workingDirectory: project.path,
);

// 热重载：发送 'r\n'
_process!.stdin.writeln('r');

// 热重启：发送 'R\n'
_process!.stdin.writeln('R');

// 停止：发送 'q\n'
_process!.stdin.writeln('q');
```

关键点：
- `stdout.transform(utf8.decoder)` 监听输出
- `exitCode.then()` 监听进程退出
- 超时机制：5 秒后 SIGTERM，失败则 SIGKILL

### 2. 设备检测 (DeviceService)

使用 `flutter devices --machine` 获取设备列表，解析 JSON 输出：

```dart
final result = await Process.run('flutter', ['devices', '--machine']);
final jsonData = jsonDecode(result.stdout) as List;
```

设备分类：
- `DeviceType.physical`: 物理设备
- `DeviceType.emulator`: 模拟器
- `DeviceType.desktop`: 桌面平台

### 3. 状态管理 (Provider)

三个独立的 Provider 在 MainWindow 根节点注入：

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProjectViewModel()..initialize()),
    ChangeNotifierProvider(create: (_) => DeviceViewModel()..initialize()),
    ChangeNotifierProvider(create: (_) => CommandViewModel()..initialize()),
  ],
  child: const _MainWindowContent(),
)
```

### 4. macOS 菜单栏集成

在 `macos/Runner/AppDelegate.swift` 中实现：

```swift
// 创建状态栏图标
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem.button.title = "📱"

// 点击切换窗口显示
@objc func toggleWindow() {
  if window.isVisible {
    window.orderOut(nil)
  } else {
    window.makeKeyAndOrderFront(nil)
  }
}
```

窗口关闭时不退出应用：
```swift
override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
  return false
}
```

## 关键约定

### JSON 序列化

所有使用 `@JsonSerializable()` 的模型都需要生成 `.g.dart` 文件：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 不可变状态

`CommandState` 和 `FlutterProject` 使用不可变模式，状态更新通过 `copyWith()` 实现：

```dart
// 更新状态
_state = _state.copyWith(status: ProcessStatus.running);

// 添加日志
_state = _state.addLog(logLine);
```

### 日志过滤

`CommandViewModel` 支持多种日志过滤：
- `LogFilter.all`: 全部日志
- `LogFilter.errors`: 仅错误
- `LogFilter.warnings`: 仅警告
- `LogFilter.info`: 仅信息
- `LogFilter.flutter`: Flutter 相关

### 常量定义

所有命令字符定义在 `AppConstants` 中：
- `hotReloadCommand = 'r'`
- `hotRestartCommand = 'R'`
- `stopCommand = 'q'`

## 重要依赖

| 包名 | 用途 |
|------|------|
| `provider` | 状态管理 |
| `json_serializable` | JSON 代码生成 |
| `shared_preferences` | 配置持久化 |
| `path_provider` | 文件系统路径 |
| `window_manager` | 窗口管理 |
| `tray_manager` | 系统托盘 |

## 环境要求

- Flutter 3.6.2+
- Dart 3.0+
- macOS 13.0+
- Xcode (for macOS build)

## 已知限制

1. **菜单栏图标**：仅支持点击切换窗口，暂不支持右键菜单
2. **进程管理**：未实现进程恢复机制（应用重启后需要重新运行）
3. **全局快捷键**：未实现
4. **项目自动检测**：需手动添加项目路径

## 开发注意事项

### 修改模型后

修改 `models/` 下的文件后，必须运行：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Flutter 进程环境变量

启动 Flutter 进程时设置了环境变量 `CLI_TOOL=links2-flutter-manager`，可用于日志识别。

### 窗口配置

窗口配置在 `macos/Runner/MainFlutterWindow.swift` 中：
- 透明标题栏：`titlebarAppearsTransparent = true`
- 最小尺寸：500x400
- 初始尺寸：600x700
