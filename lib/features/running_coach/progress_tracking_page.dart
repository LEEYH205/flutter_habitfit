import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/running_coach.dart';
import '../../services/running_coach_service.dart';
import '../../widgets/app_bar_with_notifications.dart';

/// 진행 상황 추적 페이지
class ProgressTrackingPage extends ConsumerStatefulWidget {
  const ProgressTrackingPage({super.key});

  @override
  ConsumerState<ProgressTrackingPage> createState() =>
      _ProgressTrackingPageState();
}

class _ProgressTrackingPageState extends ConsumerState<ProgressTrackingPage>
    with SingleTickerProviderStateMixin {
  final RunningCoachService _coachService = RunningCoachService();

  late TabController _tabController;

  List<TrainingPlan> _trainingPlans = [];
  RunningCoachSettings? _settings;
  bool _isLoading = true;

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

      final plans = await _coachService.getUserTrainingPlans();
      final settings = await _coachService.getCoachSettings();

      setState(() {
        _trainingPlans = plans;
        _settings = settings;
      });
    } catch (e) {
      print('❌ 진행 상황 데이터 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBarWithNotifications(
          title: '📊 진행 상황',
          showProfile: false,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '📊 진행 상황',
        showProfile: false,
      ),
      body: Column(
        children: [
          // 탭 바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade600,
              tabs: const [
                Tab(text: '주간'),
                Tab(text: '월간'),
                Tab(text: '전체'),
              ],
            ),
          ),
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyProgress(),
                _buildMonthlyProgress(),
                _buildOverallProgress(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWeekCard(),
            const SizedBox(height: 20),
            _buildWeeklyStats(),
            const SizedBox(height: 20),
            _buildNextWeekPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyProgress() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyStats(),
            const SizedBox(height: 20),
            _buildMonthlyChart(),
            const SizedBox(height: 20),
            _buildMonthlyGoals(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStats(),
            const SizedBox(height: 20),
            _buildTrainingHistory(),
            const SizedBox(height: 20),
            _buildAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeekCard() {
    if (_trainingPlans.isEmpty) {
      return _buildEmptyState();
    }

    final activePlan = _trainingPlans.first; // 단일 활성 계획
    final now = DateTime.now();
    final startDate = activePlan.startDate;
    final currentWeek = now.difference(startDate).inDays ~/ 7 + 1;
    final totalWeeks = activePlan.totalWeeks;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  '현재 $currentWeek주차',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '전체 $totalWeeks주 중 $currentWeek주차 진행 중',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: currentWeek / totalWeeks,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(currentWeek / totalWeeks * 100).toStringAsFixed(1)}% 완료',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 주 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.directions_run,
                    label: '총 거리',
                    value: '0km',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: '운동 시간',
                    value: '0분',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.speed,
                    label: '평균 페이스',
                    value: '0:00/km',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: '완료율',
                    value: '0%',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextWeekPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '다음 주 미리보기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNextWeekSchedule(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextWeekSchedule() {
    if (_trainingPlans.isEmpty) {
      return const Center(
        child: Text(
          '활성화된 훈련 계획이 없습니다',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    final activePlan = _trainingPlans.first;
    final now = DateTime.now();
    final startDate = activePlan.startDate;
    final currentWeek = now.difference(startDate).inDays ~/ 7 + 1;
    final nextWeekStart = startDate.add(Duration(days: currentWeek * 7));

    return Column(
      children: List.generate(7, (index) {
        final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
        final targetDate = nextWeekStart.add(Duration(days: index));
        final isToday =
            targetDate.day == now.day && targetDate.month == now.month;

        // 해당 날짜의 훈련 계획 찾기
        final dayPlan = _getDayPlan(activePlan, targetDate);
        final workoutType = dayPlan?.type.displayName ?? '휴식';
        final workoutIcon = _getWorkoutIcon(workoutType);
        final workoutColor = _getWorkoutColor(workoutType);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: Colors.blue.shade200) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? '오늘: $workoutType'
                          : '${dayNames[index]}요일: $workoutType',
                      style: TextStyle(
                        fontSize: 14,
                        color: isToday
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (dayPlan != null && dayPlan.distance != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${dayPlan.distance!.toStringAsFixed(1)}km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                workoutIcon,
                color: isToday ? Colors.blue : workoutColor,
                size: 20,
              ),
            ],
          ),
        );
      }),
    );
  }

  DailyWorkout? _getDayPlan(TrainingPlan plan, DateTime targetDate) {
    try {
      // 해당 날짜가 훈련 계획 기간 내에 있는지 확인
      if (targetDate.isBefore(plan.startDate) ||
          targetDate.isAfter(plan.endDate)) {
        return null;
      }

      // 주차 계산
      final weekIndex = targetDate.difference(plan.startDate).inDays ~/ 7;
      if (weekIndex >= plan.weeklyPlans.length) return null;

      final week = plan.weeklyPlans[weekIndex];
      final dayOfWeek = targetDate.weekday - 1; // 월요일 = 0

      if (dayOfWeek >= week.dailyWorkouts.length) return null;
      return week.dailyWorkouts[dayOfWeek];
    } catch (e) {
      print('❌ 일일 계획 조회 오류: $e');
      return null;
    }
  }

  IconData _getWorkoutIcon(String type) {
    switch (type.toLowerCase()) {
      case '휴식':
        return Icons.hotel;
      case '회복':
        return Icons.healing;
      case '기초체력':
        return Icons.directions_run;
      case '존2':
        return Icons.speed;
      case 'lsd':
        return Icons.timeline;
      case '템포런':
        return Icons.timer;
      case '인터벌':
        return Icons.repeat;
      case 'vo2 max':
        return Icons.flash_on;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getWorkoutColor(String type) {
    switch (type.toLowerCase()) {
      case '휴식':
        return Colors.grey.shade400;
      case '회복':
        return Colors.green.shade400;
      case '기초체력':
        return Colors.blue.shade400;
      case '존2':
        return Colors.orange.shade400;
      case 'lsd':
        return Colors.purple.shade400;
      case '템포런':
        return Colors.red.shade400;
      case '인터벌':
        return Colors.pink.shade400;
      case 'vo2 max':
        return Colors.deepOrange.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildMonthlyStats() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 달 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.directions_run,
                    label: '총 거리',
                    value: '0km',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: '운동 시간',
                    value: '0분',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up,
                    label: '개선률',
                    value: '+0%',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    label: '목표 달성',
                    value: '0%',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '월간 진행 차트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '차트 데이터 준비 중...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGoals() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 달 목표',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalItem('주간 러닝 거리', '0km', '목표: 20km', Colors.green),
            const SizedBox(height: 12),
            _buildGoalItem('운동 일수', '0일', '목표: 15일', Colors.blue),
            const SizedBox(height: 12),
            _buildGoalItem('평균 페이스', '0:00/km', '목표: 5:30/km', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전체 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.directions_run,
                    label: '총 거리',
                    value: '0km',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: '총 시간',
                    value: '0시간',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today,
                    label: '운동 일수',
                    value: '0일',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.emoji_events,
                    label: '완료 계획',
                    value: '0개',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '훈련 히스토리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_trainingPlans.isEmpty)
              const Center(
                child: Text(
                  '아직 완료된 훈련 계획이 없습니다',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            else
              ..._trainingPlans.map((plan) => _buildHistoryItem(plan)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '업적',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '업적 시스템 준비 중...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildGoalItem(
      String title, String current, String target, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$current / $target',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '0%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(TrainingPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '훈련 계획',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${plan.totalWeeks}주 계획',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '완료',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.directions_run,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 활성화된 훈련 계획이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '러닝 이벤트를 생성하고 훈련 계획을 시작해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
