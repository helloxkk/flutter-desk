import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Configure window for VS Code style with unified titlebar
    self.title = "FlutterDesk"
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = true

    // Enable full-size content view to extend content into titlebar area
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]

    // Ensure buttons are visible
    self.standardWindowButton(.closeButton)?.isHidden = false
    self.standardWindowButton(.miniaturizeButton)?.isHidden = false
    self.standardWindowButton(.zoomButton)?.isHidden = false

    // Position the traffic light buttons after layout is complete
    DispatchQueue.main.async {
      self.positionTrafficLights()
    }

    // Set minimum size
    self.minSize = NSSize(width: 800, height: 200)

    // Set initial size (Console style: wider and shorter)
    self.setContentSize(NSSize(width: 1000, height: 500))

    super.awakeFromNib()
  }

  private func positionTrafficLights() {
    guard let closeButton = self.standardWindowButton(.closeButton),
          let miniaturizeButton = self.standardWindowButton(.miniaturizeButton),
          let zoomButton = self.standardWindowButton(.zoomButton) else {
      return
    }

    // Position traffic lights to appear inside the sidebar card
    // X: 24px from left edge
    // Y: Fixed position from top (will be adjusted dynamically on window resize)
    let buttonSpacing: CGFloat = 52
    let buttonX: CGFloat = 24

    // Position from top, convert to bottom-origin coordinate system
    // For a 500px window, we want button at Y=476 (24px from top)
    // Formula: windowHeight - desiredTopPosition
    let desiredTopPosition: CGFloat = 24
    let buttonY: CGFloat = self.frame.height - desiredTopPosition

    closeButton.setFrameOrigin(NSPoint(x: buttonX, y: buttonY))
    miniaturizeButton.setFrameOrigin(NSPoint(x: buttonX + buttonSpacing, y: buttonY))
    zoomButton.setFrameOrigin(NSPoint(x: buttonX + buttonSpacing * 2, y: buttonY))

    print("Traffic lights positioned: x=\(buttonX), y=\(buttonY), window height=\(self.frame.height)")
  }
}
