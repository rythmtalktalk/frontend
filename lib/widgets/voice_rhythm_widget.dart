import 'package:flutter/material.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class VoiceRhythmWidget extends StatefulWidget {
  final List<String> rhythmWords;
  final Function(bool)? onCompleted;

  const VoiceRhythmWidget({
    Key? key,
    required this.rhythmWords,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<VoiceRhythmWidget> createState() => _VoiceRhythmWidgetState();
}

class _VoiceRhythmWidgetState extends State<VoiceRhythmWidget>
    with TickerProviderStateMixin {
  final STTService _sttService = STTService();
  final TTSService _ttsService = TTSService();

  int _currentWordIndex = 0;
  List<bool> _completedWords = [];
  bool _isListening = false;
  bool _isCompleted = false;
  bool _isPlaying = false;
  String _currentRecognizedText = '';

  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _initializeWords();
    _setupAnimations();
    _initializeServices();
  }

  void _initializeWords() {
    _completedWords = List.filled(widget.rhythmWords.length, false);
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initializeServices() async {
    print('=== VoiceRhythmWidget 서비스 초기화 ===');

    try {
      // TTS 초기화
      await _ttsService.initialize();

      // 권한 요청 (네이티브 iOS 권한 포함)
      final permissionGranted = await _sttService.requestPermissions();
      if (!permissionGranted) {
        print('권한 요청 실패');
        _showPermissionDialog();
        return;
      }

      // STT 초기화
      final sttInitialized = await _sttService.initialize();
      if (!sttInitialized) {
        print('STT 초기화 실패');
        _showPermissionDialog();
        return;
      }

      print('모든 서비스 초기화 완료');
      _startCurrentWord();
    } catch (e) {
      print('서비스 초기화 중 오류: $e');
      _showPermissionDialog();
    }
  }

  Future<void> _startCurrentWord() async {
    if (_currentWordIndex >= widget.rhythmWords.length) {
      _completeActivity();
      return;
    }

    final currentWord = widget.rhythmWords[_currentWordIndex];

    // TTS로 안내 메시지
    await Future.delayed(const Duration(milliseconds: 500));
    await _ttsService.speak('${_currentWordIndex + 1}번째 단어입니다. 먼저 들어보세요');

    await Future.delayed(const Duration(milliseconds: 1000));
    await _playCurrentWord();
  }

  Future<void> _playCurrentWord() async {
    setState(() {
      _isPlaying = true;
    });

    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    final currentWord = widget.rhythmWords[_currentWordIndex];
    await _ttsService.speak(currentWord);

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isPlaying = false;
    });

    await _ttsService.speak('이제 따라해보세요');
    await Future.delayed(const Duration(milliseconds: 500));
    _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _currentRecognizedText = '';
    });

    _pulseController.repeat(reverse: true);

    // 시뮬레이션: 2초 후 결과 반환
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final currentWord = widget.rhythmWords[_currentWordIndex];
      // 시뮬레이션: 70% 확률로 정답 인식
      final isCorrect = DateTime.now().millisecondsSinceEpoch % 3 != 0;
      final recognizedText = isCorrect ? currentWord : '잘못된 답';

      setState(() {
        _currentRecognizedText = recognizedText;
      });
      _handleVoiceResult(recognizedText);
    }
  }

  Future<void> _stopListening() async {
    await _sttService.stopListening();
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
  }

  void _handleVoiceResult(String recognizedText) async {
    await _stopListening();

    final currentWord = widget.rhythmWords[_currentWordIndex];
    final similarity = _sttService.calculateSimilarity(
      currentWord,
      recognizedText,
    );

    if (similarity >= 0.5) {
      // 50% 이상이면 성공
      // 성공
      setState(() {
        _completedWords[_currentWordIndex] = true;
      });

      _successController.forward().then((_) {
        _successController.reset();
      });

      await _ttsService.speak('잘했어요! 정말 멋져요!');
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _currentWordIndex++;
      });

      _startCurrentWord();
    } else {
      // 다시 시도
      await _ttsService.speak('조금 더 크게 말해볼까요?');
      await Future.delayed(const Duration(milliseconds: 500));
      await _playCurrentWord(); // 다시 들려주고 시도
    }
  }

  void _completeActivity() {
    setState(() {
      _isCompleted = true;
    });

    _ttsService.speak('모든 리듬을 완성했어요! 정말 훌륭합니다!');
    widget.onCompleted?.call(true);
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

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다시 시도'),
        content: const Text('음성을 듣지 못했어요.\n다시 해볼까요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playCurrentWord();
            },
            child: const Text('다시 듣기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentWordIndex++;
              });
              _startCurrentWord();
            },
            child: const Text('넘어가기'),
          ),
        ],
      ),
    );
  }

  Color _getWordColor(int index) {
    if (index > _currentWordIndex) return Colors.grey[200]!;
    if (index == _currentWordIndex) return Colors.purple[100]!;
    return _completedWords[index] ? Colors.green[100]! : Colors.grey[200]!;
  }

  IconData _getWordIcon(int index) {
    if (index > _currentWordIndex) return Icons.lock_outline;
    if (index == _currentWordIndex) {
      if (_isPlaying) return Icons.volume_up;
      if (_isListening) return Icons.mic;
      return Icons.play_arrow;
    }
    return _completedWords[index] ? Icons.check_circle : Icons.help_outline;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 진행 상황 표시
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '리듬 따라하기 (${_currentWordIndex + 1}/${widget.rhythmWords.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentWordIndex) / widget.rhythmWords.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ],
          ),
        ),

        // 현재 단어 표시
        if (!_isCompleted) ...[
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _bounceAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple[200]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isPlaying ? Icons.volume_up : Icons.graphic_eq,
                        size: 56,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_currentWordIndex + 1}번째 단어',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.rhythmWords[_currentWordIndex],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isPlaying
                            ? '듣고 있어요...'
                            : (_isListening ? '따라해보세요!' : '들어보세요!'),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 액션 버튼
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 다시 듣기 버튼
                      ElevatedButton.icon(
                        onPressed: _isListening ? null : _playCurrentWord,
                        icon: const Icon(Icons.replay),
                        label: const Text('다시 듣기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // 말하기 버튼
                      ElevatedButton.icon(
                        onPressed: _isListening
                            ? _stopListening
                            : _startListening,
                        icon: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          size: 24,
                        ),
                        label: Text(
                          _isListening ? '말하는 중' : '말하기',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isListening
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 인식된 텍스트 표시
          if (_currentRecognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
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

        // 단어 목록
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.rhythmWords.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _successAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale:
                          index == _currentWordIndex - 1 &&
                              _completedWords[index]
                          ? _successAnimation.value * 0.1 + 1.0
                          : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getWordColor(index),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: index == _currentWordIndex
                                ? Colors.purple
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: index < _currentWordIndex
                              ? () =>
                                    _ttsService.speak(widget.rhythmWords[index])
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getWordIcon(index),
                                  color: index > _currentWordIndex
                                      ? Colors.grey
                                      : (index == _currentWordIndex
                                            ? Colors.purple
                                            : (_completedWords[index]
                                                  ? Colors.green
                                                  : Colors.grey)),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.rhythmWords[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: index > _currentWordIndex
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
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
                const Icon(Icons.star, size: 64, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  '🎵 모든 리듬을 완성했어요!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '정말 훌륭한 리듬감이에요!',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
