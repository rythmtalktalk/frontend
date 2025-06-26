import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_activity.dart';
import '../services/stt_service.dart';

class PronunciationResultWidget extends StatelessWidget {
  final UserActivity userActivity;
  final String activityTitle;

  const PronunciationResultWidget({
    super.key,
    required this.userActivity,
    required this.activityTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '발음 분석 결과',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 전체 점수 표시
            _buildOverallScore(),

            const SizedBox(height: 24),

            // 상세 점수 차트
            if (userActivity.detailedScores != null) _buildDetailedScoreChart(),

            const SizedBox(height: 24),

            // 발음 피드백
            if (userActivity.pronunciationFeedback != null)
              _buildFeedbackSection(),

            const SizedBox(height: 20),

            // 단어별 정확도
            if (userActivity.wordAccuracies != null &&
                userActivity.wordAccuracies!.isNotEmpty)
              _buildWordAccuracySection(),

            const SizedBox(height: 20),

            // 인식된 텍스트 vs 원본 텍스트
            if (userActivity.recognizedText != null)
              _buildTextComparisonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScore() {
    final score = userActivity.pronunciationScore ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getScoreGradientColors(score),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '전체 점수',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score점',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getScoreDescription(score),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getScoreEmoji(score),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedScoreChart() {
    final scores = userActivity.detailedScores!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상세 분석',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        // 바 차트
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.round()}점',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const titles = ['빈칸', '녹음', '발음', '리듬'];
                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeBarGroup(
                  0,
                  scores['blank']?.toDouble() ?? 0,
                  Colors.green,
                ),
                _makeBarGroup(
                  1,
                  scores['recording']?.toDouble() ?? 0,
                  Colors.blue,
                ),
                _makeBarGroup(
                  2,
                  scores['pronunciation']?.toDouble() ?? 0,
                  Colors.orange,
                ),
                _makeBarGroup(
                  3,
                  scores['rhythm']?.toDouble() ?? 0,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ),

        // 범례
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          children: [
            _buildLegendItem('빈칸 채우기', Colors.green),
            _buildLegendItem('녹음 완료', Colors.blue),
            _buildLegendItem('발음 정확도', Colors.orange),
            _buildLegendItem('리듬감', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.feedback, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '피드백',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            userActivity.pronunciationFeedback!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWordAccuracySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '단어별 정확도',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...userActivity.wordAccuracies!.entries.map((entry) {
          final accuracy = (entry.value * 100).round();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAccuracyColor(entry.value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$accuracy%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getAccuracyColor(entry.value),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTextComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '음성 인식 결과',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // 인식된 텍스트
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '인식된 발음',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userActivity.recognizedText!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<Color> _getScoreGradientColors(int score) {
    if (score >= 90) {
      return [Colors.green[400]!, Colors.green[600]!];
    } else if (score >= 80) {
      return [Colors.blue[400]!, Colors.blue[600]!];
    } else if (score >= 70) {
      return [Colors.orange[400]!, Colors.orange[600]!];
    } else {
      return [Colors.red[400]!, Colors.red[600]!];
    }
  }

  String _getScoreDescription(int score) {
    if (score >= 90) {
      return '완벽한 발음이에요! 🌟';
    } else if (score >= 80) {
      return '정말 잘했어요! 👏';
    } else if (score >= 70) {
      return '좋아요! 조금만 더 연습해봐요 😊';
    } else if (score >= 60) {
      return '괜찮아요! 천천히 다시 해봐요 🎵';
    } else {
      return '계속 연습하면 잘할 수 있어요! 💪';
    }
  }

  String _getScoreEmoji(int score) {
    if (score >= 90) {
      return '🌟';
    } else if (score >= 80) {
      return '👏';
    } else if (score >= 70) {
      return '😊';
    } else if (score >= 60) {
      return '🎵';
    } else {
      return '💪';
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.9) {
      return Colors.green;
    } else if (accuracy >= 0.7) {
      return Colors.blue;
    } else if (accuracy >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
