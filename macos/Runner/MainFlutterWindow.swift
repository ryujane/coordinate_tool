import macos_window_utils
import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
      let windowFrame = self.frame
      let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
      self.contentViewController = macOSWindowUtilsViewController
      self.setFrame(windowFrame, display: true)

      /* Initialize the macos_window_utils plugin */
      MainFlutterWindowManipulator.start(mainFlutterWindow: self)

      RegisterGeneratedPlugins(registry: macOSWindowUtilsViewController.flutterViewController)
    super.awakeFromNib()
  }
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
      super.order(place, relativeTo: otherWin)
      hiddenWindowAtLaunch()
  }
}
