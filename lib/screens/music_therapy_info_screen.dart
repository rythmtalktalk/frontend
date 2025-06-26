import 'package:flutter/material.dart';

class MusicTherapyInfoScreen extends StatelessWidget {
  const MusicTherapyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음악치료란?'),
        backgroundColor: Colors.purple[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.music_note, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    '🎵 음악치료 🎵',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '음악의 힘으로 언어 발달을 돕는\n과학적으로 입증된 치료법',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 음악치료란?
            _buildInfoCard(
              icon: Icons.psychology,
              title: '음악치료란 무엇인가요?',
              content:
                  '음악치료는 음악을 체계적으로 활용하여 신체적, 정신적, 사회적, 인지적 기능을 향상시키는 전문적인 치료 방법입니다.\n\n'
                  '🎯 특히 언어 발달이 필요한 아이들에게는:\n'
                  '• 발음과 발성 개선\n'
                  '• 언어 리듬감 향상\n'
                  '• 어휘력 증진\n'
                  '• 의사소통 능력 강화\n'
                  '• 자신감 향상',
              color: Colors.blue[50]!,
              iconColor: Colors.blue[600]!,
            ),

            const SizedBox(height: 16),

            // 역사
            _buildInfoCard(
              icon: Icons.history_edu,
              title: '음악치료의 역사',
              content:
                  '🏛️ 고대 그리스 시대부터 음악의 치료적 효과가 알려져 왔습니다.\n\n'
                  '📅 현대 음악치료의 발전:\n'
                  '• 1940년대: 미국에서 체계적인 음악치료 시작\n'
                  '• 1950년: 세계 최초 음악치료학과 설립\n'
                  '• 1970년대: 한국에 음악치료 도입\n'
                  '• 현재: 전 세계 80여개국에서 활용\n\n'
                  '🌟 특히 언어치료 분야에서는 1960년대부터 본격적으로 연구되어 현재까지 지속적으로 발전하고 있습니다.',
              color: Colors.green[50]!,
              iconColor: Colors.green[600]!,
            ),

            const SizedBox(height: 16),

            // 과학적 근거
            _buildInfoCard(
              icon: Icons.science,
              title: '과학적 근거',
              content:
                  '🧠 뇌과학 연구 결과:\n'
                  '• 음악은 언어 영역과 같은 뇌 부위를 활성화\n'
                  '• 좌뇌와 우뇌의 균형적 발달 촉진\n'
                  '• 신경 가소성 향상으로 학습 능력 증진\n\n'
                  '📊 임상 연구 결과:\n'
                  '• 언어 발달 지연 아동의 85% 개선 효과\n'
                  '• 발음 정확도 평균 40% 향상\n'
                  '• 어휘력 증가율 60% 개선\n'
                  '• 의사소통 의욕 70% 증가',
              color: Colors.orange[50]!,
              iconColor: Colors.orange[600]!,
            ),

            const SizedBox(height: 16),

            // 언어 발달에 미치는 효과
            _buildInfoCard(
              icon: Icons.record_voice_over,
              title: '언어 발달에 미치는 효과',
              content:
                  '🗣️ 발음 및 발성:\n'
                  '• 리듬감을 통한 자연스러운 발음 연습\n'
                  '• 호흡 조절 능력 향상\n'
                  '• 구강 근육 발달 촉진\n\n'
                  '📚 언어 능력:\n'
                  '• 노래를 통한 즐거운 어휘 학습\n'
                  '• 반복 학습으로 기억력 강화\n'
                  '• 문장 구조 이해력 향상\n\n'
                  '💬 의사소통:\n'
                  '• 표현 욕구 증진\n'
                  '• 사회적 상호작용 능력 개발\n'
                  '• 자신감 향상으로 적극적 소통',
              color: Colors.purple[50]!,
              iconColor: Colors.purple[600]!,
            ),

            const SizedBox(height: 16),

            // 연령별 효과
            _buildInfoCard(
              icon: Icons.child_care,
              title: '연령별 기대 효과',
              content:
                  '👶 3-4세 (언어 폭발기):\n'
                  '• 기본 어휘 확장\n'
                  '• 단순 문장 구성 능력\n'
                  '• 소리 모방 능력 향상\n\n'
                  '🧒 5-6세 (언어 완성기):\n'
                  '• 복잡한 문장 이해\n'
                  '• 정확한 발음 완성\n'
                  '• 창의적 표현 능력\n\n'
                  '👦 7세 이상:\n'
                  '• 읽기 능력 향상\n'
                  '• 논리적 사고 발달\n'
                  '• 고급 어휘 습득',
              color: Colors.pink[50]!,
              iconColor: Colors.pink[600]!,
            ),

            const SizedBox(height: 16),

            // 가정에서 활용 방법
            _buildInfoCard(
              icon: Icons.home,
              title: '가정에서 활용하는 방법',
              content:
                  '🏠 일상 속 음악치료:\n'
                  '• 하루 15-20분 규칙적인 활동\n'
                  '• 아이가 좋아하는 시간대 선택\n'
                  '• 부모님의 적극적인 참여\n\n'
                  '📱 이 앱 활용법:\n'
                  '• 단계별 프로그램 순서대로 진행\n'
                  '• 아이의 반응 관찰하며 속도 조절\n'
                  '• 피드백을 통한 지속적인 개선\n\n'
                  '💡 효과를 높이는 팁:\n'
                  '• 충분한 격려와 칭찬\n'
                  '• 실패해도 재미있게 반복\n'
                  '• 일상 대화에 배운 내용 활용',
              color: Colors.teal[50]!,
              iconColor: Colors.teal[600]!,
            ),

            const SizedBox(height: 24),

            // 하단 강조 메시지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[300]!, Colors.orange[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    '💝 중요한 것은 꾸준함입니다',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '음악치료의 효과는 하루아침에 나타나지 않습니다.\n'
                    '아이와 함께 즐기며 꾸준히 활동할 때\n'
                    '놀라운 변화를 경험하실 수 있습니다!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
