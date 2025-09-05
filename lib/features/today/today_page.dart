import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../widgets/common/kpi_ring.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/mini_spark.dart';
import '../../providers/today_summary_provider.dart';
import '../../providers/user_goals_provider.dart';
import '../../usecases/coach_usecase.dart';
import '../habit/habit_page.dart';
import '../workout/workout_page.dart';
import '../meals/meal_page.dart';

/// Today 페이지 - 실행 중심: "지금 뭘 해야 하지?"
class TodayPage extends ConsumerStatefulWidget {
  final String? action; // 빠른 액션 파라미터

  const TodayPage({super.key, this.action});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    // 액션 파라미터가 있으면 해당 액션 실행
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAction(widget.action!);
      });
    }

    // 디버깅: 페이지 로드 시 provider 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 Today 페이지 로드됨 - provider 새로고침 트리거');
      ref.invalidate(todaySummaryProvider);
      ref.invalidate(userGoalsProvider);
    });
  }

  @override
  bool get wantKeepAlive => true; // 페이지 상태 유지

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppBarWithNotifications(title: 'Today'),
        body: SafeArea(
          child: RepaintBoundary(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 오늘 날짜와 인사말
                    _buildTodayHeader(),
                    const SizedBox(height: 24),

                    // KPI 링 (칼로리, 단백질, 습관)
                    _buildKpiRings(),
                    const SizedBox(height: 24),

                    // 빠른 액션 버튼들
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // 오늘의 진행 상황
                    _buildTodayProgress(),
                    const SizedBox(height: 24),

                    // AI 코칭 메시지
                    _buildCoachingMessage(),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  /// 오늘 날짜와 인사말
  Widget _buildTodayHeader() {
    final now = DateTime.now();
    final weekday = _getWeekdayName(now.weekday);
    final day = now.day;
    final month = _getMonthName(now.month);
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = '좋은 아침이에요!';
    } else if (hour < 18) {
      greeting = '좋은 오후에요!';
    } else {
      greeting = '좋은 저녁이에요!';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$weekday, $day $month',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /// KPI 링 섹션
  Widget _buildKpiRings() {
    return Consumer(
      builder: (context, ref, child) {
        final todaySummaryAsync = ref.watch(todaySummaryProvider);
        final userGoalsAsync = ref.watch(userGoalsProvider);

        return todaySummaryAsync.when(
          data: (summary) => userGoalsAsync.when(
            data: (goals) => SizedBox(
              height: 160,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Expanded(
                      child: KpiRing.calories(
                        value: summary.activeCalories.toInt().toString(),
                        progress: summary.getActiveCaloriesProgress(
                            goals.activeCaloriesGoal),
                        subtitle: '목표: ${goals.activeCaloriesGoal.toInt()}kcal',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiRing.exercise(
                        value: '${summary.exerciseMinutes}분',
                        progress: summary
                            .getExerciseProgress(goals.exerciseMinutesGoal),
                        subtitle: '목표: ${goals.exerciseMinutesGoal}분',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiRing.habits(
                        value: summary.habitStatusText,
                        progress: summary.habitProgress,
                        subtitle:
                            '완료율: ${summary.habitCompletionRate.toStringAsFixed(0)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiRing.steps(
                        value: summary.steps.toString(),
                        progress: summary.getStepsProgress(goals.stepsGoal),
                        subtitle: '목표: ${goals.stepsGoal}걸음',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => _buildKpiRingsLoading(),
            error: (error, stack) => _buildKpiRingsError(),
          ),
          loading: () => _buildKpiRingsLoading(),
          error: (error, stack) => _buildKpiRingsError(),
        );
      },
    );
  }

  /// KPI 링 로딩 상태
  Widget _buildKpiRingsLoading() {
    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// KPI 링 에러 상태
  Widget _buildKpiRingsError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Center(
        child: Text(
          '데이터를 불러올 수 없습니다',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  /// 빠른 액션 버튼들
  Widget _buildQuickActions() {
    return SectionCard(
      title: '빠른 액션',
      icon: Icons.flash_on,
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.check_circle,
                  label: '습관 체크',
                  color: Colors.green,
                  onTap: () => _navigateToHabits(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.fitness_center,
                  label: '운동 시작',
                  color: Colors.blue,
                  onTap: () => _navigateToWorkout(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.restaurant,
                  label: '식사 기록',
                  color: Colors.orange,
                  onTap: () => _navigateToMeals(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.directions_walk,
                  label: '걷기 시작',
                  color: Colors.purple,
                  onTap: () => _startWalking(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 빠른 액션 버튼
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 오늘의 진행 상황
  Widget _buildTodayProgress() {
    return Consumer(
      builder: (context, ref, child) {
        final todaySummaryAsync = ref.watch(todaySummaryProvider);

        return todaySummaryAsync.when(
          data: (summary) => SectionCard(
            title: '오늘의 진행',
            icon: Icons.timeline,
            color: Colors.green.shade50,
            child: Column(
              children: [
                // 걸음 수 미니 스파크라인
                if (summary.steps > 0) ...[
                  StepsMiniSpark(
                    stepsData: _generateStepsData(summary.steps),
                    label: '걸음 수',
                  ),
                  const SizedBox(height: 16),
                ],

                // 진행률 요약
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressItem(
                        '습관',
                        summary.habitStatusText,
                        summary.habitProgress,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgressItem(
                        '운동',
                        summary.workoutStatusText,
                        summary.completedWorkouts / 3.0, // 목표: 3개
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => _buildProgressLoading(),
          error: (error, stack) => _buildProgressError(),
        );
      },
    );
  }

  /// 진행률 아이템
  Widget _buildProgressItem(
      String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  /// 진행 상황 로딩
  Widget _buildProgressLoading() {
    return SectionCard(
      title: '오늘의 진행',
      icon: Icons.timeline,
      color: Colors.green.shade50,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 진행 상황 에러
  Widget _buildProgressError() {
    return SectionCard(
      title: '오늘의 진행',
      icon: Icons.timeline,
      color: Colors.green.shade50,
      child: const Center(
        child: Text('데이터를 불러올 수 없습니다'),
      ),
    );
  }

  /// AI 코칭 메시지
  Widget _buildCoachingMessage() {
    return Consumer(
      builder: (context, ref, child) {
        final todaySummaryAsync = ref.watch(todaySummaryProvider);

        return todaySummaryAsync.when(
          data: (summary) {
            final coachingMessage =
                CoachUseCase.generateTodayCoaching(summary, null);
            final motivationalMessage =
                CoachUseCase.generateMotivationalMessage(summary, null);

            return SectionCard(
              title: 'AI 코칭',
              icon: Icons.psychology,
              color: Colors.purple.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coachingMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            motivationalMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildCoachingLoading(),
          error: (error, stack) => _buildCoachingError(),
        );
      },
    );
  }

  /// 코칭 로딩
  Widget _buildCoachingLoading() {
    return SectionCard(
      title: 'AI 코칭',
      icon: Icons.psychology,
      color: Colors.purple.shade50,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 코칭 에러
  Widget _buildCoachingError() {
    return SectionCard(
      title: 'AI 코칭',
      icon: Icons.psychology,
      color: Colors.purple.shade50,
      child: const Center(
        child: Text('코칭 메시지를 불러올 수 없습니다'),
      ),
    );
  }

  /// 걸음 수 데이터 생성 (임시)
  List<int> _generateStepsData(int todaySteps) {
    // 임시로 오늘 걸음 수를 기반으로 7일 데이터 생성
    final data = <int>[];
    for (int i = 0; i < 7; i++) {
      data.add((todaySteps * (0.7 + (i * 0.05))).round());
    }
    return data;
  }

  /// 액션 처리
  void _handleAction(String action) {
    switch (action) {
      case 'habits':
        _navigateToHabits();
        break;
      case 'workout':
        _navigateToWorkout();
        break;
      case 'meals':
        _navigateToMeals();
        break;
      default:
        break;
    }
  }

  /// 네비게이션 메서드들
  void _navigateToHabits() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitPage()),
    );
  }

  void _navigateToWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutPage()),
    );
  }

  void _navigateToMeals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MealPage()),
    );
  }

  void _startWalking() {
    // TODO: 걷기 시작 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('걷기 기능은 곧 추가될 예정입니다!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// 요일 이름 변환
  String _getWeekdayName(int weekday) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[weekday - 1];
  }

  /// 월 이름 변환
  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }
}
