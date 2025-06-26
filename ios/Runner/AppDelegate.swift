import Flutter
import UIKit
import AVFoundation
import Speech

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let permissionChannel = FlutterMethodChannel(name: "com.rythmtalk.app/permissions",
                                                binaryMessenger: controller.binaryMessenger)
    
    permissionChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      switch call.method {
      case "requestMicrophonePermission":
        self.requestMicrophonePermission(result: result)
      case "requestSpeechRecognitionPermission":
        self.requestSpeechRecognitionPermission(result: result)
      case "requestAllPermissions":
        self.requestAllPermissions(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func requestMicrophonePermission(result: @escaping FlutterResult) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }
  
  private func requestSpeechRecognitionPermission(result: @escaping FlutterResult) {
    SFSpeechRecognizer.requestAuthorization { authStatus in
      DispatchQueue.main.async {
        switch authStatus {
        case .authorized:
          result(true)
        case .denied, .restricted, .notDetermined:
          result(false)
        @unknown default:
          result(false)
        }
      }
    }
  }
  
  private func requestAllPermissions(result: @escaping FlutterResult) {
    // 먼저 마이크 권한 요청
    AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
      if micGranted {
        // 마이크 권한이 허용되면 음성 인식 권한 요청
        SFSpeechRecognizer.requestAuthorization { speechStatus in
          DispatchQueue.main.async {
            let speechGranted = speechStatus == .authorized
            result(micGranted && speechGranted)
          }
        }
      } else {
        DispatchQueue.main.async {
          result(false)
        }
      }
    }
  }
}
