import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../widgets/common/section_card.dart';

class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(title: '업적'),
      body: Column(
        children: [
          // 탭 바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: '전체'),
                Tab(text: '획득'),
                Tab(text: '진행중'),
              ],
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAchievementsTab(),
                _buildEarnedAchievementsTab(),
                _buildInProgressAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 진행률 요약
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '업적 진행률',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProgressItem(
                        icon: Icons.military_tech,
                        label: '획득한 업적',
                        value: '12',
                        total: '50',
                        color: Colors.amber,
                      ),
                      _buildProgressItem(
                        icon: Icons.trending_up,
                        label: '진행률',
                        value: '24%',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 운동 관련 업적
          _buildAchievementCategory(
            title: '🏃‍♂️ 운동 업적',
            achievements: [
              _buildAchievementItem(
                title: '첫 걸음',
                description: '첫 번째 운동을 완료하세요',
                progress: 1.0,
                isEarned: true,
                icon: Icons.directions_run,
                color: Colors.green,
              ),
              _buildAchievementItem(
                title: '일주일의 전사',
                description: '7일 연속으로 운동하세요',
                progress: 0.6,
                isEarned: false,
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
              _buildAchievementItem(
                title: '마라톤러',
                description: '총 42.195km를 달리세요',
                progress: 0.3,
                isEarned: false,
                icon: Icons.flag,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 습관 관련 업적
          _buildAchievementCategory(
            title: '🎯 습관 업적',
            achievements: [
              _buildAchievementItem(
                title: '습관의 시작',
                description: '첫 번째 습관을 완료하세요',
                progress: 1.0,
                isEarned: true,
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildAchievementItem(
                title: '습관 마스터',
                description: '30일 연속으로 습관을 완료하세요',
                progress: 0.4,
                isEarned: false,
                icon: Icons.star,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 소셜 관련 업적
          _buildAchievementCategory(
            title: '👥 소셜 업적',
            achievements: [
              _buildAchievementItem(
                title: '친구 만들기',
                description: '첫 번째 친구를 추가하세요',
                progress: 1.0,
                isEarned: true,
                icon: Icons.person_add,
                color: Colors.orange,
              ),
              _buildAchievementItem(
                title: '클럽 리더',
                description: '클럽을 생성하세요',
                progress: 0.0,
                isEarned: false,
                icon: Icons.group,
                color: Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAchievementItem(
            title: '첫 걸음',
            description: '첫 번째 운동을 완료하세요',
            progress: 1.0,
            isEarned: true,
            icon: Icons.directions_run,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            title: '습관의 시작',
            description: '첫 번째 습관을 완료하세요',
            progress: 1.0,
            isEarned: true,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            title: '친구 만들기',
            description: '첫 번째 친구를 추가하세요',
            progress: 1.0,
            isEarned: true,
            icon: Icons.person_add,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAchievementItem(
            title: '일주일의 전사',
            description: '7일 연속으로 운동하세요',
            progress: 0.6,
            isEarned: false,
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            title: '마라톤러',
            description: '총 42.195km를 달리세요',
            progress: 0.3,
            isEarned: false,
            icon: Icons.flag,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            title: '습관 마스터',
            description: '30일 연속으로 습관을 완료하세요',
            progress: 0.4,
            isEarned: false,
            icon: Icons.star,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    String? total,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (total != null) ...[
          Text(
            '/ $total',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCategory({
    required String title,
    required List<Widget> achievements,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            ...achievements,
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required String title,
    required String description,
    required double progress,
    required bool isEarned,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEarned ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEarned ? color : Colors.grey.shade300,
          width: isEarned ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEarned ? color : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEarned ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEarned ? color : Colors.black,
                        ),
                      ),
                    ),
                    if (isEarned)
                      Icon(
                        Icons.check_circle,
                        color: color,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isEarned) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toInt()}% 완료',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
