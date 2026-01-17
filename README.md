# FlutterDesk

<div align="center">

**Flutter 项目管理工具 - macOS 原生应用**

[![Flutter](https://img.shields.io/badge/Flutter-3.6.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?logo=apple)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> 快速管理 Flutter 项目的桌面工具

[功能特性](#功能特性) • [安装](#安装) • [使用指南](#使用指南) • [开发](#开发) • [贡献](#贡献)

</div>

---

## ✨ 功能特性

### 🚀 快速运行
- 支持多个设备同时运行 Flutter 项目
- 一键热重载/热重启
- 自动检测可用的 Flutter 设备

### 📦 构建管理
- 支持 APK/IPA/AppBundle 构建
- 支持 macOS/Windows/Linux/Web 桌面平台构建
- Debug/Release 模式切换
- 构建产物一键打开

### 🔨 代码生成
- build_runner build/clean/watch
- 实时日志输出
- 支持 delete-conflicting-outputs

### 🧹 项目管理
- Flutter clean 清理构建产物
- pub get 管理依赖
- pub upgrade 升级依赖
- pub outdated 检查过期依赖

### 📋 日志查看
- 实时日志流式输出
- 多种过滤选项（全部/错误/警告/信息/Flutter）
- 日志搜索功能
- 日志数量限制防止内存溢出

### 🎨 macOS 原生体验
- 原生 macOS 界面风格
- 状态栏图标快速切换
- 响应式暗色模式
- 流畅的动画效果

## 📸 截图

<img src="screenshots/main-window.png" width="800" alt="主窗口">

## 📥 安装

### 前置要求
- macOS 13.0 或更高版本
- Flutter 3.6.2 或更高版本
- Xcode (用于 macOS 构建)

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/helloxkk/flutter-desk.git
cd flutter-desk

# 获取依赖
flutter pub get

# 运行开发版本
flutter run -d macos

# 构建 Release 版本
flutter build macos --release
```

### 下载预编译版本

前往 [Releases](https://github.com/helloxkk/flutter-desk/releases) 页面下载最新的 `.app` 文件。

## 🚀 使用指南

### 添加项目
1. 点击项目选择器中的 "+" 按钮
2. 选择包含 `pubspec.yaml` 的 Flutter 项目目录
3. 项目将被保存并在下次启动时自动加载

### 运行项目
1. 选择要运行的 Flutter 项目
2. 选择目标设备（模拟器或真机）
3. 点击 "运行" 按钮
4. 使用热重载/热重启按钮快速更新

### 构建应用
1. 切换到 "构建" 面板
2. 选择构建平台（APK/IPA/macOS 等）
3. 选择 Debug 或 Release 模式
4. 点击 "构建" 按钮
5. 构建完成后点击 "打开输出" 查看产物

## 🛠️ 开发

### 技术栈
- **Flutter 3.6.2+** - 跨平台 UI 框架
- **Dart 3.0+** - 编程语言
- **Provider** - 状态管理
- **JSON Serializable** - JSON 序列化

### 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── build_config.dart     # 构建配置
│   ├── command_state.dart    # 命令状态
│   ├── flutter_project.dart  # 项目模型
│   └── flutter_device.dart   # 设备模型
├── viewmodels/               # 视图模型
│   ├── command_viewmodel.dart
│   ├── device_viewmodel.dart
│   └── project_viewmodel.dart
├── views/                    # UI 组件
│   ├── main_window.dart      # 主窗口
│   ├── build_panel.dart      # 构建面板
│   ├── codegen_panel.dart    # 代码生成面板
│   ├── action_panel.dart     # 操作面板
│   ├── device_selector.dart  # 设备选择器
│   ├── project_selector.dart # 项目选择器
│   └── log_viewer.dart       # 日志查看器
├── services/                 # 业务逻辑
│   ├── flutter_service.dart  # Flutter 命令执行
│   ├── device_service.dart   # 设备检测
│   ├── storage_service.dart  # 配置持久化
│   └── tray_service.dart     # 系统托盘
├── theme/                    # 主题
│   └── macos_theme.dart      # macOS 原生主题
└── utils/                    # 工具类
    └── constants.dart        # 常量定义
```

### 开发命令

```bash
# 运行开发版本
flutter run -d macos

# 分析代码
flutter analyze

# 运行测试
flutter test

# 格式化代码
dart format .

# 生成 JSON 序列化代码
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📝 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Provider](https://pub.dev/packages/provider) - 状态管理
- [macos_window_utils](https://pub.dev/packages/macos_window_utils) - macOS 窗口管理

## 📮 联系方式

- 作者 - [@helloxkk](https://github.com/helloxkk)
- 项目链接 - [https://github.com/helloxkk/flutter-desk](https://github.com/helloxkk/flutter-desk)

---

<div align="center">
**Made with ❤️ using Flutter**
</div>
