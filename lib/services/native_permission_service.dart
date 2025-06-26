import 'package:flutter/services.dart';
import 'dart:io';

class NativePermissionService {
  static const MethodChannel _channel = MethodChannel(
    'com.rythmtalk.app/permissions',
  );

  /// 마이크 권한 요청 (iOS 네이티브)
  static Future<bool> requestMicrophonePermission() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod(
        'requestMicrophonePermission',
      );
      print('iOS 네이티브 마이크 권한 요청 결과: $result');
      return result;
    } catch (e) {
      print('iOS 네이티브 마이크 권한 요청 실패: $e');
      return false;
    }
  }

  /// 음성 인식 권한 요청 (iOS 네이티브)
  static Future<bool> requestSpeechRecognitionPermission() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod(
        'requestSpeechRecognitionPermission',
      );
      print('iOS 네이티브 음성 인식 권한 요청 결과: $result');
      return result;
    } catch (e) {
      print('iOS 네이티브 음성 인식 권한 요청 실패: $e');
      return false;
    }
  }

  /// 모든 권한 요청 (iOS 네이티브)
  static Future<bool> requestAllPermissions() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('requestAllPermissions');
      print('iOS 네이티브 모든 권한 요청 결과: $result');
      return result;
    } catch (e) {
      print('iOS 네이티브 모든 권한 요청 실패: $e');
      return false;
    }
  }
}
