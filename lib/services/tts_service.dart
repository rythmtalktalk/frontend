import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  // TTS 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 언어 설정 (한국어)
      await _flutterTts.setLanguage("ko-KR");

      // 음성 속도 설정 (0.0 ~ 1.0)
      await _flutterTts.setSpeechRate(0.5);

      // 음량 설정 (0.0 ~ 1.0) - 최대 볼륨으로 설정
      await _flutterTts.setVolume(1.0);

      // 음성 높낮이 설정 (0.5 ~ 2.0)
      await _flutterTts.setPitch(1.0);

      // iOS 설정
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      // 이벤트 리스너 설정
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        print("TTS 시작");
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        print("TTS 완료");
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        print("TTS 오류: $msg");
      });

      _isInitialized = true;
      print("TTS 초기화 완료");
    } catch (e) {
      print("TTS 초기화 실패: $e");
    }
  }

  // 텍스트 음성 변환
  Future<bool> speak(String text) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isSpeaking) {
        await stop();
      }

      if (text.isEmpty) return false;

      print("TTS 재생: $text");
      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      print("TTS 재생 실패: $e");
      return false;
    }
  }

  // 음성 중지
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print("TTS 중지 실패: $e");
    }
  }

  // 일시정지
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
    } catch (e) {
      print("TTS 일시정지 실패: $e");
    }
  }

  // 사용 가능한 언어 목록
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      print("언어 목록 가져오기 실패: $e");
      return [];
    }
  }

  // 사용 가능한 음성 목록
  Future<List<Map<String, String>>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      print("음성 목록 가져오기 실패: $e");
      return [];
    }
  }

  // 음성 속도 설정
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      print("음성 속도 설정 실패: $e");
    }
  }

  // 음량 설정
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print("음량 설정 실패: $e");
    }
  }

  // 음성 높낮이 설정
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      print("음성 높낮이 설정 실패: $e");
    }
  }

  // 리소스 해제
  void dispose() {
    _flutterTts.stop();
  }
}
