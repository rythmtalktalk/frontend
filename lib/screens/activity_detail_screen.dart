import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/lyric_sync_widget.dart';
import 'feedback_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final MusicActivity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  Timer? _stepTimer;
  Timer? _lyricTimer;

  // 애니메이션 컨트롤러들
  late AnimationController _celebrationController;
  late AnimationController _characterController;

  // 오디오 및 녹음 상태
  bool _isPlaying = false;
  bool _isRecording = false;

  // 가사 하이라이트
  int _currentLyricIndex = 0;

  // 소절별 학습 상태
  int _currentSectionIndex = 0;
  bool _isListeningToSection = true;
  int _sectionRepeatCount = 0;
  bool _isSectionCompleted = false;

  // 서비스들
  final AudioService _audioService = AudioService();
  final TTSService _ttsService = TTSService();
  final STTService _sttService = STTService();

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _characterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 캐릭터 애니메이션 반복
    _characterController.repeat(reverse: true);

    // 첫 번째 단계 시작
    _startStep1();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _lyricTimer?.cancel();
    _celebrationController.dispose();
    _characterController.dispose();
    _audioService.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }

  // 1단계: 전체 노래 듣기
  void _startStep1() {
    if (!mounted) return;
    setState(() {
      _currentStep = 0;
      _currentLyricIndex = 0;
    });

    _playAudioAndWait();
  }

  Future<void> _playAudioAndWait() async {
    if (!mounted) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      // 가사 하이라이트 시작
      _startLyricHighlight();

      // 오디오 재생
      final success = await _audioService.playMusic(widget.activity.audioUrl);

      if (success) {
        // 오디오 재생이 완료될 때까지 대기
        while (_audioService.isPlaying && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (mounted) {
        setState(() {
          _isPlaying = false;
        });

        // 바로 다음 단계(따라하기)로
        _startStep2();
      }
    } catch (e) {
      print('오디오 재생 오류: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        _startStep2();
      }
    }
  }

  // 2단계: 소절별 학습
  void _startStep2() {
    if (!mounted) return;
    setState(() {
      _currentStep = 1;
      _currentSectionIndex = 0;
      _isListeningToSection = true;
      _sectionRepeatCount = 0;
      _isSectionCompleted = false;
    });

    // 가사 트래킹을 수동으로 초기화
    _setLyricIndex(0);

    // 소절이 있으면 소절별 학습, 없으면 줄별 따라하기
    if (widget.activity.sections.isNotEmpty) {
      _startSectionLesson();
    } else {
      _startSingAlong();
    }
  }

  // 전체 따라하기 (소절이 없는 경우)
  void _startSingAlong() async {
    if (!mounted) return;

    // 가사 인덱스는 이미 _startStep2에서 초기화됨
    print('줄별 따라하기 시작 (초기 가사 인덱스: $_currentLyricIndex)');

    try {
      final lyricsLines = widget.activity.lyrics
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      for (int i = 0; i < lyricsLines.length && mounted; i++) {
        // 가사 트래킹을 현재 줄로 고정 설정
        _setLyricIndex(i);

        setState(() {
          _isPlaying = true;
        });

        // 1단계: 먼저 해당 부분 음원 재생 (전체 노래에서 해당 구간)
        print(
          '가사 줄 ${i + 1} 재생: ${lyricsLines[i]} (가사 인덱스 고정: $_currentLyricIndex)',
        );

        // 전체 가사에서 현재 줄의 예상 시간 계산
        // TODO: Firebase에 소절별 타이밍 정보가 없는 경우의 추정값
        // 실제로는 각 가사 줄별 정확한 타이밍 정보가 Firebase에 저장되어야 함
        double estimatedStartTime = i * 3.5; // 각 줄당 약 3.5초씩
        double estimatedEndTime = (i + 1) * 3.5;

        // 전체 음원에서 해당 구간 재생
        final success = await _audioService.playSectionLoop(
          widget.activity.audioUrl,
          estimatedStartTime,
          estimatedEndTime,
          repeatCount: 1, // 1번만 재생
        );

        if (!success) {
          // 오디오 재생 실패 시 TTS로 대체
          print('오디오 재생 실패, TTS로 대체');
          await _ttsService.speak(lyricsLines[i]);

          while (_ttsService.isSpeaking && mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }

        // 재생 완료 후 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          _isPlaying = false;
          _isRecording = true;
          // 가사 인덱스는 절대 변경하지 않음 (이미 고정됨)
        });

        // 2단계: 따라하기 시작
        print(
          '가사 줄 ${i + 1} 따라하기: ${lyricsLines[i]} (가사 인덱스 고정 유지: $_currentLyricIndex)',
        );

        String? recognizedText = await _sttService.startListening(
          expectedText: lyricsLines[i],
        );
        await Future.delayed(const Duration(seconds: 3));
        await _sttService.stopListening();

        // 발음 점수 계산
        double score = _calculatePronunciationScore(
          lyricsLines[i],
          recognizedText ?? '',
        );
        print('발음 점수: ${score.toStringAsFixed(1)}점 (100점 만점)');

        // 모든 경우에 긍정적인 피드백
        String feedback;
        if (score >= 80) {
          feedback = '정말 잘했어요! 최고예요!';
        } else if (score >= 60) {
          feedback = '잘했어요! 훌륭해요!';
        } else if (score >= 40) {
          feedback = '잘했어요! 멋져요!';
        } else {
          feedback = '잘했어요! 계속해봐요!';
        }

        await _ttsService.speak(feedback);

        while (_ttsService.isSpeaking && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        setState(() {
          _isRecording = false;
          // 가사 인덱스는 절대 변경하지 않음 (다음 반복에서 _setLyricIndex로 업데이트됨)
        });

        // 다음 줄로 넘어가기 전 잠시 휴식
        await Future.delayed(const Duration(seconds: 2));
        print('가사 줄 ${i + 1} 완료, 다음 줄로 이동 준비 (현재 가사 인덱스: $_currentLyricIndex)');
      }

      // 모든 줄 완료 후 축하 단계로
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _startStep3();
      }
    } catch (e) {
      print('따라하기 오류: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPlaying = false;
        });
        _startStep3();
      }
    }
  }

  // 소절 학습 시작
  void _startSectionLesson() {
    final sections = widget.activity.sections;
    if (_currentSectionIndex >= sections.length) {
      // 모든 소절 완료 시 축하 단계로
      _startStep3();
      return;
    }

    if (_isListeningToSection) {
      _playCurrentSection();
    } else {
      _recordCurrentSection();
    }
  }

  // 현재 소절 재생
  void _playCurrentSection() async {
    if (!mounted) return;

    final sections = widget.activity.sections;
    if (_currentSectionIndex >= sections.length) return;

    final currentSection = sections[_currentSectionIndex];

    // 가사 인덱스를 현재 소절로 고정 설정
    _setLyricIndex(_currentSectionIndex);

    if (mounted) {
      setState(() {
        _isPlaying = true;
      });
    }

    try {
      print(
        '소절 ${_currentSectionIndex + 1} 재생: ${currentSection.text} (${currentSection.startTime}초 ~ ${currentSection.endTime}초, 가사 인덱스: $_currentLyricIndex)',
      );

      // Firebase에 저장된 정확한 소절별 타이밍으로 오디오 구간 재생 (2회 반복)
      final success = await _audioService.playSectionLoop(
        widget.activity.audioUrl,
        currentSection.startTime,
        currentSection.endTime,
        repeatCount: 2,
      );

      if (!success) {
        // 오디오 재생 실패 시 TTS로 대체
        print('오디오 재생 실패, TTS로 대체');
        await _ttsService.speak(currentSection.text);

        while (_ttsService.isSpeaking && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // 재생 완료 후 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isListeningToSection = false; // 따라부르기 모드로 전환
          // 가사 트래킹은 현재 소절에 계속 유지
        });

        // 1초 후 녹음 시작
        _stepTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _startSectionLesson();
          }
        });
      }
    } catch (e) {
      print('구간 재생 오류: $e');

      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isListeningToSection = false;
        });

        // 오류 시에도 다음 단계로 진행
        _stepTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _startSectionLesson();
          }
        });
      }
    }
  }

  // 현재 소절 따라부르기
  void _recordCurrentSection() async {
    if (!mounted) return;

    final sections = widget.activity.sections;
    if (_currentSectionIndex >= sections.length) {
      _startStep3(); // 모든 소절 완료 시 축하 단계로
      return;
    }

    print(
      '소절 ${_currentSectionIndex + 1} 따라부르기 시작 (반복 횟수: $_sectionRepeatCount, 가사 인덱스: $_currentLyricIndex)',
    );

    // TTS 안내 메시지 (1번만 따라부르기)
    String guideMessage = "이제 따라해볼까요? 준비되면 노래해보세요!";

    // 음악 볼륨을 일시적으로 낮추고 TTS 재생
    await _audioService.setVolume(0.3); // 음악 볼륨을 30%로 낮춤

    _ttsService.speak(guideMessage).then((_) async {
      // TTS 완료 후 음악 볼륨을 원래대로 복구
      await _audioService.setVolume(1.0);
      // TTS 완료 후 5초간 녹음 시간 제공
      if (!mounted) return;

      _stepTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;

        _sectionRepeatCount++;
        print('소절 ${_currentSectionIndex + 1} 완료, 반복 횟수: $_sectionRepeatCount');

        if (_sectionRepeatCount >= 1) {
          // 1번 완료 시 다음 소절로
          print('소절 ${_currentSectionIndex + 1} 완료! 다음 소절로 이동');

          setState(() {
            _currentSectionIndex++; // 다음 소절로 이동
            _isListeningToSection = true; // 다음 소절 듣기 모드
            _sectionRepeatCount = 0; // 반복 횟수 초기화
            _isSectionCompleted = true; // 완료 메시지 표시
          });

          // 가사 트래킹을 다음 소절로 업데이트 (별도로 처리)
          _setLyricIndex(_currentSectionIndex);

          // 잠시 축하 메시지 후 다음 소절 또는 완료 처리
          _stepTimer = Timer(const Duration(seconds: 2), () {
            if (!mounted) return;

            setState(() {
              _isSectionCompleted = false;
            });

            // 모든 소절 완료 확인
            if (_currentSectionIndex >= sections.length) {
              print('모든 소절 완료! 축하 단계로 이동');
              _startStep3();
            } else {
              print('소절 ${_currentSectionIndex + 1} 시작');
              _startSectionLesson();
            }
          });
        }
      });
    });
  }

  // 3단계: 축하 및 보상
  void _startStep3() {
    if (!mounted) return;
    setState(() {
      _currentStep = 2;
    });

    _celebrationController.forward();
    _completeActivity();
  }

  // 수동 가사 트래킹 설정 (자동 타이머 제거)
  void _setLyricIndex(int index) {
    if (mounted) {
      setState(() {
        _currentLyricIndex = index;
      });
      print('가사 인덱스 수동 설정: $index');
    }
  }

  // 가사 하이라이트 애니메이션 (전체 듣기용) - 수동 제어로 변경
  void _startLyricHighlight() {
    // 전체 듣기에서는 첫 번째 가사부터 시작
    _setLyricIndex(0);

    final sections = widget.activity.sections;
    int totalLines;

    if (sections.isNotEmpty) {
      totalLines = sections.length;
    } else {
      final lyricsLines = widget.activity.lyrics
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      totalLines = lyricsLines.length;
    }

    if (totalLines == 0) return;

    // 하이라이트 시간을 7초로 늘림 (어린이가 읽을 시간 확보)
    const Duration highlightDuration = Duration(seconds: 7);

    _lyricTimer = Timer.periodic(highlightDuration, (timer) {
      if (mounted && _currentLyricIndex < totalLines - 1) {
        _setLyricIndex(_currentLyricIndex + 1);
      } else {
        timer.cancel();
      }
    });
  }

  // 발음 점수 계산 (간단한 문자열 유사도 기반)
  double _calculatePronunciationScore(String original, String recognized) {
    if (recognized.isEmpty) return 0.0;

    // 공백과 특수문자 제거하고 소문자로 변환
    String cleanOriginal = original
        .replaceAll(RegExp(r'[^\w가-힣]'), '')
        .toLowerCase();
    String cleanRecognized = recognized
        .replaceAll(RegExp(r'[^\w가-힣]'), '')
        .toLowerCase();

    if (cleanOriginal.isEmpty) return 0.0;

    // 완전 일치 시 100점
    if (cleanOriginal == cleanRecognized) return 100.0;

    // 부분 일치 점수 계산
    int matchCount = 0;
    int maxLength = cleanOriginal.length > cleanRecognized.length
        ? cleanOriginal.length
        : cleanRecognized.length;

    for (
      int i = 0;
      i < cleanOriginal.length && i < cleanRecognized.length;
      i++
    ) {
      if (cleanOriginal[i] == cleanRecognized[i]) {
        matchCount++;
      }
    }

    // 기본 점수 (문자 일치도)
    double baseScore = (matchCount / maxLength) * 100;

    // 길이 유사도 보너스
    double lengthSimilarity =
        1.0 -
        (cleanOriginal.length - cleanRecognized.length).abs() /
            cleanOriginal.length;
    double lengthBonus = lengthSimilarity * 20;

    // 포함 관계 보너스 (인식된 텍스트가 원본에 포함되어 있으면)
    double containsBonus = 0.0;
    if (cleanOriginal.contains(cleanRecognized) ||
        cleanRecognized.contains(cleanOriginal)) {
      containsBonus = 30.0;
    }

    double finalScore = baseScore + lengthBonus + containsBonus;
    return finalScore > 100.0 ? 100.0 : finalScore;
  }

  void _completeActivity() async {
    try {
      final provider = context.read<ActivityProvider>();
      await provider.completeActivity();
    } catch (e) {
      print('활동 완료 처리 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getStepBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠
            _buildStepContent(),

            // 뒤로가기 버튼 (왼쪽 상단)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // 음악 정지 및 리소스 정리
                    _audioService.dispose();
                    _ttsService.dispose();
                    _sttService.dispose();

                    // 타이머 취소
                    _stepTimer?.cancel();
                    _lyricTimer?.cancel();

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.grey,
                    size: 24,
                  ),
                  tooltip: '뒤로가기',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 단계별 배경색
  Color _getStepBackgroundColor() {
    switch (_currentStep) {
      case 0:
        return Colors.blue[50] ?? Colors.blue.shade50;
      case 1:
        return Colors.green[50] ?? Colors.green.shade50;
      case 2:
        return Colors.purple[50] ?? Colors.purple.shade50;
      default:
        return Colors.white;
    }
  }

  // 단계별 콘텐츠
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildListenStep();
      case 1:
        return _buildSingAlongStep();
      case 2:
        return _buildCelebrationStep();
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  // 1단계: 전체 노래 듣기
  Widget _buildListenStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 진행 상황 표시
            _buildProgressCard(),

            const SizedBox(height: 24),

            // 음악 아이콘과 제목
            AnimatedBuilder(
              animation: _characterController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_characterController.value * 0.1),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎵', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              widget.activity.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              '🎵 노래를 들어보세요!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 가사 표시 (강조된 스타일)
            _buildLyricsDisplay(),
          ],
        ),
      ),
    );
  }

  // 2단계: 따라 부르기
  Widget _buildSingAlongStep() {
    final sections = widget.activity.sections;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 진행 상황 표시
            _buildProgressCard(),

            const SizedBox(height: 24),

            if (sections.isEmpty) ...[
              // 전체 가사 따라하기 - 상태 표시 제거하고 바로 가사 표시
              _buildLyricsDisplay(),
            ] else ...[
              // 소절별 학습
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      '소절 ${_currentSectionIndex + 1} / ${sections.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentSectionIndex + 1) / sections.length,
                      backgroundColor: Colors.green[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 현재 학습 모드 표시
              if (_isSectionCompleted)
                _buildSectionCompletedMessage()
              else if (_isListeningToSection)
                _buildListeningMode()
              else
                _buildSingingMode(),

              const SizedBox(height: 20),

              // 현재 소절 표시
              if (_currentSectionIndex < sections.length)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[100]!, Colors.green[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '현재 배우는 소절:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sections[_currentSectionIndex].text,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // 3단계: 축하 및 보상
  Widget _buildCelebrationStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 진행 상황 표시
            _buildProgressCard(),

            const SizedBox(height: 40),

            // 축하 메시지
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_celebrationController.value * 0.4),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow[200]!, Colors.orange[200]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🌟 축하해요! 🌟',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '노래를 정말 잘 불렀어요!\n계속해서 더 많은 노래를 불러보세요!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // 스티커 보상
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSticker('⭐', Colors.yellow[200]!),
                            const SizedBox(width: 12),
                            _buildSticker('🏆', Colors.orange[200]!),
                            const SizedBox(width: 12),
                            _buildSticker('🎵', Colors.pink[200]!),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // 피드백 버튼
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.cyan[400]!],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // 피드백 대상 활동을 현재 활동으로 설정하여 피드백 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FeedbackScreen(activity: widget.activity),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.feedback, size: 24),
                    SizedBox(width: 12),
                    Text(
                      '피드백 남기기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 홈으로 돌아가기 버튼
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.pink[400]!],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  try {
                    // 모든 타이머 정리
                    _stepTimer?.cancel();
                    _lyricTimer?.cancel();

                    // 오디오 정지
                    _audioService.stopPlaying();
                    _ttsService.stop();

                    // 안전하게 홈으로 이동
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    print('홈으로 가기 오류: $e');
                    // 오류 발생 시 강제로 홈으로 이동
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, size: 24),
                    SizedBox(width: 12),
                    Text(
                      '홈으로 가기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 진행 상황 카드 (스크롤 가능)
  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 제목과 단계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.activity.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_currentStep + 1}/3 단계',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStepColor(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 진행률 바
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStepTitle(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStepColor(),
                    ),
                  ),
                  Text(
                    '${((_currentStep + 1) / 3 * 100).round()}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_getStepColor()),
                minHeight: 8,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 단계 아이콘들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStepIndicator(0, '듣기', Icons.headphones),
              _buildStepIndicator(1, '따라하기', Icons.mic),
              _buildStepIndicator(2, '축하', Icons.celebration),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '노래 듣기';
      case 1:
        return '따라 부르기';
      case 2:
        return '축하 시간';
      default:
        return '';
    }
  }

  Color _getStepColor() {
    switch (_currentStep) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                ? _getStepColor()
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted || isActive ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isCompleted || isActive ? _getStepColor() : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 가사 표시 위젯
  Widget _buildLyricsDisplay() {
    // 가사 동기화 위젯 사용
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LyricSyncWidget(
        activity: widget.activity,
        audioPlayer: _audioService.audioPlayer,
        isPlaying: _isPlaying,
        onSectionHighlight: (section) {
          // 현재 재생 중인 구간을 처리할 수 있습니다
          print('현재 구간: $section');
        },
      ),
    );
  }

  // 기존 가사 표시 (백업용)
  Widget _buildLyricsDisplayLegacy() {
    final sections = widget.activity.sections;

    if (sections.isNotEmpty) {
      // 소절이 있는 경우
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[50]!, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 가사 제목
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎵 가사 🎵',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 소절 내용
            ...sections.asMap().entries.map((entry) {
              int index = entry.key;
              var section = entry.value;
              bool isHighlighted = index == _currentLyricIndex;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? LinearGradient(
                          colors: [Colors.yellow[300]!, Colors.orange[200]!],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.6),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(15),
                  border: isHighlighted
                      ? Border.all(color: Colors.orange[400]!, width: 3)
                      : Border.all(color: Colors.purple[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: isHighlighted
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.purple.withOpacity(0.1),
                      blurRadius: isHighlighted ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  section.text,
                  style: TextStyle(
                    fontSize: isHighlighted ? 22 : 18,
                    fontWeight: isHighlighted
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: isHighlighted
                        ? Colors.orange[800]
                        : Colors.purple[800],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ],
        ),
      );
    } else {
      // 일반 가사인 경우
      final lyricsLines = widget.activity.lyrics
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[50]!, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 가사 제목
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎵 가사 🎵',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 가사 내용
            ...lyricsLines.asMap().entries.map((entry) {
              int index = entry.key;
              String line = entry.value;
              bool isHighlighted = index == _currentLyricIndex;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? LinearGradient(
                          colors: [Colors.yellow[300]!, Colors.orange[200]!],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.6),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(15),
                  border: isHighlighted
                      ? Border.all(color: Colors.orange[400]!, width: 3)
                      : Border.all(color: Colors.purple[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: isHighlighted
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.purple.withOpacity(0.1),
                      blurRadius: isHighlighted ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: isHighlighted ? 22 : 18,
                    fontWeight: isHighlighted
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: isHighlighted
                        ? Colors.orange[800]
                        : Colors.purple[800],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ],
        ),
      );
    }
  }

  // 소절 완료 메시지
  Widget _buildSectionCompletedMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow[200]!, Colors.orange[200]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 40)),
          SizedBox(height: 8),
          Text(
            '소절 완료!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Text(
            '다음 소절로 넘어가요',
            style: TextStyle(fontSize: 14, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  // 듣기 모드 UI
  Widget _buildListeningMode() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _characterController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_characterController.value * 0.15),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👂', style: TextStyle(fontSize: 50)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          '🎵 소절을 듣고 있어요',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 따라부르기 모드 UI
  Widget _buildSingingMode() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _characterController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_characterController.value * 0.15),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎤', style: TextStyle(fontSize: 50)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          '🎤 따라 불러보세요!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 스티커 위젯
  Widget _buildSticker(String emoji, Color backgroundColor) {
    return AnimatedBuilder(
      animation: _characterController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_characterController.value * 0.2),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }
}
