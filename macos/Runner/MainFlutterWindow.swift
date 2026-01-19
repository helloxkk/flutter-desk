import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Configure window for VS Code style
    self.title = "FlutterDesk"
    self.titlebarAppearsTransparent = true  // 透明标题栏
    self.titleVisibility = .hidden  // 隐藏标题
    self.isMovableByWindowBackground = true  // 可通过背景拖动窗口

    // Enable full-size content view to extend content into titlebar area
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]

    // Ensure traffic light buttons are visible
    self.standardWindowButton(.closeButton)?.isHidden = false
    self.standardWindowButton(.miniaturizeButton)?.isHidden = false
    self.standardWindowButton(.zoomButton)?.isHidden = false

    // Set minimum size
    self.minSize = NSSize(width: 800, height: 200)

    // Set initial size (Console style: wider and shorter)
    self.setContentSize(NSSize(width: 1000, height: 500))

    super.awakeFromNib()
  }
}
