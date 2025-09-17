import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/running_coach.dart';
import '../../widgets/app_bar_with_notifications.dart';

/// 훈련 계획 상세 페이지
class TrainingPlanPage extends ConsumerStatefulWidget {
  final TrainingPlan plan;

  const TrainingPlanPage({
    super.key,
    required this.plan,
  });

  @override
  ConsumerState<TrainingPlanPage> createState() => _TrainingPlanPageState();
}

class _TrainingPlanPageState extends ConsumerState<TrainingPlanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentWeek = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateCurrentWeek();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateCurrentWeek() {
    final now = DateTime.now();
    final daysSinceStart = now.difference(widget.plan.startDate).inDays;
    _currentWeek =
        ((daysSinceStart / 7).floor() + 1).clamp(1, widget.plan.totalWeeks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '📋 훈련 계획',
        showProfile: false,
      ),
      body: Column(
        children: [
          // 계획 개요
          _buildPlanOverview(),

          // 탭바
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '주간 계획'),
              Tab(text: '전체 개요'),
            ],
          ),

          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyPlanView(),
                _buildOverviewView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOverview() {
    final progress = DateTime.now().difference(widget.plan.startDate).inDays /
        widget.plan.endDate.difference(widget.plan.startDate).inDays;
    final progressPercent = (progress * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.plan.totalWeeks}주 훈련 계획',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPlanInfo(
                Icons.calendar_today,
                '현재 주차',
                '$_currentWeek주차',
              ),
              const SizedBox(width: 24),
              _buildPlanInfo(
                Icons.schedule,
                '남은 기간',
                '${widget.plan.endDate.difference(DateTime.now()).inDays}일',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyPlanView() {
    return Column(
      children: [
        // 주차 선택기
        _buildWeekSelector(),

        // 선택된 주의 훈련 계획
        Expanded(
          child: _buildWeeklyPlan(),
        ),
      ],
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.plan.totalWeeks,
        itemBuilder: (context, index) {
          final week = index + 1;
          final isSelected = week == _currentWeek;
          final weekPlan = widget.plan.weeklyPlans[index];
          final isCurrentWeek = week == _getCurrentWeekNumber();

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentWeek = week;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue
                    : isCurrentWeek
                        ? Colors.orange.shade100
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: isCurrentWeek && !isSelected
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$week주차',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isCurrentWeek
                                ? Colors.orange.shade700
                                : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: Text(
                        '${weekPlan.totalDistance.toStringAsFixed(0)}km',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? Colors.white70
                              : isCurrentWeek
                                  ? Colors.orange.shade600
                                  : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final daysSinceStart = now.difference(widget.plan.startDate).inDays;
    return ((daysSinceStart / 7).floor() + 1).clamp(1, widget.plan.totalWeeks);
  }

  Widget _buildWeeklyPlan() {
    if (_currentWeek > widget.plan.weeklyPlans.length) {
      return const Center(child: Text('해당 주차의 계획이 없습니다.'));
    }

    final weekPlan = widget.plan.weeklyPlans[_currentWeek - 1];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주차 정보
          _buildWeekInfo(weekPlan),

          const SizedBox(height: 20),

          // 일일 운동 계획
          const Text(
            '일일 운동 계획',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...weekPlan.dailyWorkouts
              .map((workout) => _buildDailyWorkoutCard(workout)),
        ],
      ),
    );
  }

  Widget _buildWeekInfo(WeeklyPlan weekPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                '$_currentWeek주차 포커스',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weekPlan.focus,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildWeekStat(
                  '총 거리', '${weekPlan.totalDistance.toStringAsFixed(1)}km'),
              const SizedBox(width: 24),
              _buildWeekStat('운동 일수',
                  '${weekPlan.dailyWorkouts.where((w) => !w.isRest).length}일'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyWorkoutCard(DailyWorkout workout) {
    final dayName = _getDayName(workout.date.weekday);
    final isToday = _isToday(workout.date);
    final isPast =
        workout.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Colors.orange
              : isPast
                  ? Colors.grey.shade300
                  : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 훈련 타입 아이콘
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(workout.type.colorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTrainingIcon(workout.type),
                    color: Color(workout.type.colorValue),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? Colors.orange
                                  : Colors.grey.shade700,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        workout.type.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!workout.isRest) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(workout.type.intensity)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '강도 ${workout.type.intensity}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getIntensityColor(workout.type.intensity),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 운동 상세 정보
            if (!workout.isRest) ...[
              Row(
                children: [
                  if (workout.distance != null) ...[
                    _buildWorkoutDetail(Icons.straighten,
                        '${workout.distance!.toStringAsFixed(1)}km'),
                    const SizedBox(width: 16),
                  ],
                  if (workout.targetPace != null) ...[
                    _buildWorkoutDetail(Icons.speed,
                        '${workout.targetPace!.inMinutes}:${(workout.targetPace!.inSeconds % 60).toString().padLeft(2, '0')}/km'),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // 운동 설명
            Text(
              workout.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),

            // 인터벌 정보
            if (workout.intervals != null && workout.intervals!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '인터벌 구성',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...workout.intervals!.map((interval) => Text(
                          '${interval.distance}km × ${interval.repetitions}회 (휴식 ${interval.restTime.inMinutes}분)',
                          style: const TextStyle(fontSize: 12),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 통계
          _buildOverallStats(),

          const SizedBox(height: 20),

          // 주차별 거리 차트
          _buildWeeklyDistanceChart(),

          const SizedBox(height: 20),

          // 훈련 타입 분포
          _buildTrainingTypeDistribution(),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final totalDistance = widget.plan.weeklyPlans
        .fold<double>(0, (sum, week) => sum + week.totalDistance);
    final totalWorkouts = widget.plan.weeklyPlans.fold<int>(0,
        (sum, week) => sum + week.dailyWorkouts.where((w) => !w.isRest).length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전체 훈련 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('총 거리',
                    '${totalDistance.toStringAsFixed(0)}km', Icons.straighten),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    '총 운동', '$totalWorkouts회', Icons.fitness_center),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('훈련 주수', '${widget.plan.totalWeeks}주',
                    Icons.calendar_today),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    '평균 주간 거리',
                    '${(totalDistance / widget.plan.totalWeeks).toStringAsFixed(1)}km',
                    Icons.timeline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDistanceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주차별 거리 변화',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.plan.weeklyPlans.length,
              itemBuilder: (context, index) {
                final week = widget.plan.weeklyPlans[index];
                final maxDistance = widget.plan.weeklyPlans
                    .map((w) => w.totalDistance)
                    .reduce((a, b) => a > b ? a : b);
                final height = (week.totalDistance / maxDistance) * 150;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        week.totalDistance.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: height,
                        decoration: BoxDecoration(
                          color: index + 1 == _getCurrentWeekNumber()
                              ? Colors.orange
                              : Colors.blue.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingTypeDistribution() {
    final typeCount = <TrainingType, int>{};

    for (final week in widget.plan.weeklyPlans) {
      for (final workout in week.dailyWorkouts) {
        typeCount[workout.type] = (typeCount[workout.type] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '훈련 타입 분포',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...typeCount.entries.map(
              (entry) => _buildTypeDistributionItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionItem(TrainingType type, int count) {
    final total = widget.plan.weeklyPlans.fold<int>(
      0,
      (sum, week) => sum + week.dailyWorkouts.length,
    );
    final percentage = (count / total * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(type.colorValue),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              type.displayName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '$count회 ($percentage%)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  IconData _getTrainingIcon(TrainingType type) {
    switch (type) {
      case TrainingType.rest:
        return Icons.bed;
      case TrainingType.recovery:
        return Icons.self_improvement;
      case TrainingType.base:
        return Icons.directions_walk;
      case TrainingType.zone2:
        return Icons.directions_run;
      case TrainingType.lsd:
        return Icons.landscape;
      case TrainingType.tempo:
        return Icons.speed;
      case TrainingType.interval:
        return Icons.timer;
      case TrainingType.vo2max:
        return Icons.flash_on;
    }
  }

  Color _getIntensityColor(int intensity) {
    if (intensity <= 2) return Colors.green;
    if (intensity <= 5) return Colors.blue;
    if (intensity <= 7) return Colors.orange;
    return Colors.red;
  }
}
