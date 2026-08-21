import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "AtaaSharePlugin") {
      let channel = FlutterMethodChannel(
        name: "ataa/share",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "shareFile" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "Missing file path", details: nil))
          return
        }
        self?.shareFile(path: path)
        result(nil)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func shareFile(path: String) {
    let url = URL(fileURLWithPath: path)
    let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    guard let root = window?.rootViewController else { return }
    if let popover = controller.popoverPresentationController {
      popover.sourceView = root.view
      popover.sourceRect = CGRect(
        x: root.view.bounds.midX,
        y: root.view.bounds.midY,
        width: 0,
        height: 0
      )
    }
    root.present(controller, animated: true)
  }
}
