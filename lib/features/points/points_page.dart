import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/points_system.dart';
import '../../services/points_service.dart';

/// 포인트 및 레벨 페이지
class PointsPage extends ConsumerStatefulWidget {
  const PointsPage({super.key});

  @override
  ConsumerState<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends ConsumerState<PointsPage>
    with TickerProviderStateMixin {
  final PointsService _pointsService = PointsService();

  UserPoints? _userPoints;
  List<PointEarned> _pointsHistory = [];
  List<Achievement> _achievements = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final futures = await Future.wait([
        _pointsService.getCurrentUserPoints(),
        _pointsService.getPointsHistory(limit: 20),
        _pointsService.getUserAchievements(),
        _pointsService.getPointsStats(),
      ]);

      setState(() {
        _userPoints = futures[0] as UserPoints?;
        _pointsHistory = futures[1] as List<PointEarned>;
        _achievements = futures[2] as List<Achievement>;
        _stats = futures[3] as Map<String, dynamic>;
      });
    } catch (e) {
      print('❌ 포인트 데이터 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터를 불러오는데 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testEarnPoints() async {
    try {
      final success = await _pointsService.earnPoints(
        type: PointType.bonus,
        customPoints: 50,
        description: '테스트 포인트',
        context: {'test': true},
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스트 포인트를 획득했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 포인트 획득에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userPoints == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('포인트 & 레벨'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('포인트 정보를 불러올 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 포인트 & 레벨'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: const Icon(Icons.emoji_events),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _testEarnPoints,
            tooltip: '테스트 포인트',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_circle), text: '레벨'),
            Tab(icon: Icon(Icons.history), text: '기록'),
            Tab(icon: Icon(Icons.emoji_events), text: '업적'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLevelTab(),
          _buildHistoryTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildLevelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 레벨 카드
          _buildLevelCard(),

          const SizedBox(height: 16),

          // 포인트 통계
          _buildStatsCard(),

          const SizedBox(height: 16),

          // 레벨 정보
          _buildLevelInfoCard(),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color(_userPoints!.levelColor),
              Color(_userPoints!.levelColor).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    _userPoints!.levelIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userPoints!.levelName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '레벨 ${_userPoints!.currentLevel}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_userPoints!.totalPoints} 포인트',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 레벨 진행률
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '다음 레벨까지',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_userPoints!.pointsNeededForNextLevel} 포인트',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _userPoints!.levelProgress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_userPoints!.levelProgress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '포인트 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_stats.isNotEmpty) ...[
              _buildStatRow('총 포인트', '${_stats['totalPoints'] ?? 0}'),
              _buildStatRow('현재 레벨', '${_stats['currentLevel'] ?? 1}'),
              _buildStatRow('레벨명', _stats['levelName'] ?? '초보자'),
              _buildStatRow('최근 30일 포인트', '${_stats['recentPoints'] ?? 0}'),
              _buildStatRow('달성한 업적', '${_stats['totalAchievements'] ?? 0}개'),
            ] else ...[
              const Text('통계 정보를 불러올 수 없습니다.'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfoCard() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '레벨 시스템 안내',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• 습관 완료: 10포인트 (연속 달성 시 보너스)\n'
              '• 운동 완료: 20포인트 (시간/칼로리 보너스)\n'
              '• 목표 달성: 50포인트 (달성도 보너스)\n'
              '• 업적 달성: 25-500포인트\n'
              '• 레벨업 시 보너스 포인트 지급',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pointsHistory.length,
      itemBuilder: (context, index) {
        final point = _pointsHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                '+${point.points}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(point.type.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (point.description != null) ...[
                  Text(point.description!),
                ],
                Text(
                  _formatDateTime(point.earnedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              _getPointTypeIcon(point.type),
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    if (_achievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '아직 달성한 업적이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '습관을 완료하고 운동을 하면\n업적을 달성할 수 있습니다!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.withOpacity(0.1),
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              achievement.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 16,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${achievement.pointsReward} 포인트',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(achievement.unlockedAt!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  IconData _getPointTypeIcon(PointType type) {
    switch (type) {
      case PointType.habitCompleted:
        return Icons.check_circle;
      case PointType.workoutCompleted:
        return Icons.fitness_center;
      case PointType.streakAchieved:
        return Icons.local_fire_department;
      case PointType.goalAchieved:
        return Icons.flag;
      case PointType.dailyChallenge:
        return Icons.calendar_today;
      case PointType.weeklyChallenge:
        return Icons.date_range;
      case PointType.monthlyChallenge:
        return Icons.calendar_month;
      case PointType.socialShare:
        return Icons.share;
      case PointType.reviewWritten:
        return Icons.rate_review;
      case PointType.friendInvited:
        return Icons.person_add;
      case PointType.achievementUnlocked:
        return Icons.emoji_events;
      case PointType.bonus:
        return Icons.card_giftcard;
    }
  }
}
