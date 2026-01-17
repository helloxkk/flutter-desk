# Notes: Flutter 项目管理器开发

## 已实现功能

### Phase 1: Flutter Desktop 项目基础架构 ✅
- 创建 Flutter Desktop for macOS 项目
- 配置依赖：provider, shared_preferences, path_provider, process_run
- 配置 JSON 序列化：json_annotation, json_serializable

### Phase 2: 数据模型 ✅
- **FlutterProject**: 项目模型（名称、路径、状态）
- **FlutterDevice**: 设备模型（ID、名称、平台、类型）
- **CommandState**: 命令执行状态（运行状态、进程信息、日志）

### Phase 3: 服务层 ✅
- **FlutterService**: Flutter 命令执行服务
  - 运行项目：`flutter run -d <device>`
  - 热重载：向 stdin 发送 'r'
  - 热重启：向 stdin 发送 'R'
  - 停止运行：向 stdin 发送 'q'
  - 清洁与依赖：clean/pub get/upgrade/outdated
  - 构建：build 命令支持多平台
  - 代码生成：build_runner build/clean/watch
- **DeviceService**: 设备检测服务
  - 执行 `flutter devices --machine`
  - 解析 JSON 输出
  - 设备分类（物理设备、模拟器、桌面）
- **StorageService**: 配置存储服务
  - 项目列表持久化
  - 最后选择的项目/设备

### Phase 4-6: UI 层 ✅
- **MainWindow**: 主窗口，使用 Provider 状态管理 + Tab 布局
- **ProjectSelector**: 项目选择器（下拉选择、添加、刷新）
- **DeviceSelector**: 设备选择器（列表显示、分类）
- **ActionPanel**: 操作按钮面板（运行、热重载、热重启、停止 + 工具菜单）
- **LogViewer**: 日志查看器（实时显示、语法高亮）

### Phase 7: macOS 菜单栏集成 ✅
- **AppDelegate.swift**:
  - 添加状态栏图标（📱）
  - 点击图标切换窗口显示/隐藏
  - 窗口关闭时不退出应用
- **MainFlutterWindow.swift**:
  - 配置窗口属性（标题、透明标题栏、最小尺寸）

### Phase 8-10: 功能扩展 ✅ (2024年新增)

#### 清洁与依赖管理 ✅
- FlutterService 扩展：
  - `cleanProject()` - flutter clean
  - `getDependencies()` - flutter pub get
  - `upgradeDependencies()` - flutter pub upgrade
  - `pubOutdated()` - flutter pub outdated
- ActionPanel 工具菜单：下拉菜单提供常用工具命令

#### 构建模块 ✅
- **BuildConfig** 模型：支持 APK/IPA/AppBundle/macOS/Windows/Linux/Web 构建
- **BuildPanel** UI：平台选择、模式选择、构建按钮
- 构建状态跟踪：新增 `ProcessStatus.building` 状态

#### 代码生成工具 ✅
- **BuildRunnerCommand** 枚举：build/clean/watch 命令
- **CodegenPanel** UI：build_runner 操作界面
- 一键生成代码：支持 `--delete-conflicting-outputs`

#### UI 整合 ✅
- Tab 布局：运行、构建、代码生成三个功能页
- 统一风格：保持 macOS Native Design

## 技术实现细节

### Flutter 命令执行
```dart
// 使用 Process.start() 启动 flutter run
_process = await Process.start(
  'flutter',
  ['run', '-d', deviceId],
  workingDirectory: projectPath,
  mode: ProcessStartMode.normal,
);

// 监听输出
_process!.stdout.transform(utf8.decoder).listen((data) {
  _handleOutput(data);
});

// 热重载
_process!.stdin.writeln('r');
```

### 设备检测
```dart
// 执行 flutter devices --machine
final result = await Process.run(
  'flutter',
  ['devices', '--machine'],
);

// 解析 JSON
final jsonData = jsonDecode(result.stdout as String) as List;
```

### 状态管理
```dart
// 使用 Provider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProjectViewModel()),
    ChangeNotifierProvider(create: (_) => DeviceViewModel()),
    ChangeNotifierProvider(create: (_) => CommandViewModel()),
  ],
  child: MainWindow(),
)
```

### 构建命令生成
```dart
// BuildConfig 自动生成构建命令
final command = config.buildCommand;
// ['build', 'apk', '--release', '--split-per-abi']
```

## 已知问题和限制

### 当前版本限制
1. **菜单栏图标**：仅支持点击切换窗口，暂不支持右键菜单
2. **进程管理**：未实现进程恢复机制
3. **日志**：未实现日志文件保存
4. **多设备运行**：未实现同时运行多个设备

### 待实现功能
1. 全局快捷键支持
2. 自动检测 CursorProjects 目录下的 Flutter 项目
3. 日志文件保存和查看历史
4. 固件升级流程集成
5. 通知功能（运行完成、错误提醒）
6. **多设备同时运行**（Phase 4 - 需要较大重构）

## 构建和运行

### 开发模式
```bash
# 运行开发版本
flutter run -d macos

# 或
flutter build macos --debug
open build/macos/Build/Products/Debug/links2_flutter_manager.app
```

### 发布模式
```bash
# 构建发布版本
flutter build macos --release

# 输出位置
build/macos/Build/Products/Release/links2_flutter_manager.app
```

## 交付物清单

- [x] 可运行的 macOS 应用（.app）
- [x] 支持运行、热重载、热重启、停止操作
- [x] 支持设备选择
- [x] 支持项目管理（至少 3 个项目）
- [x] macOS 菜单栏图标集成
- [x] 实时日志显示
- [x] 清洁与依赖管理工具（clean/pub get/upgrade/outdated）
- [x] 构建模块（支持多平台构建）
- [x] 代码生成工具（build_runner build/clean/watch）
- [ ] 多设备同时运行（未实现）
