import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // MARK: - Tray Menu Properties
  /// 当前托盘菜单状态
  private var currentStatus: String = "idle"
  private var currentProject: String = ""
  private var currentDevice: String = ""
  private var currentDeviceIcon: String = ""  // 设备图标
  private var isRunning: Bool = false
  private var statusItem: NSStatusItem?
  private var methodChannel: FlutterMethodChannel?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app running when window is closed (for menu bar style)
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Get Flutter ViewController
    guard let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }

    // Setup tray menu
    setupTrayMenu(with: flutterViewController)
  }

  // MARK: - Tray Menu Setup

  /// 初始化托盘菜单
  private func setupTrayMenu(with viewController: FlutterViewController) {
    // 创建状态栏项
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    updateStatusBarIcon()

    // 设置 MethodChannel
    let channelName = "com.drivensmart.flutter-manager/tray"
    methodChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: viewController.engine.binaryMessenger
    )
    methodChannel?.setMethodCallHandler(handleTrayMethodCall)

    // 初始化菜单
    rebuildMenu()
  }

  /// 处理来自 Flutter 的方法调用
  private func handleTrayMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateState":
      if let args = call.arguments as? [String: Any] {
        updateState(args)
        result(nil)
      } else {
        result(FlutterError(code: "invalid_args", message: "Invalid arguments", details: nil))
      }
    case "showMainWindow":
      showMainWindow()
      result(nil)
    case "hideMainWindow":
      hideMainWindow()
      result(nil)
    case "quitApp":
      NSApp.terminate(nil)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 更新状态
  private func updateState(_ state: [String: Any]) {
    currentStatus = state["status"] as? String ?? "idle"
    currentProject = state["project"] as? String ?? ""
    currentDevice = state["device"] as? String ?? ""
    currentDeviceIcon = state["deviceIcon"] as? String ?? ""
    isRunning = state["isRunning"] as? Bool ?? false

    rebuildMenu()
  }

  /// 更新状态栏图标（固定为 📱）
  private func updateStatusBarIcon() {
    guard let button = statusItem?.button else { return }
    button.title = "📱"
    button.action = #selector(showTrayMenu)
    button.target = self
  }

  /// 显示托盘菜单
  @objc private func showTrayMenu() {
    // 重建菜单以确保状态最新
    rebuildMenu()
    // 触发菜单显示
    statusItem?.button?.performClick(nil)
  }

  /// 构建菜单
  private func rebuildMenu() {
    let menu = NSMenu()

    // 标题行
    let titleItem = NSMenuItem()
    let statusText = isRunning ? "● Running" : ""
    titleItem.title = "📱  Flutter Manager    \(statusText)"
    menu.addItem(titleItem)

    menu.addItem(NSMenuItem.separator())

    // 项目和设备信息
    if !currentProject.isEmpty {
      let projectItem = NSMenuItem()
      projectItem.title = "项目: \(currentProject)"
      menu.addItem(projectItem)
    }

    if !currentDevice.isEmpty {
      let deviceItem = NSMenuItem()
      deviceItem.title = "设备: \(currentDeviceIcon) \(currentDevice)"
      menu.addItem(deviceItem)
    }

    if !currentProject.isEmpty || !currentDevice.isEmpty {
      menu.addItem(NSMenuItem.separator())
    }

    // 运行操作
    menu.addItem(createMenuItem(
      title: "▶️  运行项目",
      action: #selector(runProject),
      keyEquivalent: "r",
      isEnabled: !isRunning
    ))

    menu.addItem(createMenuItem(
      title: "🔄  热重载",
      action: #selector(hotReload),
      keyEquivalent: "s",
      isEnabled: isRunning
    ))

    menu.addItem(createMenuItem(
      title: "🔃  热重启",
      action: #selector(hotRestart),
      keyEquivalent: "R",
      isEnabled: isRunning
    ))

    menu.addItem(createMenuItem(
      title: "⏹️  停止运行",
      action: #selector(stopProject),
      keyEquivalent: "q",
      isEnabled: isRunning
    ))

    menu.addItem(NSMenuItem.separator())

    // 省口操作
    menu.addItem(createMenuItem(
      title: "📊  打开仪表板",
      action: #selector(showMainWindow),
      keyEquivalent: "d",
      isEnabled: true
    ))

    menu.addItem(NSMenuItem.separator())

    // 退出
    menu.addItem(createMenuItem(
      title: "❌  退出应用",
      action: #selector(quitApp),
      keyEquivalent: "q",
      isEnabled: true
    ))

    statusItem?.menu = menu
  }

  /// 创建菜单项
  private func createMenuItem(
    title: String,
    action: Selector?,
    keyEquivalent: String,
    isEnabled: Bool
  ) -> NSMenuItem {
    let item = NSMenuItem(
      title: title,
      action: action,
      keyEquivalent: keyEquivalent
    )
    item.target = self
    item.isEnabled = isEnabled
    return item
  }

  // MARK: - Menu Actions

  /// 运行项目
  @objc private func runProject() {
    methodChannel?.invokeMethod("runProject", arguments: nil) { result in
      if let error = result as? FlutterError {
        print("Failed to run project: \(error)")
      }
    }
  }

  /// 热重载
  @objc private func hotReload() {
    methodChannel?.invokeMethod("hotReload", arguments: nil) { result in
      if let error = result as? FlutterError {
        print("Failed to hot reload: \(error)")
      }
    }
  }

  /// 热重启
  @objc private func hotRestart() {
    methodChannel?.invokeMethod("hotRestart", arguments: nil) { result in
      if let error = result as? FlutterError {
        print("Failed to hot restart: \(error)")
      }
    }
  }

  /// 停止运行
  @objc private func stopProject() {
    methodChannel?.invokeMethod("stopProject", arguments: nil) { result in
      if let error = result as? FlutterError {
        print("Failed to stop project: \(error)")
      }
    }
  }

  /// 显示主窗口
  @objc private func showMainWindow() {
    guard let window = NSApp.windows.first else { return }

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    // 通知 Flutter 层窗口已显示
    methodChannel?.invokeMethod("windowShown", arguments: nil)
  }

  /// 隐藏主窗口
  func hideMainWindow() {
    guard let window = NSApp.windows.first else { return }
    window.orderOut(nil)
  }

  /// 退出应用
  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}
