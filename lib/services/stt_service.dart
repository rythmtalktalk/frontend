import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'native_permission_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PronunciationAnalysis {
  final String originalText;
  final String recognizedText;
  final double overallScore;
  final Map<String, double> wordAccuracies;
  final String feedback;

  PronunciationAnalysis({
    required this.originalText,
    required this.recognizedText,
    required this.overallScore,
    required this.wordAccuracies,
    required this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'recognizedText': recognizedText,
      'overallScore': overallScore,
      'wordAccuracies': wordAccuracies,
      'feedback': feedback,
    };
  }

  factory PronunciationAnalysis.fromMap(Map<String, dynamic> map) {
    return PronunciationAnalysis(
      originalText: map['originalText'] ?? '',
      recognizedText: map['recognizedText'] ?? '',
      overallScore: (map['overallScore'] ?? 0.0).toDouble(),
      wordAccuracies: Map<String, double>.from(map['wordAccuracies'] ?? {}),
      feedback: map['feedback'] ?? '',
    );
  }
}

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  static const String _apiKey = String.fromEnvironment('GOOGLE_API_KEY');
  static const String _baseUrl =
      'https://speech.googleapis.com/v1/speech:recognize';

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;

  // STT 초기화
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print('STT Status: $status');
          _isListening = status == 'listening';
        },
        onError: (error) {
          print('STT Error: $error');
          _isListening = false;
        },
      );
      return _isAvailable;
    } catch (e) {
      print('STT 초기화 실패: $e');
      return false;
    }
  }

  // 권한 요청 - iOS와 Android 모두 지원
  Future<bool> requestPermissions() async {
    try {
      print('=== 권한 요청 시작 ===');

      // iOS에서는 네이티브 권한 요청 먼저 시도
      if (Platform.isIOS) {
        print('iOS - 네이티브 권한 요청 시도');
        final nativeResult =
            await NativePermissionService.requestAllPermissions();
        if (nativeResult) {
          print('iOS 네이티브 권한 요청 성공');
          return true;
        }
        print('iOS 네이티브 권한 요청 실패 - permission_handler로 재시도');
      }

      // permission_handler를 사용한 권한 요청 (Android 또는 iOS 네이티브 실패 시)
      var microphonePermission = await Permission.microphone.status;
      print('현재 마이크 권한 상태: $microphonePermission');

      if (microphonePermission.isDenied) {
        microphonePermission = await Permission.microphone.request();
        print('마이크 권한 요청 결과: $microphonePermission');
      }

      // 음성 인식 권한도 확인 (Android)
      if (Platform.isAndroid) {
        var speechPermission = await Permission.speech.status;
        print('현재 음성 인식 권한 상태: $speechPermission');

        if (speechPermission.isDenied) {
          speechPermission = await Permission.speech.request();
          print('음성 인식 권한 요청 결과: $speechPermission');
        }
      }

      // 권한이 영구적으로 거부된 경우
      if (microphonePermission.isPermanentlyDenied) {
        print('마이크 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
        await openAppSettings();
        return false;
      }

      // 권한 확인
      final isGranted = microphonePermission.isGranted;
      print('최종 권한 상태: $isGranted');
      return isGranted;
    } catch (e) {
      print("권한 요청 실패: $e");
      return false;
    }
  }

  /// 오디오 파일을 Google Speech-to-Text API로 분석
  Future<String> transcribeAudioFile(String audioFilePath) async {
    try {
      // 오디오 파일을 base64로 인코딩
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        throw Exception('오디오 파일을 찾을 수 없습니다: $audioFilePath');
      }

      final audioBytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      // Google Speech-to-Text API 요청
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'config': {
            'encoding': 'WEBM_OPUS', // 또는 'MP3', 'WAV' 등 실제 파일 형식에 맞게
            'sampleRateHertz': 48000,
            'languageCode': 'ko-KR',
            'enableAutomaticPunctuation': false,
            'model': 'latest_short',
          },
          'audio': {'content': base64Audio},
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['results'] != null &&
            responseData['results'].isNotEmpty &&
            responseData['results'][0]['alternatives'] != null &&
            responseData['results'][0]['alternatives'].isNotEmpty) {
          final transcript =
              responseData['results'][0]['alternatives'][0]['transcript'];
          debugPrint('STT 결과: $transcript');
          return transcript.trim();
        } else {
          debugPrint('STT 결과가 없습니다.');
          return '';
        }
      } else {
        debugPrint('STT API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('음성 인식에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('STT 오류: $e');
      // 개발 중에는 에러 대신 빈 문자열 반환
      return '';
    }
  }

  // 실시간 음성 인식 시작
  Future<String?> startListening({
    required String expectedText,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isAvailable) {
      await initialize();
    }

    if (!_isAvailable) {
      return null;
    }

    String recognizedText = '';

    try {
      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          print('인식된 텍스트: $recognizedText');
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'ko_KR', // 한국어 설정
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // 리스닝이 완료될 때까지 대기
      while (_isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return recognizedText.isNotEmpty ? recognizedText : null;
    } catch (e) {
      print('실시간 STT 실패: $e');
      return null;
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // 음성 인식 취소
  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
      _confidence = 0.0;
      print("음성 인식 취소");
    } catch (e) {
      print("음성 인식 취소 실패: $e");
    }
  }

  // 사용 가능한 언어 목록
  Future<List<stt.LocaleName>> getLocales() async {
    try {
      if (!_isAvailable) {
        await initialize();
      }
      return await _speech.locales();
    } catch (e) {
      print("언어 목록 가져오기 실패: $e");
      return [];
    }
  }

  // 한국어 언어 확인
  Future<bool> hasKoreanSupport() async {
    try {
      final locales = await getLocales();
      return locales.any(
        (locale) =>
            locale.localeId.startsWith('ko') ||
            (locale.name?.contains('Korean') ?? false) ||
            (locale.name?.contains('한국') ?? false),
      );
    } catch (e) {
      print("한국어 지원 확인 실패: $e");
      return false;
    }
  }

  /// 두 텍스트 간의 유사도를 계산 (레벤슈타인 거리 기반)
  double calculateSimilarity(String original, String recognized) {
    if (original.isEmpty && recognized.isEmpty) return 1.0;
    if (original.isEmpty || recognized.isEmpty) return 0.0;

    // 공백과 특수문자 제거하고 소문자로 변환
    final cleanOriginal = _cleanText(original);
    final cleanRecognized = _cleanText(recognized);

    final distance = _levenshteinDistance(cleanOriginal, cleanRecognized);
    final maxLength = [
      cleanOriginal.length,
      cleanRecognized.length,
    ].reduce((a, b) => a > b ? a : b);

    if (maxLength == 0) return 1.0;

    final similarity = 1.0 - (distance / maxLength);
    return similarity.clamp(0.0, 1.0);
  }

  /// 텍스트 정리 (공백, 특수문자 제거)
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w가-힣]'), '') // 한글, 영문, 숫자만 남김
        .toLowerCase()
        .trim();
  }

  /// 레벤슈타인 거리 계산
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // 삭제
          matrix[i][j - 1] + 1, // 삽입
          matrix[i - 1][j - 1] + cost, // 치환
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// 단어별 정확도 분석
  Map<String, double> _analyzeWordAccuracies(
    String original,
    String recognized,
  ) {
    final originalWords = original
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final recognizedWords = recognized
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    final wordAccuracies = <String, double>{};

    for (int i = 0; i < originalWords.length; i++) {
      final originalWord = originalWords[i];

      if (i < recognizedWords.length) {
        final recognizedWord = recognizedWords[i];
        final accuracy = calculateSimilarity(originalWord, recognizedWord);
        wordAccuracies[originalWord] = accuracy;
      } else {
        // 인식되지 않은 단어
        wordAccuracies[originalWord] = 0.0;
      }
    }

    return wordAccuracies;
  }

  /// 피드백 메시지 생성 (모든 경우에 긍정적)
  String _generateFeedback(double score, Map<String, double> wordAccuracies) {
    if (score >= 0.9) {
      return '🎉 정말 잘했어요! 최고예요!';
    } else if (score >= 0.8) {
      return '👍 잘했어요! 훌륭해요!';
    } else if (score >= 0.7) {
      return '😊 잘했어요! 멋져요!';
    } else if (score >= 0.5) {
      return '💪 잘했어요! 계속해봐요!';
    } else {
      return '🌟 잘했어요! 좋아요!';
    }
  }

  /// 발음 분석 수행
  Future<PronunciationAnalysis> analyzePronunciation(
    String audioFilePath,
    String expectedText,
  ) async {
    try {
      // STT로 음성을 텍스트로 변환
      final recognizedText = await transcribeAudioFile(audioFilePath);

      // 유사도 계산
      final overallScore = calculateSimilarity(expectedText, recognizedText);

      // 단어별 정확도 분석
      final wordAccuracies = _analyzeWordAccuracies(
        expectedText,
        recognizedText,
      );

      // 피드백 생성
      final feedback = _generateFeedback(overallScore, wordAccuracies);

      debugPrint('발음 분석 완료:');
      debugPrint('- 원본: $expectedText');
      debugPrint('- 인식: $recognizedText');
      debugPrint('- 점수: ${(overallScore * 100).toInt()}점');

      return PronunciationAnalysis(
        originalText: expectedText,
        recognizedText: recognizedText,
        overallScore: overallScore,
        wordAccuracies: wordAccuracies,
        feedback: feedback,
      );
    } catch (e) {
      debugPrint('발음 분석 오류: $e');

      // 오류 발생 시 기본값 반환
      return PronunciationAnalysis(
        originalText: expectedText,
        recognizedText: '',
        overallScore: 0.5, // 기본 점수
        wordAccuracies: {},
        feedback: '잘했어요! 계속해봐요!',
      );
    }
  }

  // 발음 평가
  Map<String, dynamic> evaluatePronunciation(
    String original,
    String recognized,
  ) {
    final similarity = calculateSimilarity(original, recognized);

    String grade;
    if (similarity >= 0.9) {
      grade = '우수';
    } else if (similarity >= 0.7) {
      grade = '좋음';
    } else if (similarity >= 0.5) {
      grade = '보통';
    } else {
      grade = '연습필요';
    }

    return {
      'similarity': similarity,
      'percentage': (similarity * 100).toStringAsFixed(1),
      'grade': grade,
      'original': original,
      'recognized': recognized,
      'confidence': _confidence,
    };
  }

  void dispose() {
    _speech.cancel();
  }
}
