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

    // Calculate button positions
    // Card position in Flutter: left=8, top=8, width=168, height=28
    let cardLeft: CGFloat = 8
    let cardTop: CGFloat = 8
    let cardHeight: CGFloat = 28
    let buttonHeight = closeButton.frame.height
    let buttonSpacing: CGFloat = 52

    // Calculate Y position to center buttons in card
    let buttonY = cardTop + (cardHeight - buttonHeight) / 2

    // Position buttons using setFrame
    closeButton.setFrameOrigin(NSPoint(x: cardLeft + 12, y: buttonY))
    miniaturizeButton.setFrameOrigin(NSPoint(x: cardLeft + 12 + buttonSpacing, y: buttonY))
    zoomButton.setFrameOrigin(NSPoint(x: cardLeft + 12 + buttonSpacing * 2, y: buttonY))

    print("Traffic lights positioned at: close=\(closeButton.frame.origin), mini=\(miniaturizeButton.frame.origin), zoom=\(zoomButton.frame.origin)")
  }
}
