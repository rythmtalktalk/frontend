import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class VoiceGuideWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final bool autoPlay;

  const VoiceGuideWidget({
    Key? key,
    required this.message,
    this.icon = Icons.volume_up,
    this.color = Colors.blue,
    this.autoPlay = true,
  }) : super(key: key);

  @override
  State<VoiceGuideWidget> createState() => _VoiceGuideWidgetState();
}

class _VoiceGuideWidgetState extends State<VoiceGuideWidget>
    with TickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeTTS();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
    if (widget.autoPlay) {
      await Future.delayed(const Duration(milliseconds: 500));
      _playMessage();
    }
  }

  Future<void> _playMessage() async {
    setState(() {
      _isPlaying = true;
    });

    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    await _ttsService.speak(widget.message);

    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _bounceAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.color.withOpacity(0.8),
              ),
            ),
          ),
          IconButton(
            onPressed: _playMessage,
            icon: Icon(
              _isPlaying ? Icons.volume_off : Icons.replay,
              color: widget.color,
            ),
            tooltip: '다시 듣기',
          ),
        ],
      ),
    );
  }
}

// 미리 정의된 안내 메시지들
class VoiceGuideMessages {
  static const String welcome = "안녕하세요! 오늘도 즐겁게 노래해봐요!";
  static const String listen = "먼저 동요를 잘 들어보세요. 귀 기울여 주세요!";
  static const String record = "이제 동요를 따라 불러보세요. 크고 예쁜 목소리로요!";
  static const String blankFill = "빈칸에 들어갈 단어를 말해보세요. 천천히 또박또박요!";
  static const String rhythm = "리듬에 맞춰 단어를 따라해보세요. 신나게 해봐요!";
  static const String pronunciation = "정확한 발음으로 따라해보세요. 입을 크게 벌려요!";
  static const String encouragement = "정말 잘하고 있어요! 계속 해봐요!";
  static const String completion = "와! 모든 활동을 완료했어요! 정말 대단해요!";
  static const String retry = "괜찮아요! 다시 한번 해볼까요?";
  static const String goodJob = "잘했어요! 정말 멋져요!";
}
