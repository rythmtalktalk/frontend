import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity.dart';
import '../services/firebase_service.dart';
import '../services/sample_data_service.dart';
import '../services/lyric_timing_service.dart';
import 'activity_detail_screen.dart';

import 'activity_history_screen.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';
import 'setup_guide_screen.dart';
import 'music_therapy_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadTodayActivities();
      context.read<ActivityProvider>().loadPopularActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [_HomeTab(), _PopularTab(), _MyPageTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '인기'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('말놀이뮤직'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('로그아웃'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadTodayActivities();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadTodayActivities();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 큼직한 환영 메시지
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[100]!, Colors.blue[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 큰 음악 아이콘
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.music_note,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '🎵 노래를 골라보세요!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '좋아하는 노래를 터치해보세요',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 카테고리 선택 (큼직한 아이콘들)
                  const Text(
                    '🎈 종류별로 찾기',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 카테고리 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryButton(
                          icon: '🐻',
                          title: '동물',
                          color: Colors.orange,
                          onTap: () => _filterByCategory(provider, '동물'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryButton(
                          icon: '🏠',
                          title: '일상',
                          color: Colors.green,
                          onTap: () => _filterByCategory(provider, '가족'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryButton(
                          icon: '🌈',
                          title: '자연',
                          color: Colors.purple,
                          onTap: () => _filterByCategory(provider, '자연'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 노래 목록 (큼직한 카드들)
                  const Text(
                    '🎶 모든 노래',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 노래 카드들 (세로로 배치, 큼직하게)
                  if (provider.todayActivities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '아직 노래가 없어요',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...provider.todayActivities.map(
                      (activity) => _buildLargeSongCard(activity),
                    ),

                  const SizedBox(height: 32),

                  // 빠른 메뉴 섹션 추가
                  const Text(
                    '📱 빠른 메뉴',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 빠른 액션 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.history,
                          title: '활동 기록',
                          subtitle: '지난 활동 보기',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ActivityHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 음악치료 정보 버튼 (전체 너비)
                  _QuickActionCard(
                    icon: Icons.psychology,
                    title: '🎵 음악치료란?',
                    subtitle: '음악치료의 효과와 과학적 근거 알아보기',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MusicTherapyInfoScreen(),
                        ),
                      );
                    },
                    isFullWidth: true,
                    backgroundColor: Colors.purple[50],
                    iconColor: Colors.purple[600],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 카테고리 버튼 위젯
  Widget _buildCategoryButton({
    required String icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리별 필터링
  void _filterByCategory(ActivityProvider provider, String category) {
    // 카테고리에 해당하는 활동들만 표시하는 로직
    // 현재는 간단하게 스낵바로 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category 카테고리 노래를 찾고 있어요!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 큰 노래 카드 위젯
  Widget _buildLargeSongCard(MusicActivity activity) {
    // 노래별 이모지 매핑
    String getActivityEmoji(String title) {
      if (title.contains('곰')) return '🐻';
      if (title.contains('나비')) return '🦋';
      if (title.contains('동물')) return '🐾';
      if (title.contains('무지개')) return '🌈';
      if (title.contains('별')) return '⭐';
      if (title.contains('숫자')) return '🔢';
      return '🎵';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailScreen(activity: activity),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _getActivityColor(activity.title).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // 큰 이모지 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getActivityColor(activity.title).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      getActivityEmoji(activity.title),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // 노래 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 노래 제목 (큼직하게)
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 설명
                      Text(
                        activity.description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // 태그들
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getActivityColor(
                                activity.title,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity.ageGroup,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getActivityColor(activity.title),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (activity.isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '인기',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 재생 버튼
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getActivityColor(activity.title),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 활동별 색상 반환
  Color _getActivityColor(String title) {
    if (title.contains('곰')) return Colors.orange;
    if (title.contains('나비')) return Colors.pink;
    if (title.contains('동물')) return Colors.green;
    if (title.contains('무지개')) return Colors.purple;
    if (title.contains('별')) return Colors.blue;
    if (title.contains('숫자')) return Colors.teal;
    return Colors.indigo;
  }
}

class _PopularTab extends StatelessWidget {
  const _PopularTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인기 활동'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<ActivityProvider>(
                context,
                listen: false,
              );
              provider.loadPopularActivities();
            },
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.popularActivities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('인기 활동이 없습니다'),
                  const SizedBox(height: 8),
                  const Text('마이페이지에서 샘플 데이터를 추가해보세요'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadPopularActivities();
                    },
                    child: const Text('새로고침'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadPopularActivities();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: provider.popularActivities.length,
              itemBuilder: (context, index) {
                final activity = provider.popularActivities[index];
                return ActivityCard(activity: activity);
              },
            ),
          );
        },
      ),
    );
  }
}

class _MyPageTab extends StatefulWidget {
  const _MyPageTab();

  @override
  State<_MyPageTab> createState() => _MyPageTabState();
}

class _MyPageTabState extends State<_MyPageTab> {
  final _firebaseService = FirebaseService();
  Map<String, int> _userStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        final stats = await _firebaseService.getUserStats(currentUser.uid);
        if (mounted) {
          setState(() {
            _userStats = stats;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 프로필 카드
                    _buildProfileCard(),
                    const SizedBox(height: 20),

                    // 통계 카드들
                    _buildStatsSection(),
                    const SizedBox(height: 20),

                    // 메뉴 섹션
                    _buildMenuSection(),
                    const SizedBox(height: 20),

                    // 개발자 도구 (디버그용)
                    if (_firebaseService.currentUser != null)
                      _buildDeveloperSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final user = _firebaseService.currentUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.child_care,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? '익명 사용자',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.isAnonymous == true ? '체험 중' : '정회원',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '나의 활동 현황',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '완료한 활동',
                _userStats['completedActivities']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '연속 일수',
                '${_userStats['streakDays'] ?? 0}일',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '전체 활동',
                _userStats['totalActivities']?.toString() ?? '0',
                Icons.music_note,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '스티커',
                _userStats['totalStickers']?.toString() ?? '0',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '메뉴',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('활동 기록'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivityHistoryScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('도움말'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetupGuideScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('앱 정보'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showAppInfoDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '개발자 도구',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('샘플 데이터 추가'),
                subtitle: const Text('Firebase에 테스트 활동 데이터를 추가합니다'),
                onTap: () => _addSampleData(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.music_note, color: Colors.purple),
                title: const Text('가사 타이밍 정보 추가'),
                subtitle: const Text('기존 활동에 가사 동기화 타이밍을 추가합니다'),
                onTap: () => _updateLyricTimings(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.update, color: Colors.blue),
                title: const Text('S3 URL로 강제 업데이트'),
                subtitle: const Text('실제 S3 음악 파일 URL로 데이터를 업데이트합니다'),
                onTap: () => _forceUpdateWithS3Urls(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('모든 데이터 삭제'),
                subtitle: const Text('주의: 모든 활동 데이터가 삭제됩니다'),
                onTap: () => _clearAllData(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.volume_up),
              title: Text('소리'),
              trailing: Text('켜짐'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('말놀이뮤직'),
            SizedBox(height: 8),
            Text('버전: 1.0.0'),
            SizedBox(height: 8),
            Text('음악 기반 언어치료 앱'),
            SizedBox(height: 16),
            Text('3-7세 아이들을 위한\n언어발달 프로그램입니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLyricTimings() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('가사 타이밍 정보 업데이트 중...'),
            ],
          ),
        ),
      );

      await LyricTimingService.updateActivitiesWithTimings();

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가사 타이밍 정보가 업데이트되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // 홈 화면 데이터 새로고침
        final provider = Provider.of<ActivityProvider>(context, listen: false);
        provider.loadTodayActivities();
        provider.loadPopularActivities();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addSampleData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('샘플 데이터 추가 중...'),
            ],
          ),
        ),
      );

      await SampleDataService.addSampleActivities();

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('샘플 데이터가 추가되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // 홈 화면 데이터 새로고침
        final provider = Provider.of<ActivityProvider>(context, listen: false);
        provider.loadTodayActivities();
        provider.loadPopularActivities();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제'),
        content: const Text('정말 모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('데이터 삭제 중...'),
              ],
            ),
          ),
        );

        await SampleDataService.clearAllData();

        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모든 데이터가 삭제되었습니다.'),
              backgroundColor: Colors.orange,
            ),
          );

          // 홈 화면 데이터 새로고침
          final provider = Provider.of<ActivityProvider>(
            context,
            listen: false,
          );
          provider.loadTodayActivities();
          provider.loadPopularActivities();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _forceUpdateWithS3Urls() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('S3 URL 강제 업데이트'),
        content: const Text(
          'Firebase의 모든 활동 데이터를 실제 S3 음악 파일 URL로 업데이트하시겠습니까?\n기존 데이터가 덮어쓰여집니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('업데이트', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('S3 URL로 업데이트 중...'),
              ],
            ),
          ),
        );

        await SampleDataService.forceUpdateActivities();

        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('S3 URL로 활동 데이터가 업데이트되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );

          // 홈 화면 데이터 새로고침
          final provider = Provider.of<ActivityProvider>(
            context,
            listen: false,
          );
          provider.loadTodayActivities();
          provider.loadPopularActivities();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업데이트 오류: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class ActivityCard extends StatelessWidget {
  final MusicActivity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.ageGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (activity.isPopular)
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                activity.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    activity.likeCount.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '난이도 ${activity.difficulty}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? iconColor;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFullWidth = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: isFullWidth ? 40 : 32,
                color: iconColor ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isFullWidth ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isFullWidth ? 13 : 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseService().signOut();
              // AuthWrapper가 자동으로 로그인 화면으로 이동
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}
