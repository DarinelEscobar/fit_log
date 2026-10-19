import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "fit_log/timezone", binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { call, result in
          if call.method == "getTimeZone" { result(TimeZone.current.identifier) }
          else { result(FlutterMethodNotImplemented) }
        }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
