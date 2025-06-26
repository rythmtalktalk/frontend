import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정 가이드'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.settings,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Firebase 설정이 필요합니다',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '앱을 사용하기 위해 Firebase 익명 인증을 활성화해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 단계별 가이드
            const Text(
              '설정 단계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildStep(
              context,
              1,
              'Firebase 콘솔 접속',
              'https://console.firebase.google.com 에 접속하세요',
              Icons.web,
            ),

            _buildStep(
              context,
              2,
              '프로젝트 선택',
              'rythmtalktalk 프로젝트를 선택하세요',
              Icons.folder,
            ),

            _buildStep(
              context,
              3,
              'Authentication 메뉴',
              '왼쪽 메뉴에서 Authentication을 클릭하세요',
              Icons.security,
            ),

            _buildStep(
              context,
              4,
              'Sign-in method 설정',
              'Sign-in method 탭에서 "Anonymous" 를 활성화하세요',
              Icons.person,
            ),

            _buildStep(
              context,
              5,
              '앱 재시작',
              '설정 완료 후 앱을 다시 시작하세요',
              Icons.refresh,
            ),

            const SizedBox(height: 32),

            // 도움말 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '도움이 필요하신가요?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Firebase 콘솔에서 익명 인증이 활성화되어 있는지 확인하세요\n'
                    '• 네트워크 연결 상태를 확인하세요\n'
                    '• 문제가 지속되면 앱을 재설치해보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyProjectId(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('프로젝트 ID 복사'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('돌아가기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    int step,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyProjectId(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'rythmtalktalk'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로젝트 ID가 클립보드에 복사되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
