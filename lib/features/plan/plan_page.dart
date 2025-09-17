import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/kpi_ring.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/profile_menu.dart';
import '../../providers/today_summary_provider.dart';
import '../../providers/user_goals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cache_service.dart';
import '../../services/analytics_service.dart';
import '../../services/recommendation_service.dart';
import '../../models/today_summary.dart';
import '../../models/user_goals.dart';
import '../habit/habit_page.dart';
import '../workout/workout_page.dart';
import '../meals/meal_page.dart';
import '../settings/goal_settings_page.dart';
import '../notifications/notifications_page.dart';

class PlanPage extends ConsumerStatefulWidget {
  final String? action; // 빠른 액션 파라미터

  const PlanPage({super.key, this.action});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Smart Recommendations 관련 변수들
  final AnalyticsService _analyticsService = AnalyticsService();
  final RecommendationService _recommendationService = RecommendationService();
  UserPattern? _userPattern;
  List<GoalAdjustment> _goalAdjustments = [];
  List<HabitSuggestion> _habitSuggestions = [];
  String _personalizedInsight = '';
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // 액션 파라미터가 있으면 해당 액션 실행
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAction(widget.action!);
      });
    }

    // Smart Recommendations 로드
    _loadSmartRecommendations();

    // 페이지 로드 시 provider 새로고침 및 캐시 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 Plan 페이지 로드됨 - provider 새로고침 트리거');

      // 캐시가 비어있거나 오래된 경우 강제 새로고침
      _checkAndRefreshIfNeeded();

      // 프로필 사진 로드를 위한 추가 대기
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {}); // 프로필 사진 재렌더링 트리거
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요

    final todaySummary = ref.watch(todaySummaryProvider);
    final userGoals = ref.watch(userGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '플랜',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
              ),
              // Red dot for unread notifications
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _showProfileMenu(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    ref.read(authProviderProvider).user?.photoURL != null
                        ? NetworkImage(
                            ref.read(authProviderProvider).user!.photoURL!)
                        : null,
                child: ref.read(authProviderProvider).user?.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(todaySummaryProvider.future);
          await ref.refresh(userGoalsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 오늘의 목표 섹션 (Today 기능 통합)
              _buildTodaySection(todaySummary, userGoals),
              const SizedBox(height: 24),

              // 스마트 추천 섹션
              _buildSmartRecommendationSection(),
              const SizedBox(height: 24),

              // 목표 설정 섹션
              _buildGoalSettingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection(
      AsyncValue<TodaySummary> todaySummary, AsyncValue<UserGoals> userGoals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 인사말 섹션
        _buildGreeting(),
        const SizedBox(height: 24),

        // KPI 링 섹션
        _buildKpiRings(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 인사말 섹션
  Widget _buildGreeting() {
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
            data: (goals) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: KpiRing.calories(
                      value: summary.activeCalories.toInt().toString(),
                      progress: summary
                          .getActiveCaloriesProgress(goals.activeCaloriesGoal),
                      subtitle: '목표: ${goals.activeCaloriesGoal.toInt()}kcal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KpiRing.exercise(
                      value: '${summary.exerciseMinutes}분',
                      progress: summary
                          .getExerciseProgress(goals.exerciseMinutesGoal),
                      subtitle: '목표: ${goals.exerciseMinutesGoal}분',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KpiRing.habits(
                      value: summary.habitStatusText,
                      progress: summary.habitProgress,
                      subtitle:
                          '완료율: ${summary.habitCompletionRate.toStringAsFixed(0)}%',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HabitPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KpiRing.meals(
                      value: '${summary.mealCount}끼',
                      progress: summary.getMealProgress(3), // 하루 3끼 목표
                      subtitle: '목표: 3끼',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16), // 마지막에 여백 추가
                ],
              ),
            ),
            loading: () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: KpiRing.calories(
                      value: summary.activeCalories.toInt().toString(),
                      progress: summary.getActiveCaloriesProgress(400.0),
                      subtitle: '목표: 400kcal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KpiRing.exercise(
                      value: '${summary.exerciseMinutes}분',
                      progress: summary.getExerciseProgress(30),
                      subtitle: '목표: 30분',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KpiRing.habits(
                      value: summary.habitStatusText,
                      progress: summary.habitProgress,
                      subtitle:
                          '완료율: ${summary.habitCompletionRate.toStringAsFixed(0)}%',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HabitPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: KpiRing.meals(
                      value: '${summary.mealCount}끼',
                      progress: summary.getMealProgress(3), // 하루 3끼 목표
                      subtitle: '목표: 3끼',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16), // 마지막에 여백 추가
                ],
              ),
            ),
            error: (error, stack) => const Text('목표 로딩 실패'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Text('데이터 로딩 실패'),
        );
      },
    );
  }

  /// 액션 처리
  void _handleAction(String action) {
    switch (action) {
      case 'habits':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HabitPage(),
          ),
        );
        break;
      case 'workout':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutPage(),
          ),
        );
        break;
      case 'meal':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MealPage(),
          ),
        );
        break;
    }
  }

  /// 캐시 확인 및 새로고침
  void _checkAndRefreshIfNeeded() async {
    final cacheKey = 'today_summary_cache';
    final cachedData = await CacheService.getCache(cacheKey);

    if (cachedData == null) {
      print('🔄 Today 캐시가 없거나 만료됨 - 강제 새로고침');
      await ref.refresh(todaySummaryProvider.future);
    } else {
      print('✅ Today 캐시 유효함 - 일반 새로고침');
    }
  }

  /// 요일 이름 반환
  String _getWeekdayName(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }

  /// 월 이름 반환
  String _getMonthName(int month) {
    const months = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월'
    ];
    return months[month - 1];
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileMenu(),
    );
  }

  /// Smart Recommendations 로드
  Future<void> _loadSmartRecommendations() async {
    final authProvider = ref.read(authProviderProvider);
    final user = authProvider.user;
    if (user == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // 사용자 패턴 분석
      _userPattern = await _analyticsService.analyzeUserPattern(user.uid);

      // 목표 조정 제안
      _goalAdjustments =
          await _recommendationService.suggestGoalAdjustments(user.uid);

      // 새로운 습관 제안
      _habitSuggestions =
          await _recommendationService.suggestNewHabits(user.uid);

      // 개인화된 인사이트
      _personalizedInsight =
          await _recommendationService.generatePersonalizedInsight(user.uid);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ 스마트 추천 로드 실패: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  /// Smart Recommendations 섹션 빌드
  Widget _buildSmartRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '🤖 스마트 추천',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        if (_isAnalyzing) ...[
          _buildAnalyzingCard(),
        ] else if (_userPattern != null) ...[
          if (_personalizedInsight.isNotEmpty) _buildPersonalizedInsightCard(),
          if (_goalAdjustments.isNotEmpty) _buildGoalAdjustmentCard(),
        ] else ...[
          _buildNoDataCard(),
        ],
      ],
    );
  }

  /// 분석 중 카드
  Widget _buildAnalyzingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              '데이터를 분석하고 있어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개인화된 인사이트 카드
  Widget _buildPersonalizedInsightCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                const Text(
                  '개인화된 인사이트',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _personalizedInsight,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 목표 조정 제안 카드
  Widget _buildGoalAdjustmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  '목표 조정 제안',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._goalAdjustments.map((adjustment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adjustment.habitType,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _getGoalChangeText(adjustment.currentGoal,
                                  adjustment.suggestedGoal),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              adjustment.reason,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(adjustment.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 데이터 없음 카드
  Widget _buildNoDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              '아직 충분한 데이터가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '습관을 실천해보시면\n개인화된 추천을 받을 수 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSmartRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 분석하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 목표 설정 섹션
  Widget _buildGoalSettingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '🎯 목표 설정',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.fitness_center, color: Colors.orange.shade600),
                  title: const Text('운동 목표'),
                  subtitle: const Text('일일 운동 시간 설정'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 운동 목표 설정 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.local_fire_department,
                      color: Colors.red.shade600),
                  title: const Text('칼로리 목표'),
                  subtitle: const Text('일일 소모 칼로리 설정'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 칼로리 목표 설정 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading:
                      Icon(Icons.directions_walk, color: Colors.green.shade600),
                  title: const Text('걸음 수 목표'),
                  subtitle: const Text('일일 걸음 수 설정'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 걸음 수 목표 설정 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 목표 변화를 사용자 친화적인 텍스트로 변환
  String _getGoalChangeText(int currentGoal, int suggestedGoal) {
    if (currentGoal == suggestedGoal) {
      return '현재 목표 유지';
    } else if (suggestedGoal > currentGoal) {
      return '목표 증가 제안';
    } else {
      return '목표 감소 제안';
    }
  }
}
