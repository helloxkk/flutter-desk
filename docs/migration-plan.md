# FlutterDesk → Swift/SwiftUI 迁移计划

## 📋 项目概述

| 项目 | 说明 |
|-----|------|
| **项目名称** | FlutterDesk (Swift 版本) |
| **目标平台** | macOS 13.0+ |
| **开发周期** | 8 周（优化版本） |
| **团队水平** | Swift/SwiftUI 专家级 |
| **目标** | 完整功能迁移 + 性能优化 + 原生体验增强 |

---

## 🏗️ 技术架构设计

```
FlutterDesk-Swift/
├── App/
│   ├── FlutterDeskApp.swift           # 应用入口
│   └── AppDelegate.swift              # 应用代理 & 菜单栏
│
├── Core/
│   ├── Theme/
│   │   ├── MacOSTheme.swift           # 主题系统
│   │   ├── Colors.swift               # SF 颜色
│   │   └── Typography.swift           # 字体系统
│   │
│   ├── Models/
│   │   ├── FlutterProject.swift       # 项目模型
│   │   ├── FlutterDevice.swift        # 设备模型
│   │   ├── CommandState.swift         # 命令状态
│   │   └── BuildConfig.swift          # 构建配置
│   │
│   ├── ViewModels/
│   │   ├── ProjectViewModel.swift     # 项目管理
│   │   ├── DeviceViewModel.swift      # 设备管理
│   │   ├── CommandViewModel.swift     # 命令执行
│   │   └── ThemeViewModel.swift       # 主题切换
│   │
│   └── Services/
│       ├── FlutterService.swift       # Flutter 进程管理
│       ├── DeviceService.swift        # 设备检测
│       ├── StorageService.swift       # 持久化
│       └── TrayService.swift          # 菜单栏服务
│
├── Features/
│   ├── MainWindow/
│   │   ├── MainWindowView.swift       # 主窗口
│   │   └── ContentView.swift          # 内容区域
│   │
│   ├── ProjectManagement/
│   │   ├── Views/
│   │   │   ├── ConsoleSidebar.swift   # 左侧边栏
│   │   │   ├── ProjectSelector.swift # 项目选择器
│   │   │   └── ProjectListItem.swift  # 项目列表项
│   │   └── Components/
│   │       ├── EmptyStateView.swift
│   │       ├── LoadingIndicator.swift
│   │       └── ErrorView.swift
│   │
│   ├── DeviceManagement/
│   │   ├── Views/
│   │   │   ├── DeviceListSection.swift
│   │   │   └── DeviceListItem.swift
│   │   └── Components/
│   │       └── EmptyDeviceView.swift
│   │
│   ├── RunControl/
│   │   ├── Views/
│   │   │   ├── ConsoleToolbar.swift   # 顶部工具栏
│   │   │   ├── ActionButtons.swift    # 操作按钮组
│   │   │   └── SearchField.swift      # 搜索框
│   │   └── Components/
│   │       ├── ToolbarButton.swift
│   │       └── StatusIndicator.swift
│   │
│   ├── LogViewer/
│   │   ├── Views/
│   │   │   ├── LogViewerView.swift    # 日志查看器
│   │   │   ├── LogContentArea.swift   # 内容区域
│   │   │   └── LogViewerToolbar.swift # 工具栏
│   │   ├── Components/
│   │   │   ├── SegmentedFilter.swift  # 分段过滤
│   │   │   ├── LogLineView.swift      # 日志行
│   │   │   └── ErrorBanner.swift      # 错误横幅
│   │   └── Utils/
│   │       └── LogSyntaxHighlighter.swift # 语法高亮
│   │
│   ├── BuildPanel/
│   │   ├── Views/
│   │   │   ├── BuildPanelView.swift   # 构建面板
│   │   │   ├── BuildTypeSelector.swift # 构建类型选择
│   │   │   └── BuildButton.swift      # 构建按钮
│   │   └── Components/
│   │       └── BuildingIndicator.swift
│   │
│   └── CodeGenPanel/
│       ├── Views/
│       │   ├── CodeGenPanelView.swift
│       │   └── BuildRunnerButton.swift
│       └── Components/
│           └── CodeGenIndicator.swift
│
├── Resources/
│   ├── Assets.xcassets/                # SF Symbols
│   └── Colors.xcassets/               # 颜色资源
│
├── Supporting Files/
│   ├── Info.plist                     # 应用配置
│   └── entitlements                   # 权限配置
│
└── Tests/
    ├── UnitTests/
    │   ├── ServiceTests/
    │   └── ModelTests/
    └── UITests/
        └── FeatureTests/
```

---

## 📊 Flutter → Swift/SwiftUI 技术映射

| Flutter | Swift/SwiftUI | 实现说明 |
|---------|---------------|---------|
| **数据模型** | `struct` + `Codable` | 自动 JSON 序列化，无需代码生成 |
| **状态管理** | `@Observable` (iOS 17+) | 现代化响应式状态管理 |
| **Widget 树** | `View` + `ViewBuilder` | 声明式 UI，概念完全一致 |
| **StatefulWidget** | `@State` / `@StateObject` | 本地状态管理 |
| **InheritedWidget** | `@Environment` | 环境传递 |
| **Provider** | `@Environment` + `@Observable` | 轻量级依赖注入 |
| **ListView.builder** | `List` / `LazyVStack` | 性能优化，自动 diffing |
| **GestureDetector** | `.onTapGesture()` modifier | 流式 API |
| **Container + decoration** | `ZStack` + `.background()` | 更灵活的布局 |
| **TextField** | `TextField` | 原生文本输入 |
| **PopupMenuButton** | `.contextMenu()` modifier | 系统原生菜单 |
| **SnakBar** | `.alert()` / `.sheet()` modifier | 系统级提示 |
| **Dialog** | `.alert()` / `.confirmationDialog()` | 系统级对话框 |
| **SelectionArea** | `Text(.init(selection:))` | 更强大的文本选择 |
| **Process.start** | `Process` + `Pipe` | Foundation 原生进程管理 |
| **File` | `FileManager` | 系统文件 API |
| **SharedPreferences** | `UserDefaults` | 系统持久化 |
| **window_manager** | `NSWindow` / `NSWindowController` | AppKit 原生窗口 |
| **tray_manager** | `NSStatusBar` + `NSMenu` | AppKit 原生菜单栏 |
| **file_selector** | `NSOpenPanel` / `NSSavePanel` | 系统文件选择器 |
| **ProcessSignal** | `signal()` | Unix 信号 |
| **utf8.decoder** | `String(decoding:)` | String 编码 |

---

## 🎯 详细实施计划（8 周）

### 第 1 周：项目初始化 & 基础架构

**目标**: 建立 Xcode 项目，完成核心基础设施

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 创建 Xcode macOS App 项目 | 0.5 天 | Xcode 项目 |
| 配置 Info.plist & 签名 | 0.5 天 | 可运行的空 App |
| 实现主题系统 | 1 天 | MacOSTheme.swift |
| 创建数据模型 | 1 天 | 所有 Models (Codable) |
| 设置状态管理架构 | 1 天 | Observable ViewModels 框架 |
| 实现持久化服务 | 1 天 | StorageService |

**技术要点**:
- 使用 iOS 17+ `@Observable` 宏
- SF Colors 系统颜色
- UserDefaults 存储项目列表
- Codable 自动 JSON 序列化

---

### 第 2 周：核心服务层

**目标**: 实现所有业务逻辑服务

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 实现 DeviceService | 1.5 天 | 设备检测服务 |
| 实现 FlutterService | 2 天 | 进程管理服务 |
| 实现 TrayService | 1.5 天 | 菜单栏集成 |
| 单元测试 | 1 天 | Service 测试套件 |

**FlutterService 实现关键点**:
```swift
class FlutterService: ObservableObject {
    @Published var state: CommandState

    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?

    func run(project: FlutterProject, device: FlutterDevice) async throws {
        // 启动 Process
        // 监听 Pipe 输出流
        // 更新 state
    }

    func hotReload() async throws {
        process?.standardInput?.write("r\n".data(using: .utf8)!)
    }
}
```

---

### 第 3 周：主窗口布局

**目标**: 实现主窗口的三栏布局

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 主窗口框架 | 1 天 | MainWindowView |
| 侧边栏容器 | 1.5 天 | ConsoleSidebar |
| 内容区域布局 | 1.5 天 | ContentView |
| 窗口管理 | 1 天 | NSWindow 配置 |

**SwiftUI 布局代码示例**:
```swift
struct MainWindowView: View {
    @Environment(ProjectViewModel.self) var projectVM
    @Environment(DeviceViewModel.self) var deviceVM
    @Environment(CommandViewModel.self) var commandVM

    var body: some View {
        HStack(spacing: 12) {
            // 左侧边栏
            ConsoleSidebar()
                .frame(width: 200)
                .padding(.horizontal, 12)
                .padding(.vertical, 40)

            // 右侧内容区
            VStack(spacing: 0) {
                ConsoleToolbar()
                    .frame(height: 52)
                SegmentedFilter()
                LogContentView()
                    .layoutPriority(1)
            }
            .padding(.trailing, 12)
        }
    }
}
```

---

### 第 4 周：项目管理功能

**目标**: 完成项目和设备选择 UI

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 项目列表 UI | 1.5 天 | ProjectListView |
| 项目列表项 | 1 天 | ProjectListItem |
| 添加/删除项目 | 1 天 | 上下文菜单 |
| 设备列表 UI | 1 天 | DeviceListView |
| 空状态 & 加载状态 | 1.5 天 | EmptyState, Loading |

**关键组件实现**:
```swift
struct ProjectListItem: View {
    let project: FlutterProject
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(isSelected ? .blue : .secondary)
            Text(project.name)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .blue : .primary)
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button("移除项目") { /* ... */ }
            Button("在 Finder 中显示") { /* ... */ }
        }
    }
}
```

---

### 第 5 周：运行控制功能

**目标**: 实现工具栏和操作按钮

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 工具栏布局 | 1 天 | ConsoleToolbar |
| 操作按钮组 | 1.5 天 | ActionButtons |
| 搜索框 | 0.5 天 | SearchField |
| 状态指示器 | 0.5 天 | StatusIndicator |
| 按钮交互逻辑 | 2 天 | 所有命令处理 |

**操作按钮实现**:
```swift
struct ActionButtons: View {
    @Environment(CommandViewModel.self) var vm

    var body: some View {
        HStack(spacing: 2) {
            ToolbarButton(
                icon: "play.fill",
                color: .green,
                isEnabled: vm.canRun,
                action: { Task { await vm.run() } }
            )
            ToolbarButton(
                icon: "bolt.fill",
                color: .yellow,
                isEnabled: vm.canOperate,
                action: { Task { await vm.hotReload() } }
            )
            ToolbarButton(
                icon: "arrow.clockwise",
                color: .blue,
                isEnabled: vm.canOperate,
                action: { Task { await vm.hotRestart() } }
            )
            ToolbarButton(
                icon: "stop.fill",
                color: .red,
                isEnabled: vm.isRunning,
                action: { Task { await vm.stop() } }
            )
        }
    }
}
```

---

### 第 6 周：日志查看器

**目标**: 实现功能完整的日志查看器

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 日志内容区域 | 1.5 天 | LogContentView |
| 日志行渲染 | 1.5 天 | LogLineView + 高亮 |
| 过滤器工具栏 | 1 天 | LogViewerToolbar |
| 搜索功能 | 1 天 | 搜索实现 |
| 自动滚动 | 1 天 | ScrollView 管理 |

**语法高亮实现**:
```swift
struct LogSyntaxHighlighter {
    static func attributedString(for log: String) -> AttributedString {
        var attributedString = AttributedString(log)

        if log.contains("[ERROR]") || log.contains("Error:") {
            attributedString.foregroundColor = .red
        } else if log.contains("[WARNING]") {
            attributedString.foregroundColor = .orange
        } else if log.contains("Hot reload") {
            attributedString.foregroundColor = .green
        } else if log.contains("Flutter run") {
            attributedString.foregroundColor = .blue
        }

        return attributedString
    }
}

struct LogLineView: View {
    let log: String

    var body: some View {
        Text(LogSyntaxHighlighter.attributedString(for: log))
            .font(.system(.caption, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

---

### 第 7 周：构建面板 & 代码生成

**目标**: 完成构建和代码生成功能

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 构建面板 UI | 1.5 天 | BuildPanelView |
| 构建类型选择器 | 1 天 | BuildTypeSelector |
| 构建进度显示 | 1 天 | BuildingIndicator |
| 代码生成面板 | 1 天 | CodeGenPanel |
| 构建输出管理 | 1.5 天 | 打开构建产物 |

---

### 第 8 周：优化、测试 & 发布

**目标**: 性能优化、测试、打包发布

| 任务 | 工作量 | 交付物 |
|------|-------|-------|
| 性能优化 | 1 天 | 内存、启动速度优化 |
| 单元测试 | 1.5 天 | 测试覆盖率 >80% |
| UI 测试 | 1 天 | XCUITest 套件 |
| Bug 修复 | 1.5 天 | 所有问题修复 |
| 文档编写 | 0.5 天 | README, CLAUDE.md |
| 打包发布 | 1.5 天 | .dmg 分发包 |
| Code Review | 1 天 | 代码审查 |

---

## 🚀 增强功能计划

在 8 周的基础功能之外，我们还计划实现以下增强功能：

| 功能 | 工作量 | 优先级 | 说明 |
|------|-------|-------|------|
| **全局快捷键** | 0.5 天 | P0 | Cmd+R 热重载、Cmd+Q 停止 |
| **深度搜索** | 1 天 | P0 | 正则表达式搜索日志 |
| **日志导出** | 0.5 天 | P1 | 导出为 .txt/.log |
| **项目自动检测** | 1 天 | P1 | 监控常用目录 |
| **Git 集成** | 1.5 天 | P2 | 显示当前分支 |
| **终端集成** | 2 天 | P2 | 内嵌终端 |
| **多标签页** | 1.5 天 | P2 | 管理多个项目 |
| **性能监控** | 1 天 | P3 | CPU/内存占用 |
| **主题自定义** | 1.5 天 | P3 | 自定义颜色 |
| **插件系统** | 3 天 | P3 | 可扩展架构 |

---

## 📈 性能对比预期

| 指标 | Flutter 版本 | Swift 版本 | 提升 |
|------|------------|-----------|------|
| **启动时间** | ~3s | ~1.5s | 50% ↓ |
| **内存占用** | ~80MB | ~40MB | 50% ↓ |
| **App 体积** | ~50MB | ~15MB | 70% ↓ |
| **界面流畅度** | 60fps | 120fps (ProMotion) | 100% ↑ |
| **CPU 占用** | ~5% | ~2% | 60% ↓ |

---

## ⚠️ 风险管理

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| **进程流处理复杂** | 中 | 中 | 使用 Combine 框架处理异步流 |
| **SwiftUI 布局限制** | 低 | 中 | 必要时使用 NSViewRepresentable |
| **文本选择性能** | 低 | 低 | 使用 LazyVStack 优化列表 |
| **菜单栏状态同步** | 中 | 低 | 使用 @Published 自动同步 |
| **深色模式适配** | 低 | 低 | 系统自动监听 colorScheme |

---

## ✅ 质量保证策略

### 单元测试
- 所有 ViewModel 服务逻辑
- 数据模型序列化/反序列化
- 工具函数（日志高亮、过滤）

### UI 测试
- 主要用户流程测试
- 按钮交互测试
- 窗口管理测试

### 性能测试
- Instruments 工具检测内存泄漏
- Time Profiler 分析 CPU 占用
- 启动时间测试

### 代码质量
- SwiftLint 代码规范检查
- Git PR Code Review
- 文档注释覆盖率 >90%

---

## 📚 文档计划

1. **README.md** - 项目介绍、快速开始
2. **CLAUDE.md** - 开发指南、架构说明
3. **API.md** - 公开 API 文档
4. **CONTRIBUTING.md** - 贡献指南
5. **CHANGELOG.md** - 版本更新日志

---

## 🎯 里程碑

| 里程碑 | 周次 | 验收标准 |
|-------|------|---------|
| **M1: 基础架构** | Week 1 | 可运行的空 App，主题系统完成 |
| **M2: 核心服务** | Week 2 | 所有服务通过单元测试 |
| **M3: 主窗口** | Week 3 | 三栏布局完成，响应式 |
| **M4: 项目管理** | Week 4 | 可添加/删除/选择项目 |
| **M5: 运行控制** | Week 5 | 所有操作按钮可用 |
| **M6: 日志查看** | Week 6 | 实时日志、搜索、过滤 |
| **M7: 构建功能** | Week 7 | 可构建所有目标平台 |
| **M8: 发布版本** | Week 8 | 通过所有测试，可发布 |

---

## 📝 开发规范

### 命名约定
- **类名**: `PascalCase` (e.g., `ProjectViewModel`)
- **方法名**: `camelCase` (e.g., `addProject()`)
- **常量**: `camelCase` (e.g., `systemBlue`)
- **私有成员**: `_camelCase`

### 文件组织
- 每个 Swift 文件只包含一个主要的类型
- 使用 MARK 注释组织代码
- 文件名与类型名一致

### Git 工作流
- 功能分支: `feature/xxx`
- 修复分支: `fix/xxx`
- 每次提交前运行 `swift test`
- PR 至少 1 人审批

---

## 🔧 工具链

- **Xcode**: 15.0+
- **Swift**: 5.9+
- **SwiftLint**: 0.54+
- **SwiftFormat**: 0.52+
- **SwiftGen**: 6.6+ (资源生成)
- **Mint**: 1.0+ (依赖管理)

---

## 📦 依赖管理

```swift
// Package.swift (使用 SwiftPM)
dependencies: [
    // 不需要外部依赖，主要使用系统框架：
    // - SwiftUI (UI)
    // - Combine (响应式)
    // - Foundation (核心)
    // - AppKit (macOS 特定)
]
```

---

## 🎨 主题系统设计

### SF 颜色系统
- **System Blue**: `#007AFF` (主色调)
- **System Gray**: `#8E8E93` (中性色)
- **Success Green**: `#34C759` (成功)
- **Warning Orange**: `#FF9500` (警告)
- **Error Red**: `#FF3B30` (错误)

### 字体系统
- **SF Pro**: macOS 系统字体
- **Monospace**: Menlo (日志显示)
- **标题**: 17-20pt
- **正文**: 13pt
- **说明**: 11pt

---

## 🔐 安全与权限

### Info.plist 配置
```xml
<key>NSAppleEventsUsageDescription</key>
<string>需要访问 Apple Events 以控制终端进程</string>
<key>LSUIElement</key>
<false/>
<key>LSBackgroundOnly</key>
<false/>
```

### 签名配置
- 开发者证书签名
- App Store 分发准备
- Gatekeeper 兼容

---

## 📞 联系与支持

- **Issue Tracker**: GitHub Issues
- **文档**: docs/
- **示例代码**: Examples/

---

## 📄 许可证

与原 FlutterDesk 项目保持一致。

---

*最后更新: 2025-01-20*
