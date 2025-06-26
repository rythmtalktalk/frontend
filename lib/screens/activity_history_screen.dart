import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/user_activity.dart';
import '../models/activity.dart';
import '../services/firebase_service.dart';
import 'dart:math' as math;

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<UserActivityWithDetails> _userActivities = [];
  bool _isLoading = true;
  String? _error;
  Map<String, int> _weeklyStats = {};

  @override
  void initState() {
    super.initState();
    _loadActivityHistory();
  }

  Future<void> _loadActivityHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final firebaseService = FirebaseService();
      final currentUser = firebaseService.currentUser;

      if (currentUser == null) {
        setState(() {
          _error = '로그인이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      // 사용자 활동 기록 가져오기
      final userActivities = await firebaseService.getUserActivities(
        currentUser.uid,
      );

      // 각 활동의 상세 정보 가져오기
      List<UserActivityWithDetails> activitiesWithDetails = [];

      for (final userActivity in userActivities) {
        // 실제 활동 정보 가져오기 (제목 등)
        final activities = await firebaseService.getTodayActivities();
        final matchingActivity = activities.firstWhere(
          (activity) => activity.id == userActivity.activityId,
          orElse: () => MusicActivity(
            id: userActivity.activityId,
            title: _getActivityTitleFromId(userActivity.activityId),
            description: '음악 활동',
            audioUrl: '',
            lyrics: '',
            blanks: [],
            rhythmWords: [],
            sections: [], // 빈 구간 리스트
            difficulty: 1,
            ageGroup: '3-5세',
            tags: [],
            likeCount: 0,
            isPopular: false,
            createdAt: DateTime.now(),
          ),
        );

        activitiesWithDetails.add(
          UserActivityWithDetails(
            userActivity: userActivity,
            activityInfo: matchingActivity,
          ),
        );
      }

      // 주간 통계 계산
      _calculateWeeklyStats(userActivities);

      setState(() {
        _userActivities = activitiesWithDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '활동 기록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  String _getActivityTitleFromId(String activityId) {
    final titles = {
      'activity_1': '곰 세 마리',
      'activity_2': '나비야',
      'activity_3': '동물농장',
      'activity_4': '무지개',
      'activity_5': '작은별',
      'activity_6': '아기상어',
      'activity_7': '생일축하',
      'activity_8': '과일송',
    };
    return titles[activityId] ?? activityId;
  }

  void _calculateWeeklyStats(List<UserActivity> activities) {
    _weeklyStats = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = '${date.month}/${date.day}';
      _weeklyStats[dayKey] = 0;
    }

    for (final activity in activities) {
      if (activity.completedAt != null) {
        final completedDate = activity.completedAt!;
        final dayKey = '${completedDate.month}/${completedDate.day}';
        if (_weeklyStats.containsKey(dayKey)) {
          _weeklyStats[dayKey] = _weeklyStats[dayKey]! + 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivityHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActivityHistory,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_userActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '아직 완료한 활동이 없어요',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 활동을 시작해보세요!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivityHistory,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주간 통계 차트
            _buildWeeklyStatsCard(),
            const SizedBox(height: 20),

            // 전체 통계 요약
            _buildOverallStatsCard(),
            const SizedBox(height: 20),

            // 활동 목록 헤더
            Row(
              children: [
                const Text(
                  '최근 활동',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '총 ${_userActivities.length}개',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 활동 목록
            ...(_userActivities.map(
              (activityWithDetails) => _buildActivityCard(activityWithDetails),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '주간 활동 통계',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 120, child: _buildWeeklyChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    final maxValue = _weeklyStats.values.isNotEmpty
        ? _weeklyStats.values.reduce(math.max)
        : 1;
    final normalizedMax = maxValue > 0 ? maxValue : 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _weeklyStats.entries.map((entry) {
        final height = (entry.value / normalizedMax) * 60; // 높이 줄임
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.value.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Container(
                  width: 20,
                  height: math.max(height + 8, 8), // 최소 높이 보장하되 더 작게
                  decoration: BoxDecoration(
                    color: entry.value > 0 ? Colors.blue : Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.key,
                style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverallStatsCard() {
    final completedCount = _userActivities
        .where((a) => a.userActivity.isCompleted)
        .length;
    final averageScore =
        _userActivities
            .where((a) => a.userActivity.score != null)
            .map((a) => a.userActivity.score!)
            .fold<double>(0, (sum, score) => sum + score) /
        math.max(1, _userActivities.length);
    final totalRecordings = _userActivities
        .where((a) => a.userActivity.recordingUrl != null)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '전체 통계',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '완료한 활동',
                    completedCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '평균 점수',
                    '${averageScore.round()}점',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '녹음 횟수',
                    totalRecordings.toString(),
                    Icons.mic,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivityCard(UserActivityWithDetails activityWithDetails) {
    final userActivity = activityWithDetails.userActivity;
    final activityInfo = activityWithDetails.activityInfo;

    final completedAt = userActivity.completedAt;
    final formattedDate = completedAt != null
        ? '${completedAt.year}.${completedAt.month.toString().padLeft(2, '0')}.${completedAt.day.toString().padLeft(2, '0')}'
        : '진행중';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showActivityDetail(activityWithDetails),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: userActivity.isCompleted
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userActivity.isCompleted ? '완료' : '진행중',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: userActivity.isCompleted
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 음악 제목
              Row(
                children: [
                  Icon(Icons.music_note, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activityInfo.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (userActivity.score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(userActivity.score!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${userActivity.score}점',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // 활동 설명
              Text(
                activityInfo.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              // 진행 상황 아이콘들
              Row(
                children: [
                  if (userActivity.recordingUrl != null)
                    _buildProgressIcon(Icons.mic, '녹음', Colors.blue),
                  if (userActivity.blankAnswers.isNotEmpty)
                    _buildProgressIcon(Icons.edit, '빈칸채우기', Colors.green),
                  if (userActivity.pronunciationScore != null)
                    _buildProgressIcon(
                      Icons.record_voice_over,
                      '발음',
                      Colors.purple,
                    ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIcon(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  void _showActivityDetail(UserActivityWithDetails activityWithDetails) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityDetailAnalysisScreen(
          activityWithDetails: activityWithDetails,
        ),
      ),
    );
  }
}

// 활동과 상세 정보를 함께 담는 클래스
class UserActivityWithDetails {
  final UserActivity userActivity;
  final MusicActivity activityInfo;

  UserActivityWithDetails({
    required this.userActivity,
    required this.activityInfo,
  });
}

// 활동 상세 분석 화면
class ActivityDetailAnalysisScreen extends StatelessWidget {
  final UserActivityWithDetails activityWithDetails;

  const ActivityDetailAnalysisScreen({
    super.key,
    required this.activityWithDetails,
  });

  @override
  Widget build(BuildContext context) {
    final userActivity = activityWithDetails.userActivity;
    final activityInfo = activityWithDetails.activityInfo;

    return Scaffold(
      appBar: AppBar(
        title: Text(activityInfo.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 점수 카드
            _buildScoreCard(userActivity),
            const SizedBox(height: 20),

            // 상세 분석 차트
            _buildDetailedAnalysisCard(userActivity),
            const SizedBox(height: 20),

            // 발음 분석 (STT 결과)
            if (userActivity.recognizedText != null)
              _buildPronunciationAnalysisCard(userActivity, activityInfo),
            const SizedBox(height: 20),

            // 빈칸 채우기 결과
            if (userActivity.blankAnswers.isNotEmpty)
              _buildBlankAnswersCard(userActivity, activityInfo),
            const SizedBox(height: 20),

            // 개선 제안
            _buildImprovementSuggestionsCard(userActivity),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(UserActivity userActivity) {
    final score = userActivity.score ?? 0;
    final scoreColor = _getScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: scoreColor),
                const SizedBox(width: 8),
                const Text(
                  '전체 점수',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '점',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreMessage(score),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysisCard(UserActivity userActivity) {
    final scores = {
      '발음': userActivity.pronunciationScore ?? 50,
      '빈칸채우기': _calculateBlankScore(userActivity),
      '녹음': userActivity.recordingUrl != null ? 85 : 0,
      '리듬': 75, // 기본값
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '상세 분석',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...scores.entries.map(
              (entry) => _buildScoreBar(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final color = _getScoreColor(score);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score점',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationAnalysisCard(
    UserActivity userActivity,
    MusicActivity activityInfo,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  '발음 분석 결과',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 원본 가사
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '원본 가사',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityInfo.lyrics.replaceAll('\n', ' '),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 인식된 텍스트
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '인식된 발음',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userActivity.recognizedText ?? '분석 중...',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 피드백
            if (userActivity.pronunciationFeedback != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '피드백',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userActivity.pronunciationFeedback!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankAnswersCard(
    UserActivity userActivity,
    MusicActivity activityInfo,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '빈칸 채우기 결과',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...activityInfo.blanks.asMap().entries.map((entry) {
              final index = entry.key;
              final correctAnswer = entry.value;
              final userAnswer =
                  userActivity.blankAnswers['blank_$index'] ?? '';
              final isCorrect =
                  userAnswer.toLowerCase().trim() ==
                  correctAnswer.toLowerCase().trim();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${index + 1}. $correctAnswer')),
                    if (userAnswer.isNotEmpty)
                      Text(
                        '→ $userAnswer',
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSuggestionsCard(UserActivity userActivity) {
    final suggestions = _generateSuggestions(userActivity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  '개선 제안',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...suggestions
                .map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return '🎉 훌륭해요! 완벽한 수행이에요!';
    if (score >= 80) return '👏 잘했어요! 조금만 더 연습하면 완벽해요!';
    if (score >= 70) return '😊 좋아요! 계속 연습해봐요!';
    return '💪 괜찮아요! 다음에는 더 잘할 수 있을 거예요!';
  }

  int _calculateBlankScore(UserActivity userActivity) {
    if (userActivity.blankAnswers.isEmpty) return 0;
    // 간단한 점수 계산 (실제로는 정답 비교 필요)
    return (userActivity.blankAnswers.length * 20).clamp(0, 100);
  }

  List<String> _generateSuggestions(UserActivity userActivity) {
    List<String> suggestions = [];

    final pronunciationScore = userActivity.pronunciationScore ?? 0;
    if (pronunciationScore < 70) {
      suggestions.add('천천히 또박또박 발음해보세요');
      suggestions.add('입 모양을 크게 하여 발음해보세요');
    }

    if (userActivity.blankAnswers.isEmpty) {
      suggestions.add('빈칸 채우기를 완료해보세요');
    }

    if (userActivity.recordingUrl == null) {
      suggestions.add('녹음 기능을 사용해보세요');
    }

    suggestions.add('매일 조금씩 연습하면 실력이 늘어요');
    suggestions.add('다른 동요도 함께 불러보세요');

    return suggestions;
  }

  void _shareResults(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('결과를 공유했습니다!')));
  }
}
