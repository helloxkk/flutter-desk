# FlutterDesk 分包架构重构设计

**日期**: 2025-01-20
**作者**: Claude Code
**状态**: 设计完成，待实施

---

## 1. 概述

### 1.1 目标

将 FlutterDesk 从现有的平铺目录结构重构为 **渐进式模块化架构**，实现：

- 代码按功能垂直分片，每个 feature 独立自包含
- 清晰的层次划分（Core、Shared、Features）
- 低耦合、高内聚的代码组织
- 便于未来扩展和维护

### 1.2 架构选择理由

| 方案 | 优势 | 劣势 | 选择 |
|------|------|------|------|
| 功能模块分包 | 按业务分片清晰 | 可能代码重复 | ✅ 推荐 |
| 层次分包 | 传统分层 | 跨层依赖混乱 | ❌ |
| 垂直切片分包 | 独立性好 | 初期结构复杂 | ✅ 结合 |
| 多包/模块化 | 完全解耦 | 开发复杂度高 | ❌ 过度设计 |

**最终选择**：渐进式模块化 - 单包 + 垂直分片 + 清晰层次

---

## 2. 目标架构

### 2.1 目录结构

```
lib/
├── main.dart                           # 应用入口
│
├── core/                               # 核心层（全局共享，无业务依赖）
│   ├── theme/
│   │   ├── macos_theme.dart            # macOS 原生主题
│   │   └── colors.dart                 # 颜色常量
│   ├── utils/
│   │   ├── constants.dart              # 应用常量
│   │   ├── logger.dart                 # 日志工具
│   │   └── extensions/                 # Dart 扩展
│   ├── config/
│   │   └── app_config.dart             # 应用配置
│   └── core.dart                       # Barrel export
│
├── shared/                             # 共享层（跨 feature 复用）
│   ├── widgets/
│   │   ├── segmented_control/          # 通用分段控制器
│   │   ├── loading_indicator/          # 加载指示器
│   │   ├── error_display/              # 错误展示
│   │   └── empty_state/                # 空状态
│   ├── models/
│   │   ├── command_state.dart          # 命令执行状态
│   │   ├── command_state.g.dart
│   │   ├── build_config.dart           # 构建配置
│   │   ├── build_config.g.dart
│   │   ├── flutter_project.dart        # 项目模型
│   │   ├── flutter_project.g.dart
│   │   ├── flutter_device.dart         # 设备模型
│   │   └── flutter_device.g.dart
│   └── services/
│       ├── storage_service.dart        # 本地存储
│       └── tray_service.dart           # 系统托盘
│   └── shared.dart                     # Barrel export
│
├── features/                           # 功能特性层（垂直分片）
│   │
│   ├── project_management/             # 项目管理 feature
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── project_entity.dart
│   │   │   └── repositories/
│   │   │       └── project_repository.dart
│   │   ├── presentation/
│   │   │   ├── viewmodels/
│   │   │   │   └── project_viewmodel.dart
│   │   │   ├── views/
│   │   │   │   └── console_sidebar.dart
│   │   │   └── widgets/
│   │   │       ├── project_item.dart
│   │   │       └── add_project_dialog.dart
│   │   └── services/
│   │       └── project_service.dart
│   │   └── project_management.dart     # Barrel export
│   │
│   ├── device_management/              # 设备管理 feature
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── device_repository.dart
│   │   ├── presentation/
│   │   │   ├── viewmodels/
│   │   │   │   └── device_viewmodel.dart
│   │   │   └── widgets/
│   │   │       └── device_item.dart
│   │   ├── services/
│   │   │   └── device_service.dart
│   │   └── device_management.dart
│   │
│   ├── run_control/                   # 运行控制 feature
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── flutter_process.dart
│   │   │   └── repositories/
│   │   │       └── process_repository.dart
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       └── flutter_process_datasource.dart
│   │   ├── presentation/
│   │   │   ├── viewmodels/
│   │   │   │   └── run_control_viewmodel.dart
│   │   │   ├── views/
│   │   │   │   ├── console_toolbar.dart
│   │   │   │   └── action_panel.dart
│   │   │   └── widgets/
│   │   │       └── compact_toolbar_button.dart
│   │   ├── services/
│   │   │   └── flutter_service.dart
│   │   └── run_control.dart
│   │
│   ├── build_panel/                   # 构建面板 feature
│   │   ├── presentation/
│   │   │   ├── viewmodels/
│   │   │   │   └── build_viewmodel.dart
│   │   │   └── views/
│   │   │       └── build_panel.dart
│   │   └── build_panel.dart
│   │
│   ├── codegen_panel/                 # 代码生成 feature
│   │   ├── presentation/
│   │   │   ├── viewmodels/
│   │   │   │   └── codegen_viewmodel.dart
│   │   │   └── views/
│   │   │       └── codegen_panel.dart
│   │   └── codegen_panel.dart
│   │
│   └── log_viewer/                    # 日志查看 feature
│       ├── presentation/
│       │   ├── viewmodels/
│       │   │   └── log_viewmodel.dart
│       │   └── views/
│       │       ├── log_viewer.dart
│       │       └── segmented_filter.dart
│       └── log_viewer.dart
│
└── bootstrap/                         # 启动配置
    ├── providers/
    │   └── provider_setup.dart        # Provider 注入配置
    └── initialization/
        └── app_initialization.dart    # 应用初始化
```

### 2.2 层次职责

| 层级 | 职责 | 依赖规则 |
|------|------|----------|
| **Core** | 主题、工具类、常量 | 被所有层依赖，不依赖任何层 |
| **Shared** | 共享模型、通用组件、全局服务 | 仅依赖 Core，被 Features 依赖 |
| **Features** | 业务逻辑 | 仅依赖 Core + Shared |
| **Bootstrap** | 启动配置 | 依赖所有层 |

### 2.3 数据流

```
View (用户操作)
    ↓
ViewModel (状态管理)
    ↓
Service (业务编排)
    ↓
Repository (数据抽象)
    ↓
DataSource (数据源)
```

---

## 3. 执行计划

### 3.1 总体策略

- **渐进式迁移**：不一次性大重构，降低风险
- **保持可运行**：每个阶段后应用可正常运行
- **自动化工具**：使用脚本批量处理 import 更新

### 3.2 阶段划分

| 阶段 | 任务 | 预计时间 | 风险 |
|------|------|----------|------|
| 0 | 准备工作 | 30分钟 | 低 |
| 1 | 建立新结构 | 1小时 | 低 |
| 2 | 迁移 Core 层 | 1小时 | 低 |
| 3 | 迁移 Shared 层 | 2小时 | 中 |
| 4 | 迁移 Features 层 | 6-8小时 | 中 |
| 5 | 更新入口和清理 | 1小时 | 低 |
| 6 | 测试验证 | 2小时 | 中 |

**总计**：约 13-15 小时

---

## 4. 详细执行步骤

### 阶段 0：准备工作 (30分钟)

#### 0.1 创建备份分支

```bash
git checkout -b refactor/modular-architecture
git push -u origin refactor/modular-architecture
```

#### 0.2 验证当前状态

```bash
# 确保当前代码可运行
flutter pub get
flutter analyze
flutter test
```

#### 0.3 记录当前结构

```bash
# 创建快照文档
tree lib -L 3 > docs/current-structure.txt
```

#### 0.4 创建迁移脚本

创建 `scripts/migrate_imports.dart` 用于批量更新 import 路径。

---

### 阶段 1：建立新结构 (1小时)

#### 1.1 创建目录结构

```bash
# Core 层
mkdir -p lib/core/theme
mkdir -p lib/core/utils
mkdir -p lib/core/utils/extensions
mkdir -p lib/core/config

# Shared 层
mkdir -p lib/shared/widgets/segmented_control
mkdir -p lib/shared/widgets/loading_indicator
mkdir -p lib/shared/widgets/error_display
mkdir -p lib/shared/widgets/empty_state
mkdir -p lib/shared/models
mkdir -p lib/shared/services

# Features 层
mkdir -p lib/features/project_management/{domain/{entities,repositories},presentation/{viewmodels,views,widgets},services}
mkdir -p lib/features/device_management/{domain/{repositories},presentation/{viewmodels,widgets},services}
mkdir -p lib/features/run_control/{domain/{entities,repositories},data/datasources,presentation/{viewmodels,views,widgets},services}
mkdir -p lib/features/build_panel/{presentation/{viewmodels,views}}
mkdir -p lib/features/codegen_panel/{presentation/{viewmodels,views}}
mkdir -p lib/features/log_viewer/{presentation/{viewmodels,views}}

# Bootstrap 层
mkdir -p lib/bootstrap/{providers,initialization}
```

#### 1.2 创建 Barrel Export 文件

创建以下骨架文件：

```dart
// lib/core/core.dart
library core;

export 'theme/macos_theme.dart';
export 'utils/constants.dart';
```

```dart
// lib/shared/shared.dart
library shared;

// 将在迁移后填充
```

#### 1.3 验证结构

```bash
tree lib -L 3 -d
```

---

### 阶段 2：迁移 Core 层 (1小时)

#### 2.1 迁移主题

```bash
mv lib/theme/macos_theme.dart lib/core/theme/macos_theme.dart
```

#### 2.2 迁移工具类

```bash
mv lib/utils/constants.dart lib/core/utils/constants.dart
```

#### 2.3 创建新的工具类

```dart
// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print(error);
      }
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }
}
```

#### 2.4 更新 Core barrel export

```dart
// lib/core/core.dart
library core;

export 'theme/macos_theme.dart';
export 'utils/constants.dart';
export 'utils/logger.dart';
```

#### 2.5 更新所有引用

```bash
# 批量替换 import
find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/theme/|package:flutter_desk/core/theme/|g' {} \;

find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/utils/|package:flutter_desk/core/utils/|g' {} \;
```

#### 2.6 验证

```bash
flutter analyze
flutter run -d macos  # 快速验证
```

---

### 阶段 3：迁移 Shared 层 (2小时)

#### 3.1 迁移共享模型

```bash
mv lib/models/command_state.dart lib/shared/models/command_state.dart
mv lib/models/command_state.g.dart lib/shared/models/command_state.g.dart
mv lib/models/build_config.dart lib/shared/models/build_config.dart
mv lib/models/build_config.g.dart lib/shared/models/build_config.g.dart
mv lib/models/flutter_project.dart lib/shared/models/flutter_project.dart
mv lib/models/flutter_project.g.dart lib/shared/models/flutter_project.g.dart
mv lib/models/flutter_device.dart lib/shared/models/flutter_device.dart
mv lib/models/flutter_device.g.dart lib/shared/models/flutter_device.g.dart
```

#### 3.2 迁移共享服务

```bash
mv lib/services/storage_service.dart lib/shared/services/storage_service.dart
mv lib/services/tray_service.dart lib/shared/services/tray_service.dart
```

#### 3.3 更新 Shared barrel export

```dart
// lib/shared/shared.dart
library shared;

export 'models/command_state.dart';
export 'models/build_config.dart';
export 'models/flutter_project.dart';
export 'models/flutter_device.dart';
export 'services/storage_service.dart';
export 'services/tray_service.dart';
```

#### 3.4 更新所有引用

```bash
find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/models/|package:flutter_desk/shared/models/|g' {} \;

find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/services/storage_service|package:flutter_desk/shared/services/storage_service|g' {} \;

find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/services/tray_service|package:flutter_desk/shared/services/tray_service|g' {} \;
```

#### 3.5 重新生成序列化代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3.6 验证

```bash
flutter analyze
flutter test
```

---

### 阶段 4：迁移 Features 层 (6-8小时)

#### 4.1 迁移 project_management feature (2小时)

##### 4.1.1 移动文件

```bash
# ViewModel
mv lib/viewmodels/project_viewmodel.dart \
   lib/features/project_management/presentation/viewmodels/project_viewmodel.dart

# Views
mv lib/views/console_sidebar.dart \
   lib/features/project_management/presentation/views/console_sidebar.dart
mv lib/views/project_selector.dart \
   lib/features/project_management/presentation/views/project_selector.dart
```

##### 4.1.2 提取 domain 层

```dart
// lib/features/project_management/domain/repositories/project_repository.dart
import 'package:flutter_desk/shared/shared.dart';

abstract class ProjectRepository {
  Future<List<FlutterProject>> loadProjects();
  Future<bool> saveProject(FlutterProject project);
  Future<bool> removeProject(String path);
  Future<void> openInFinder(String path);
}
```

##### 4.1.3 创建 feature barrel export

```dart
// lib/features/project_management/project_management.dart
library project_management;

export 'domain/repositories/project_repository.dart';
export 'presentation/viewmodels/project_viewmodel.dart';
export 'presentation/views/console_sidebar.dart';
export 'presentation/views/project_selector.dart';
```

##### 4.1.4 更新引用

```bash
find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/viewmodels/project_viewmodel|package:flutter_desk/features/project_management/presentation/viewmodels/project_viewmodel|g' {} \;

find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/views/console_sidebar|package:flutter_desk/features/project_management/presentation/views/console_sidebar|g' {} \;
```

---

#### 4.2 迁移 device_management feature (1.5小时)

```bash
# ViewModel
mv lib/viewmodels/device_viewmodel.dart \
   lib/features/device_management/presentation/viewmodels/device_viewmodel.dart

# Service
mv lib/services/device_service.dart \
   lib/features/device_management/services/device_service.dart

# 更新引用
find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/viewmodels/device_viewmodel|package:flutter_desk/features/device_management/presentation/viewmodels/device_viewmodel|g' {} \;

find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/services/device_service|package:flutter_desk/features/device_management/services/device_service|g' {} \;
```

---

#### 4.3 迁移 run_control feature (2小时)

```bash
# ViewModel
mv lib/viewmodels/command_viewmodel.dart \
   lib/features/run_control/presentation/viewmodels/run_control_viewmodel.dart

# Views
mv lib/views/console_toolbar.dart \
   lib/features/run_control/presentation/views/console_toolbar.dart
mv lib/views/action_panel.dart \
   lib/features/run_control/presentation/views/action_panel.dart

# Service
mv lib/services/flutter_service.dart \
   lib/features/run_control/services/flutter_service.dart

# 更新引用
find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/viewmodels/command_viewmodel|package:flutter_desk/features/run_control/presentation/viewmodels/run_control_viewmodel|g' {} \;
```

---

#### 4.4 迁移 log_viewer feature (1.5小时)

```bash
# Views
mv lib/views/log_viewer.dart \
   lib/features/log_viewer/presentation/views/log_viewer.dart
mv lib/views/segmented_filter.dart \
   lib/features/log_viewer/presentation/widgets/segmented_filter.dart
mv lib/views/console_content_area.dart \
   lib/features/log_viewer/presentation/views/console_content_area.dart

# 更新引用
find lib -name "*.dart" -exec sed -i '' \
  's|package:flutter_desk/views/log_viewer|package:flutter_desk/features/log_viewer/presentation/views/log_viewer|g' {} \;
```

---

#### 4.5 迁移 build_panel feature (1小时)

```bash
mv lib/views/build_panel.dart \
   lib/features/build_panel/presentation/views/build_panel.dart
```

---

#### 4.6 迁移 codegen_panel feature (1小时)

```bash
mv lib/views/codegen_panel.dart \
   lib/features/codegen_panel/presentation/views/codegen_panel.dart
```

---

### 阶段 5：更新入口和清理 (1小时)

#### 5.1 创建 Provider 配置

```dart
// lib/bootstrap/providers/provider_setup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_desk/features/project_management/project_management.dart';
import 'package:flutter_desk/features/device_management/device_management.dart';
import 'package:flutter_desk/features/run_control/run_control.dart';
import 'package:flutter_desk/shared/shared.dart';

class ProviderSetup {
  static List<SingleChildWidget> getProviders() {
    return [
      // 全局服务
      Provider<StorageService>.value(value: StorageService()),

      // Project Management
      ChangeNotifierProxy2<StorageService, Object, ProjectViewModel>(
        create: (_) => ProjectViewModel(storageService: StorageService()),
        update: (_, __, viewModel) => viewModel!,
      ),

      // Device Management
      ChangeNotifierProvider(
        create: (_) => DeviceViewModel(deviceService: DeviceService()),
      ),

      // Run Control
      ChangeNotifierProvider(
        create: (_) => RunControlViewModel(flutterService: FlutterService()),
      ),
    ];
  }
}
```

#### 5.2 更新 main.dart

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_desk/core/core.dart';
import 'package:flutter_desk/bootstrap/providers/provider_setup.dart';
import 'package:flutter_desk/views/main_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  final storageService = StorageService();
  await storageService.initialize();

  runApp(const FlutterDeskApp());
}

class FlutterDeskApp extends StatelessWidget {
  const FlutterDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProviderSetup.getProviders(),
      child: MaterialApp(
        title: 'FlutterDesk',
        theme: MacOSTheme.lightTheme,
        darkTheme: MacOSTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainWindow(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

#### 5.3 删除旧目录

```bash
# 在确认所有功能正常后执行
rm -rf lib/models
rm -rf lib/viewmodels
rm -rf lib/views
rm -rf lib/services
rm -rf lib/theme
rm -rf lib/utils
```

---

### 阶段 6：测试验证 (2小时)

#### 6.1 静态分析

```bash
flutter analyze
```

#### 6.2 运行测试

```bash
flutter test
```

#### 6.3 手动功能测试清单

| 功能 | 测试项 | 状态 |
|------|--------|------|
| 项目管理 | 添加项目 | ⬜ |
| 项目管理 | 移除项目 | ⬜ |
| 项目管理 | 在 Finder 中显示 | ⬜ |
| 项目管理 | 切换选中项目 | ⬜ |
| 设备管理 | 检测设备 | ⬜ |
| 设备管理 | 刷新设备列表 | ⬜ |
| 设备管理 | 切换选中设备 | ⬜ |
| 运行控制 | 启动项目 | ⬜ |
| 运行控制 | 热重载 | ⬜ |
| 运行控制 | 热重启 | ⬜ |
| 运行控制 | 停止运行 | ⬜ |
| 日志查看 | 显示日志 | ⬜ |
| 日志查看 | 搜索日志 | ⬜ |
| 日志查看 | 过滤日志 | ⬜ |
| 主题 | 切换暗色模式 | ⬜ |

#### 6.4 构建验证

```bash
flutter build macos --debug
flutter build macos --release
```

---

## 5. 风险和缓解措施

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| Import 路径错误 | 编译失败 | 使用 sed 批量替换，编译验证 |
| JSON 序列化失败 | 运行时错误 | 重新运行 build_runner |
| 功能回归 | 用户受影响 | 每阶段后完整测试 |
| Git 冲突 | 协作受阻 | 使用独立分支，及时沟通 |

---

## 6. 回滚计划

如果迁移出现问题：

```bash
# 回滚到迁移前
git checkout main
git branch -D refactor/modular-architecture

# 或保留工作，回到稳定状态
git stash
git checkout main
```

---

## 7. 完成标准

- [ ] 所有文件迁移到新结构
- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 全部通过
- [ ] 手动功能测试全部通过
- [ ] Debug 和 Release 构建成功
- [ ] 文档更新（README.md、CLAUDE.md）

---

## 8. 附录

### 8.1 迁移脚本

```dart
// scripts/migrate_imports.dart
import 'dart:io';

void main() {
  final mappings = {
    'package:flutter_desk/theme/': 'package:flutter_desk/core/theme/',
    'package:flutter_desk/utils/': 'package:flutter_desk/core/utils/',
    'package:flutter_desk/models/': 'package:flutter_desk/shared/models/',
    // ... 添加更多映射
  };

  final libDir = Directory('lib');
  for (var entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      migrateFile(entity, mappings);
    }
  }
}

void migrateFile(File file, Map<String, String> mappings) {
  var content = file.readAsStringSync();
  mappings.forEach((old, new) {
    content = content.replaceAll(old, new);
  });
  file.writeAsStringSync(content);
}
```

### 8.2 参考资料

- [Flutter架构指南](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture/)
- [DDD Directory Structure](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)

---

**文档结束**
