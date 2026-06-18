import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var pendingFilePath: String?
  private var fileOpenerChannel: FlutterMethodChannel?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }

    fileOpenerChannel = FlutterMethodChannel(
      name: "com.staler2019.epud_image_extractor/file_opener",
      binaryMessenger: controller.engine.binaryMessenger
    )

    fileOpenerChannel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialFilePath" {
        result(self?.pendingFilePath)
        self?.pendingFilePath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Called when the OS asks this app to open one or more files (Finder "Open With",
  // double-click, or set-as-default). On cold launch this fires before
  // applicationDidFinishLaunching, so the channel may not exist yet — in that
  // case the path is held in pendingFilePath and returned on getInitialFilePath.
  override func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first, url.pathExtension.lowercased() == "epub" else { return }
    let path = url.path
    if let channel = fileOpenerChannel {
      channel.invokeMethod("fileOpened", arguments: path)
    } else {
      pendingFilePath = path
    }
  }
}
