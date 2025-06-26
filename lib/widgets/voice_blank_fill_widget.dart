import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';

class VoiceBlankFillWidget extends StatefulWidget {
  final List<String> blanks;
  final VoidCallback? onCompleted;

  const VoiceBlankFillWidget({
    super.key,
    required this.blanks,
    this.onCompleted,
  });

  @override
  State<VoiceBlankFillWidget> createState() => _VoiceBlankFillWidgetState();
}

class _VoiceBlankFillWidgetState extends State<VoiceBlankFillWidget>
    with TickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  final STTService _sttService = STTService();

  int _currentBlankIndex = 0;
  bool _isListening = false;
  bool _isCompleted = false;
  String _currentRecognizedText = '';
  List<bool> _correctAnswers = [];
  List<String> _userAnswers = [];

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _correctAnswers = List.filled(widget.blanks.length, false);
    _userAnswers = List.filled(widget.blanks.length, '');

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.bounceOut,
      ),
    );

    _initializeTTS();
    _speakInstruction();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _successAnimationController.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }

  Future<void> _speakInstruction() async {
    await _ttsService.speak('빈칸에 들어갈 단어를 말해보세요. 천천히 또박또박요!');
  }

  Future<void> _startListening() async {
    try {
      // 3단계: 음성 인식 시작
      setState(() {
        _isListening = true;
        _currentRecognizedText = '';
      });

      _pulseAnimationController.repeat(reverse: true);

      // 기존 startListening 대신 간단한 시뮬레이션
      // 실제로는 녹음 -> STT 분석 과정이 필요하지만
      // 여기서는 간단하게 정답을 입력받는 것으로 처리
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        final correctAnswer = widget.blanks[_currentBlankIndex];
        // 시뮬레이션: 80% 확률로 정답 인식
        final isCorrect = DateTime.now().millisecondsSinceEpoch % 5 != 0;
        final recognizedText = isCorrect ? correctAnswer : '잘못된 답';

        setState(() {
          _currentRecognizedText = recognizedText;
        });
        _checkAnswer(recognizedText);
      }
    } catch (e) {
      print('음성 인식 시작 중 오류: $e');
      await _stopListening();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했어요. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    await _sttService.stopListening();
    setState(() {
      _isListening = false;
    });
    _pulseAnimationController.stop();
    _pulseAnimationController.reset();
  }

  Future<void> _checkAnswer(String userAnswer) async {
    final correctAnswer = widget.blanks[_currentBlankIndex];
    final similarity = _sttService.calculateSimilarity(
      userAnswer,
      correctAnswer,
    );

    setState(() {
      _userAnswers[_currentBlankIndex] = userAnswer;
      _correctAnswers[_currentBlankIndex] = similarity >= 0.6;
    });

    if (similarity >= 0.6) {
      _successAnimationController.forward().then((_) {
        _successAnimationController.reset();
      });

      await _ttsService.speak('정답이에요! 잘했어요!');

      setState(() {
        _currentBlankIndex++;
      });

      if (_currentBlankIndex >= widget.blanks.length) {
        setState(() {
          _isCompleted = true;
        });
        await _ttsService.speak('모든 빈칸을 완성했어요! 정말 잘했어요!');
        widget.onCompleted?.call();
      } else {
        await _ttsService.speak('다음 단어를 말해보세요!');
      }
    } else {
      await _ttsService.speak('다시 한 번 말해보세요. ${correctAnswer}라고 해보세요!');
    }
  }

  Color _getAnswerColor(int index) {
    if (index > _currentBlankIndex) return Colors.grey[100]!;
    if (index == _currentBlankIndex) return Colors.blue[50]!;
    return _correctAnswers[index] ? Colors.green[50]! : Colors.red[50]!;
  }

  IconData _getAnswerIcon(int index) {
    if (index > _currentBlankIndex) return Icons.help_outline;
    if (index == _currentBlankIndex) return Icons.mic;
    return _correctAnswers[index] ? Icons.check_circle : Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 진행 상황 표시
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '빈칸 채우기 (${_currentBlankIndex + 1}/${widget.blanks.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentBlankIndex) / widget.blanks.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        ),

        // 현재 빈칸 표시
        if (!_isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!, width: 2),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.record_voice_over,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  '${_currentBlankIndex + 1}번째 단어',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${widget.blanks[_currentBlankIndex]}"',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '라고 따라해보세요!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 마이크 버튼
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 32),
                    label: Text(
                      _isListening ? '말하는 중...' : '말하기 시작',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 인식된 텍스트 표시
          if (_currentRecognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    '들린 내용',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRecognizedText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],

        // 완료된 빈칸들 표시
        Container(
          constraints: const BoxConstraints(maxHeight: 100),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.blanks.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _successAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        index == _currentBlankIndex - 1 &&
                            _correctAnswers[index]
                        ? _successAnimation.value * 0.1 + 1.0
                        : 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getAnswerColor(index),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == _currentBlankIndex
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAnswerIcon(index),
                            color: index > _currentBlankIndex
                                ? Colors.grey
                                : (index == _currentBlankIndex
                                      ? Colors.blue
                                      : (_correctAnswers[index]
                                            ? Colors.green
                                            : Colors.red)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${widget.blanks[index]}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (index < _currentBlankIndex &&
                                    _userAnswers[index].isNotEmpty)
                                  Text(
                                    '말한 내용: ${_userAnswers[index]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // 완료 메시지
        if (_isCompleted)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.celebration, size: 64, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  '🎉 모든 빈칸을 완성했어요!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_correctAnswers.where((answer) => answer).length}/${widget.blanks.length} 정답!',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
