import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/activity.dart';

class LyricSyncWidget extends StatefulWidget {
  final MusicActivity activity;
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final Function(String)? onSectionHighlight;

  const LyricSyncWidget({
    super.key,
    required this.activity,
    required this.audioPlayer,
    required this.isPlaying,
    this.onSectionHighlight,
  });

  @override
  State<LyricSyncWidget> createState() => _LyricSyncWidgetState();
}

class _LyricSyncWidgetState extends State<LyricSyncWidget> {
  Duration _currentPosition = Duration.zero;
  String _currentSection = '';
  int _currentSectionIndex = -1;

  @override
  void initState() {
    super.initState();
    _setupAudioListener();
  }

  void _setupAudioListener() {
    widget.audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _updateCurrentLyric(position.inMilliseconds / 1000.0);
        });
      }
    });
  }

  void _updateCurrentLyric(double currentTimeSeconds) {
    if (widget.activity.sections.isEmpty) return;

    // 현재 재생 중인 구간 찾기
    for (int i = 0; i < widget.activity.sections.length; i++) {
      final section = widget.activity.sections[i];
      if (currentTimeSeconds >= section.startTime &&
          currentTimeSeconds <= section.endTime) {
        if (_currentSectionIndex != i) {
          setState(() {
            _currentSectionIndex = i;
            _currentSection = section.text;
          });

          // 구간 변경 콜백 호출
          if (widget.onSectionHighlight != null) {
            widget.onSectionHighlight!(section.text);
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activity.sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '가사 타이밍 정보가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '일반 가사를 표시합니다',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.activity.lyrics,
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 진행률 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isPlaying ? Icons.music_note : Icons.pause,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_currentPosition),
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 가사 섹션들
          Expanded(
            child: ListView.builder(
              itemCount: widget.activity.sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = widget.activity.sections[sectionIndex];
                final isCurrentSection = _currentSectionIndex == sectionIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCurrentSection
                        ? Colors.orange[50]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentSection
                          ? Colors.orange[300]!
                          : Colors.grey[200]!,
                      width: isCurrentSection ? 3 : 1,
                    ),
                    boxShadow: isCurrentSection
                        ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 구간 정보
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentSection
                                  ? Colors.orange[200]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${section.index + 1}번째 구간',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrentSection
                                    ? Colors.orange[800]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${section.startTime.toStringAsFixed(1)}s - ${section.endTime.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 가사 텍스트
                      Text(
                        section.text,
                        style: TextStyle(
                          fontSize: isCurrentSection ? 22 : 18,
                          fontWeight: isCurrentSection
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isCurrentSection
                              ? Colors.orange[800]
                              : Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 현재 재생 중인 구간 크게 표시
          if (_currentSection.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[300]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '지금 부르는 가사',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSection,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
