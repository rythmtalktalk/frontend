import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _listenToAudioProgress();
  }

  void _listenToAudioProgress() {
    // 재생 위치 스트림 구독
    _audioService.positionStream.listen((position) {
      if (mounted && !_isSliding) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // 전체 길이 스트림 구독
    _audioService.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 음악 아이콘
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.music_note,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // 재생 컨트롤 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            try {
                              final success = await provider.playCurrentMusic();
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('음악 재생에 실패했습니다. 다시 시도해주세요.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '오류가 발생했습니다: ${e.toString()}',
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : Icon(
                            Icons.play_circle_filled,
                            size: 48,
                            color: provider.isLoading
                                ? Colors.grey[400]
                                : Theme.of(context).primaryColor,
                          ),
                  ),
                  const SizedBox(width: 16),

                  IconButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.stopCurrentMusic();
                            setState(() {
                              _currentPosition = Duration.zero;
                            });
                          },
                    icon: Icon(
                      Icons.stop_circle,
                      size: 48,
                      color: provider.isLoading
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 재생 상태 표시
              StreamBuilder<bool>(
                stream: provider.isPlayingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;

                  String statusText;
                  Color statusColor;
                  IconData statusIcon;

                  if (provider.isLoading) {
                    statusText = '음악을 불러오는 중...';
                    statusColor = Colors.orange;
                    statusIcon = Icons.hourglass_empty;
                  } else if (isPlaying) {
                    statusText = '재생 중 ♪♫♪';
                    statusColor = Colors.green;
                    statusIcon = Icons.music_note;
                  } else {
                    statusText = '🎵 음악을 들어보세요';
                    statusColor = Colors.grey[600]!;
                    statusIcon = Icons.play_arrow;
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: isPlaying
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),

              // 시간바와 시간 표시
              if (_totalDuration.inSeconds > 0) ...[
                const SizedBox(height: 12),

                // 현재 시간 / 전체 시간
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 진행 바
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Theme.of(context).primaryColor,
                    overlayColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _totalDuration.inSeconds > 0
                        ? (_currentPosition.inSeconds /
                                  _totalDuration.inSeconds)
                              .clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: (value) {
                      setState(() {
                        _isSliding = true;
                        _currentPosition = Duration(
                          seconds: (value * _totalDuration.inSeconds).round(),
                        );
                      });
                    },
                    onChangeEnd: (value) {
                      final newPosition = Duration(
                        seconds: (value * _totalDuration.inSeconds).round(),
                      );
                      _audioService.seekTo(newPosition);
                      setState(() {
                        _isSliding = false;
                      });
                    },
                  ),
                ),
              ],

              // URL 표시 (개발용)
              if (widget.audioUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'URL: ${widget.audioUrl.length > 40 ? '${widget.audioUrl.substring(0, 40)}...' : widget.audioUrl}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
