import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/user_activity.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';
import '../services/stt_service.dart';

class ActivityProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioService _audioService = AudioService();
  final STTService _sttService = STTService();

  List<MusicActivity> _todayActivities = [];
  List<MusicActivity> _popularActivities = [];
  MusicActivity? _currentActivity;
  UserActivity? _currentUserActivity;
  bool _isLoading = false;
  String? _error;
  bool _isRecording = false;
  String? _recordingPath;
  bool _isAnalyzing = false;

  // Getters
  List<MusicActivity> get activities => _todayActivities;
  List<MusicActivity> get todayActivities => _todayActivities;
  List<MusicActivity> get popularActivities => _popularActivities;
  MusicActivity? get currentActivity => _currentActivity;
  UserActivity? get currentUserActivity => _currentUserActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRecording => _isRecording;
  bool get isAnalyzing => _isAnalyzing;
  String? get recordingPath => _recordingPath;

  // 오늘의 활동 가져오기
  Future<void> loadTodayActivities() async {
    print('ActivityProvider: 오늘의 활동 로딩 시작');
    _setLoading(true);
    _error = null;

    try {
      _todayActivities = await _firebaseService.getTodayActivities();
      print('ActivityProvider: 오늘의 활동 로딩 완료 - ${_todayActivities.length}개');
      notifyListeners();
    } catch (e) {
      _error = '오늘의 활동을 불러오는데 실패했습니다: $e';
      print('ActivityProvider: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // 인기 활동 가져오기
  Future<void> loadPopularActivities() async {
    print('ActivityProvider: 인기 활동 로딩 시작');
    _setLoading(true);
    _error = null;

    try {
      _popularActivities = await _firebaseService.getPopularActivities();
      print('ActivityProvider: 인기 활동 로딩 완료 - ${_popularActivities.length}개');
      notifyListeners();
    } catch (e) {
      _error = '인기 활동을 불러오는데 실패했습니다: $e';
      print('ActivityProvider: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // 활동 선택
  void selectActivity(MusicActivity activity) {
    _currentActivity = activity;
    _initializeUserActivity();
    notifyListeners();
  }

  // 사용자 활동 초기화
  void _initializeUserActivity() {
    if (_currentActivity == null) return;

    final user = _firebaseService.currentUser;
    if (user == null) return;

    _currentUserActivity = UserActivity(
      id: '${user.uid}_${_currentActivity!.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      activityId: _currentActivity!.id,
      completedAt: DateTime.now(),
      isCompleted: false,
      blankAnswers: {},
      score: 0,
      parentFeedback: [],
    );
    notifyListeners();
  }

  // 음악 재생
  Future<bool> playCurrentMusic() async {
    if (_currentActivity == null) return false;
    return await _audioService.playMusic(_currentActivity!.audioUrl);
  }

  // 음악 정지
  Future<void> stopCurrentMusic() async {
    await _audioService.stopPlaying();
  }

  // 녹음 시작
  Future<bool> startRecording() async {
    final success = await _audioService.startRecording();
    if (success) {
      _isRecording = true;
      notifyListeners();
    }
    return success;
  }

  // 녹음 중지
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioService.stopRecording();
      if (path != null) {
        _recordingPath = path;

        // 실제 STT 분석 수행
        if (_currentActivity != null) {
          _isAnalyzing = true;
          notifyListeners();

          try {
            // 현재 활동의 가사를 사용하여 실제 발음 분석
            final analysis = await _sttService.analyzePronunciation(
              path,
              _currentActivity!.lyrics,
            );

            // 분석 결과를 UserActivity에 저장
            _currentUserActivity = _currentUserActivity?.copyWith(
              recordingUrl: path,
              recognizedText: analysis.recognizedText,
              pronunciationScore: (analysis.overallScore * 100).round(),
              wordAccuracies: analysis.wordAccuracies,
              pronunciationFeedback: analysis.feedback,
            );

            debugPrint('STT 분석 완료:');
            debugPrint('- 원본 가사: ${_currentActivity!.lyrics}');
            debugPrint('- 인식된 텍스트: ${analysis.recognizedText}');
            debugPrint('- 발음 점수: ${(analysis.overallScore * 100).round()}점');
          } catch (e) {
            debugPrint('STT 분석 오류: $e');
            // 오류 시 기본값 설정
            _currentUserActivity = _currentUserActivity?.copyWith(
              recordingUrl: path,
              recognizedText: '',
              pronunciationScore: 50,
              pronunciationFeedback: '잘했어요! 계속해봐요!',
            );
          } finally {
            _isAnalyzing = false;
          }
        }
      }
    } catch (e) {
      debugPrint('녹음 중지 오류: $e');
    }

    _isRecording = false;
    notifyListeners();
  }

  // 녹음 재생
  Future<bool> playRecording() async {
    return await _audioService.playRecording();
  }

  // 빈칸 답변 추가
  void addBlankAnswer(String questionKey, String answer) {
    if (_currentUserActivity == null) return;

    final updatedAnswers = Map<String, String>.from(
      _currentUserActivity!.blankAnswers,
    );
    updatedAnswers[questionKey] = answer;

    _currentUserActivity = UserActivity(
      id: _currentUserActivity!.id,
      userId: _currentUserActivity!.userId,
      activityId: _currentUserActivity!.activityId,
      completedAt: _currentUserActivity!.completedAt,
      isCompleted: _currentUserActivity!.isCompleted,
      recordingUrl: _currentUserActivity!.recordingUrl,
      blankAnswers: updatedAnswers,
      score: _currentUserActivity!.score,
      parentFeedback: _currentUserActivity!.parentFeedback,
      stickers: _currentUserActivity!.stickers,
    );
    notifyListeners();
  }

  // 활동 완료
  Future<bool> completeActivity() async {
    if (_currentUserActivity == null) return false;

    final completedActivity = UserActivity(
      id: _currentUserActivity!.id,
      userId: _currentUserActivity!.userId,
      activityId: _currentUserActivity!.activityId,
      completedAt: DateTime.now(),
      isCompleted: true,
      recordingUrl: _currentUserActivity!.recordingUrl,
      blankAnswers: _currentUserActivity!.blankAnswers,
      score: _calculateScore(),
      parentFeedback: _currentUserActivity!.parentFeedback,
      stickers: 1,
    );

    final success = await _firebaseService.saveUserActivity(completedActivity);
    if (success) {
      _currentUserActivity = completedActivity;
      notifyListeners();
    }

    return success;
  }

  // 점수 계산
  int _calculateScore() {
    if (_currentUserActivity == null || _currentActivity == null) return 0;

    final totalQuestions = _currentActivity!.blanks.length;
    final answeredQuestions = _currentUserActivity!.blankAnswers.length;
    final hasRecording = _currentUserActivity!.recordingUrl != null;
    final pronunciationScore = _currentUserActivity!.pronunciationScore ?? 0;

    int score = 0;

    // 빈칸 답변 점수 (40%)
    if (totalQuestions > 0) {
      score += ((answeredQuestions / totalQuestions) * 40).round();
    }

    // 녹음 완료 점수 (20%)
    if (hasRecording) {
      score += 20;
    }

    // 발음 점수 (40%)
    score += (pronunciationScore * 0.4).round();

    return score.clamp(0, 100);
  }

  // 점수 계산 (실제 STT 분석 결과 반영)
  Map<String, int> _calculateDetailedScores() {
    if (_currentUserActivity == null) {
      return {
        'blank': 0,
        'recording': 0,
        'pronunciation': 0,
        'rhythm': 0,
        'total': 0,
      };
    }

    // 빈칸 채우기 점수 (40%)
    int blankScore = 0;
    if (_currentUserActivity!.blankAnswers.isNotEmpty &&
        _currentActivity != null) {
      final totalBlanks = _currentActivity!.blanks.length;
      final correctAnswers = _currentUserActivity!.blankAnswers.values
          .where((answer) => answer.isNotEmpty)
          .length;
      blankScore = totalBlanks > 0
          ? ((correctAnswers / totalBlanks) * 100).round()
          : 0;
    }

    // 녹음 점수 (20%) - 녹음 파일이 있으면 기본 점수
    int recordingScore =
        (_currentUserActivity!.recordingUrl?.isNotEmpty ?? false) ? 80 : 0;

    // 발음 점수 (40%) - 실제 STT 분석 결과 사용
    int pronunciationScore = _currentUserActivity!.pronunciationScore ?? 50;

    // 리듬 점수 (기본값)
    int rhythmScore = 75;

    // 총점 계산 (가중평균)
    int totalScore =
        ((blankScore * 0.4) +
                (recordingScore * 0.2) +
                (pronunciationScore * 0.4))
            .round();

    return {
      'blank': blankScore,
      'recording': recordingScore,
      'pronunciation': pronunciationScore,
      'rhythm': rhythmScore,
      'total': totalScore,
    };
  }

  // 좋아요
  Future<bool> likeActivity(String activityId) async {
    return await _firebaseService.likeActivity(activityId);
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Provider 해제
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // 오디오 상태 스트림
  Stream<bool> get isPlayingStream => _audioService.playingStateStream;
  Stream<bool> get isRecordingStream => _audioService.recordingStateStream;
  Stream<Duration> get positionStream => _audioService.positionStream;
  Stream<Duration?> get durationStream => _audioService.durationStream;
}
