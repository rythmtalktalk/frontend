import 'package:flutter/material.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class PronunciationWidget extends StatefulWidget {
  final String targetText;
  final Function(Map<String, dynamic>)? onEvaluationComplete;

  const PronunciationWidget({
    Key? key,
    required this.targetText,
    this.onEvaluationComplete,
  }) : super(key: key);

  @override
  State<PronunciationWidget> createState() => _PronunciationWidgetState();
}

class _PronunciationWidgetState extends State<PronunciationWidget>
    with TickerProviderStateMixin {
  final STTService _sttService = STTService();
  final TTSService _ttsService = TTSService();

  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _partialText = '';
  Map<String, dynamic>? _evaluationResult;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeServices() async {
    try {
      final sttInitialized = await _sttService.initialize();
      await _ttsService.initialize();

      if (!sttInitialized) {
        _showPermissionDialog();
        return;
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('서비스 초기화 실패: $e');
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _partialText = '';
      _evaluationResult = null;
    });

    _pulseController.repeat(reverse: true);

    // 시뮬레이션: 3초 후 결과 반환
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // 시뮬레이션: 60% 확률로 정답 인식
      final isCorrect = DateTime.now().millisecondsSinceEpoch % 5 < 3;
      final recognizedText = isCorrect ? widget.targetText : '비슷한 발음';

      setState(() {
        _recognizedText = recognizedText;
        _partialText = recognizedText;
        _isListening = false;
      });
      _pulseController.stop();
      _evaluatePronunciation();
    }
  }

  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
  }

  void _evaluatePronunciation() {
    if (_recognizedText.isEmpty) return;

    // 간단한 발음 평가 시뮬레이션
    final similarity = _sttService.calculateSimilarity(
      widget.targetText,
      _recognizedText,
    );

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

    final evaluation = {
      'grade': grade,
      'score': (similarity * 100).round(),
      'similarity': similarity,
      'feedback': similarity >= 0.7 ? '정말 잘했어요!' : '잘했어요!',
    };

    setState(() {
      _evaluationResult = evaluation;
    });

    widget.onEvaluationComplete?.call(evaluation);
  }

  Future<void> _playTargetText() async {
    await _ttsService.speak(widget.targetText);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: const Text('음성 인식을 위해 마이크 권한이 필요해요.\n설정에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeServices();
            },
            child: const Text('다시 시도'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 이전 화면으로 돌아가기
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case '우수':
        return Colors.green;
      case '좋음':
        return Colors.blue;
      case '보통':
        return Colors.orange;
      case '연습필요':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getGradeIcon(String grade) {
    switch (grade) {
      case '우수':
        return Icons.star;
      case '좋음':
        return Icons.thumb_up;
      case '보통':
        return Icons.sentiment_neutral;
      case '연습필요':
        return Icons.school;
      default:
        return Icons.help;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            const Text(
              '발음 연습',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 목표 텍스트
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    '따라 말해보세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.targetText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _playTargetText,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('듣기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 녹음 버튼
            if (!_isInitialized)
              const Center(child: CircularProgressIndicator())
            else
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: ElevatedButton.icon(
                      onPressed: _isListening
                          ? _stopListening
                          : _startListening,
                      icon: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 32,
                      ),
                      label: Text(
                        _isListening ? '녹음 중지' : '녹음 시작',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // 인식된 텍스트 표시
            if (_partialText.isNotEmpty || _recognizedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '인식된 내용',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recognizedText.isNotEmpty
                          ? _recognizedText
                          : _partialText,
                      style: TextStyle(
                        fontSize: 16,
                        color: _recognizedText.isNotEmpty
                            ? Colors.black
                            : Colors.grey[600],
                        fontStyle: _recognizedText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),

            // 평가 결과
            if (_evaluationResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getGradeColor(
                    _evaluationResult!['grade'],
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getGradeColor(_evaluationResult!['grade']),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getGradeIcon(_evaluationResult!['grade']),
                          color: _getGradeColor(_evaluationResult!['grade']),
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _evaluationResult!['grade'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(_evaluationResult!['grade']),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '정확도: ${_evaluationResult!['percentage']}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _evaluationResult!['similarity'],
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getGradeColor(_evaluationResult!['grade']),
                      ),
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
}
