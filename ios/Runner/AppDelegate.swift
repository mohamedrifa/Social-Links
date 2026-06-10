import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      configureAppAvailabilityChannel(controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func configureAppAvailabilityChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "social_link/app_availability",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getInstalledPlatforms":
        result(self.installedPlatforms())
      case "canOpenScheme":
        guard
          let args = call.arguments as? [String: Any],
          let scheme = args["scheme"] as? String
        else {
          result(false)
          return
        }
        result(self.canOpenScheme(scheme))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func installedPlatforms() -> [String] {
    let platformSchemes: [String: [String]] = [
      "facebook": ["fb", "facebook"],
      "twitter": ["twitter", "x"],
      "instagram": ["instagram"],
      "whatsapp": ["whatsapp"],
      "telegram": ["tg"],
      "linkedin": ["linkedin"],
      "pinterest": ["pinterest"],
      "tiktok": ["tiktok"],
      "snapchat": ["snapchat"],
      "reddit": ["reddit"],
      "youtube": ["youtube"],
      "wechat": ["wechat", "weixin"],
      "email": ["mailto"]
    ]

    return platformSchemes.compactMap { platform, schemes in
      schemes.contains(where: canOpenScheme) ? platform : nil
    }
  }

  private func canOpenScheme(_ scheme: String) -> Bool {
    guard let url = URL(string: "\(scheme):") else {
      return false
    }
    return UIApplication.shared.canOpenURL(url)
  }
}
