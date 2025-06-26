import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/user_activity.dart';
import '../services/firebase_service.dart';

class FeedbackScreen extends StatefulWidget {
  final MusicActivity activity;

  const FeedbackScreen({super.key, required this.activity});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  bool _didChildParticipate = false;
  bool _noticedImprovement = false;
  int _engagementLevel = 3;
  String _additionalComments = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('활동 피드백')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 완료 축하 메시지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      '🎉 활동 완료!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.activity.title} 활동을 완료했습니다!',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 피드백 제목
              const Text(
                '부모님 피드백',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '아이의 활동 참여 상황을 알려주세요. 언어 발달에 도움이 됩니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // 참여도 질문
              _buildQuestionCard(
                '아이가 활동에 잘 참여했나요?',
                _buildParticipationSwitch(),
              ),

              const SizedBox(height: 16),

              // 개선 체감 질문
              _buildQuestionCard(
                '언어 발달 변화를 체감하시나요?',
                _buildImprovementSwitch(),
              ),

              const SizedBox(height: 16),

              // 참여 정도 질문
              _buildQuestionCard('아이의 활동 참여 정도는?', _buildEngagementSlider()),

              const SizedBox(height: 16),

              // 추가 의견
              _buildQuestionCard('추가 의견 (선택사항)', _buildCommentsField()),

              const SizedBox(height: 24),

              // 프로토타입 피드백 요청 (강조)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lightbulb, size: 40, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      '💡 프로토타입 피드백 요청',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '현재 이 앱은 프로토타입 버전입니다!\n\n'
                        '🔍 부족한 기능이나 개선이 필요한 점\n'
                        '✨ 추가되었으면 하는 새로운 기능\n'
                        '🐛 발견하신 버그나 오류\n'
                        '💭 사용성 개선 아이디어\n\n'
                        '어떤 의견이든 소중합니다!\n'
                        '위의 추가 의견란에 자유롭게 적어주세요.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 제출 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '피드백 제출하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationSwitch() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _didChildParticipate ? '네, 잘 참여했어요!' : '아니요, 어려워했어요',
            style: TextStyle(
              fontSize: 14,
              color: _didChildParticipate ? Colors.green[600] : Colors.red[600],
            ),
          ),
        ),
        Switch(
          value: _didChildParticipate,
          onChanged: (value) {
            setState(() {
              _didChildParticipate = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildImprovementSwitch() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _noticedImprovement ? '네, 변화를 느꼈어요!' : '아직 잘 모르겠어요',
            style: TextStyle(
              fontSize: 14,
              color: _noticedImprovement
                  ? Colors.green[600]
                  : Colors.orange[600],
            ),
          ),
        ),
        Switch(
          value: _noticedImprovement,
          onChanged: (value) {
            setState(() {
              _noticedImprovement = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEngagementSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '소극적',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '매우 적극적',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        Slider(
          value: _engagementLevel.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: _getEngagementLabel(_engagementLevel),
          onChanged: (value) {
            setState(() {
              _engagementLevel = value.round();
            });
          },
        ),
        Text(
          _getEngagementLabel(_engagementLevel),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '프로토타입 피드백도 함께 남겨주세요!',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                '• 아이의 반응이나 활동 참여 상황\n'
                '• 앱에서 부족하거나 개선이 필요한 기능\n'
                '• 추가되었으면 하는 새로운 기능\n'
                '• 발견하신 버그나 사용성 개선 아이디어',
            hintStyle: TextStyle(fontSize: 13, height: 1.4),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _additionalComments = value;
            });
          },
        ),
      ],
    );
  }

  String _getEngagementLabel(int level) {
    switch (level) {
      case 1:
        return '매우 소극적';
      case 2:
        return '소극적';
      case 3:
        return '보통';
      case 4:
        return '적극적';
      case 5:
        return '매우 적극적';
      default:
        return '보통';
    }
  }

  void _submitFeedback() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Firebase 연결 테스트
      print('Firebase 연결 테스트 중...');
      final connectionTest = await _firebaseService.testFirebaseConnection();
      print('Firebase 연결 테스트 결과: $connectionTest');

      if (!connectionTest) {
        _showErrorDialog('Firebase 연결에 문제가 있습니다. 네트워크 상태를 확인해주세요.');
        return;
      }

      final user = _firebaseService.currentUser;
      print('현재 사용자: ${user?.uid}');
      print('사용자 이메일: ${user?.email}');

      if (user == null) {
        print('사용자 정보 없음 - 로그인 필요');
        _showErrorDialog('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
        return;
      }

      // 인증 토큰 확인
      try {
        final token = await user.getIdToken();
        print('인증 토큰 확인 성공: ${token?.substring(0, 20)}...');
      } catch (e) {
        print('인증 토큰 확인 실패: $e');
        _showErrorDialog('인증에 문제가 있습니다. 다시 로그인해주세요.');
        return;
      }

      print('활동 정보: ${widget.activity.id}, ${widget.activity.title}');
      print('피드백 입력값:');
      print('- 참여 여부: $_didChildParticipate');
      print('- 개선 체감: $_noticedImprovement');
      print('- 참여도: $_engagementLevel');
      print('- 추가 의견: $_additionalComments');

      final feedback = ParentFeedback(
        id: '${user.uid}_${widget.activity.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        activityId: widget.activity.id,
        date: DateTime.now(),
        didChildParticipate: _didChildParticipate,
        noticedImprovement: _noticedImprovement,
        engagementLevel: _engagementLevel,
        additionalComments: _additionalComments.isNotEmpty
            ? _additionalComments
            : null,
      );

      print('생성된 피드백 객체: ${feedback.toJson()}');

      final success = await _firebaseService.saveParentFeedback(feedback);
      print('피드백 저장 결과: $success');

      if (success) {
        // 저장 후 실제로 데이터가 저장되었는지 확인
        print('저장된 피드백 확인 중...');
        try {
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final todayEnd = todayStart.add(const Duration(days: 1));

          final savedFeedbacks = await _firebaseService
              .getParentFeedbackByDateRange(user.uid, todayStart, todayEnd);

          final isActuallySaved = savedFeedbacks.any(
            (f) => f.id == feedback.id,
          );
          print('실제 저장 확인 결과: $isActuallySaved');
          print('오늘 저장된 피드백 수: ${savedFeedbacks.length}');

          if (isActuallySaved) {
            print('피드백 저장 및 확인 성공 - 성공 다이얼로그 표시');
            _showSuccessDialog();
          } else {
            print('피드백 저장은 성공했지만 확인 실패 - 성공 다이얼로그 표시');
            _showSuccessDialog(); // 저장은 성공했으므로 성공 다이얼로그 표시
          }
        } catch (e) {
          print('저장 확인 중 오류: $e');
          _showSuccessDialog(); // 저장은 성공했으므로 성공 다이얼로그 표시
        }
      } else {
        print('피드백 저장 실패 - 오류 다이얼로그 표시');
        _showErrorDialog('피드백 저장에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      print('피드백 제출 중 예외 발생: $e');
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('감사합니다! 🎉'),
        content: const Text(
          '소중한 피드백을 주셔서 감사합니다.\n아이의 언어 발달에 도움이 되도록 더 좋은 콘텐츠를 제공하겠습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 안전한 네비게이션: 홈 화면까지 모든 스택 제거
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('홈으로 돌아가기'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
