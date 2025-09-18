import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../common/services/local_notification_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../services/recommendation_service.dart';
import '../../services/user_cleanup_service.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';
import '../../services/cache_service.dart';
import '../../providers/today_summary_provider.dart';
import '../../router/app_router.dart';
import 'user_profile_page.dart';
import 'goal_settings_page.dart';
import 'notification_settings_page.dart';
import 'advanced_goal_settings_page.dart';
import '../running_coach/running_coach_page.dart';
import '../ranking/ranking_page.dart';
import '../watch/watch_test_page.dart';
import '../bug_report/bug_report_page.dart';
import '../points/points_page.dart';
import 'test_security_button.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SharedPreferences _prefs;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 사용자 정보
  User? _currentUser;

  // 서비스
  final HabitService _habitService = HabitService();
  bool _isAddingHabit = false;
  final Set<String> _addingHabits = <String>{}; // 추가 중인 습관 제목들

  // 알림 설정
  bool _workoutNotificationsEnabled = true;
  bool _habitRemindersEnabled = true;
  bool _dailySummaryEnabled = true;
  bool _goalAchievementEnabled = true;
  bool _weeklySummaryEnabled = true;

  // 확장된 알림 설정
  bool _missedHabitReminderEnabled = true;
  int _missedHabitReminderCount = 2; // 1-3회
  bool _snoozeEnabled = true;
  int _snoozeDuration = 15; // 10, 15, 30분
  bool _quietHoursEnabled = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _focusModeRespectEnabled = true;

  // 시간 설정
  TimeOfDay _habitReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _weeklySummaryTime = const TimeOfDay(hour: 20, minute: 0);

  // 요일별 반복 설정
  List<bool> _habitReminderDays = [
    true,
    true,
    true,
    true,
    true,
    false,
    false
  ]; // 월~일
  List<bool> _dailySummaryDays = [
    true,
    true,
    true,
    true,
    true,
    true,
    true
  ]; // 매일
  List<bool> _weeklySummaryDays = [
    false,
    false,
    false,
    false,
    false,
    false,
    true
  ]; // 일요일만

  // 고급 목표 설정
  bool _progressiveIncreaseEnabled = true;
  double _progressiveIncreaseRate = 0.05; // 5% 증가
  bool _deloadSystemEnabled = true;
  int _consecutiveFailuresForDeload = 2; // 연속 실패 2회
  double _deloadRate = 0.1; // 10% 감소
  bool _restDaysEnabled = true;
  List<bool> _restDays = [
    false,
    false,
    false,
    false,
    false,
    true,
    true
  ]; // 토, 일 휴식
  bool _weeklyResetEnabled = true;
  int _weeklyResetDay = 1; // 월요일 (1=월요일, 0=일요일)

  // 스마트 추천 관련
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
    _currentUser = _auth.currentUser;
    _loadSettings();
    _loadSmartRecommendations();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    setState(() {
      _workoutNotificationsEnabled =
          _prefs.getBool('workoutNotificationsEnabled') ?? true;
      _habitRemindersEnabled = _prefs.getBool('habitRemindersEnabled') ?? true;
      _dailySummaryEnabled = _prefs.getBool('dailySummaryEnabled') ?? true;
      _goalAchievementEnabled =
          _prefs.getBool('goalAchievementEnabled') ?? true;
      _weeklySummaryEnabled = _prefs.getBool('weeklySummaryEnabled') ?? true;

      // 확장된 알림 설정
      _missedHabitReminderEnabled =
          _prefs.getBool('missedHabitReminderEnabled') ?? true;
      _missedHabitReminderCount =
          _prefs.getInt('missedHabitReminderCount') ?? 2;
      _snoozeEnabled = _prefs.getBool('snoozeEnabled') ?? true;
      _snoozeDuration = _prefs.getInt('snoozeDuration') ?? 15;
      _quietHoursEnabled = _prefs.getBool('quietHoursEnabled') ?? true;
      _focusModeRespectEnabled =
          _prefs.getBool('focusModeRespectEnabled') ?? true;

      final quietStartHour = _prefs.getInt('quietHoursStartHour') ?? 22;
      final quietStartMinute = _prefs.getInt('quietHoursStartMinute') ?? 0;
      _quietHoursStart =
          TimeOfDay(hour: quietStartHour, minute: quietStartMinute);

      final quietEndHour = _prefs.getInt('quietHoursEndHour') ?? 7;
      final quietEndMinute = _prefs.getInt('quietHoursEndMinute') ?? 0;
      _quietHoursEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMinute);

      // 요일별 반복 설정
      _habitReminderDays = _prefs
              .getStringList('habitReminderDays')
              ?.map((e) => e == 'true')
              .toList() ??
          [true, true, true, true, true, false, false];
      _dailySummaryDays = _prefs
              .getStringList('dailySummaryDays')
              ?.map((e) => e == 'true')
              .toList() ??
          [true, true, true, true, true, true, true];
      _weeklySummaryDays = _prefs
              .getStringList('weeklySummaryDays')
              ?.map((e) => e == 'true')
              .toList() ??
          [false, false, false, false, false, false, true];

      // 고급 목표 설정
      _progressiveIncreaseEnabled =
          _prefs.getBool('progressiveIncreaseEnabled') ?? true;
      _progressiveIncreaseRate =
          _prefs.getDouble('progressiveIncreaseRate') ?? 0.05;
      _deloadSystemEnabled = _prefs.getBool('deloadSystemEnabled') ?? true;
      _consecutiveFailuresForDeload =
          _prefs.getInt('consecutiveFailuresForDeload') ?? 2;
      _deloadRate = _prefs.getDouble('deloadRate') ?? 0.1;
      _restDaysEnabled = _prefs.getBool('restDaysEnabled') ?? true;
      _restDays =
          _prefs.getStringList('restDays')?.map((e) => e == 'true').toList() ??
              [false, false, false, false, false, true, true];
      _weeklyResetEnabled = _prefs.getBool('weeklyResetEnabled') ?? true;
      _weeklyResetDay = _prefs.getInt('weeklyResetDay') ?? 1;

      final habitHour = _prefs.getInt('habitReminderHour') ?? 20;
      final habitMinute = _prefs.getInt('habitReminderMinute') ?? 0;
      _habitReminderTime = TimeOfDay(hour: habitHour, minute: habitMinute);

      final dailyHour = _prefs.getInt('dailySummaryHour') ?? 21;
      final dailyMinute = _prefs.getInt('dailySummaryMinute') ?? 0;
      _dailySummaryTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);

      final weeklyHour = _prefs.getInt('weeklySummaryHour') ?? 20;
      final weeklyMinute = _prefs.getInt('weeklySummaryMinute') ?? 0;
      _weeklySummaryTime = TimeOfDay(hour: weeklyHour, minute: weeklyMinute);
    });
  }

  Future<void> _loadSmartRecommendations() async {
    if (_currentUser == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // 사용자 패턴 분석
      _userPattern =
          await _analyticsService.analyzeUserPattern(_currentUser!.uid);

      // 목표 조정 제안
      _goalAdjustments = await _recommendationService
          .suggestGoalAdjustments(_currentUser!.uid);

      // 새로운 습관 제안
      _habitSuggestions =
          await _recommendationService.suggestNewHabits(_currentUser!.uid);

      // 개인화된 인사이트
      _personalizedInsight = await _recommendationService
          .generatePersonalizedInsight(_currentUser!.uid);

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

  Future<void> _saveSettings({bool showSnackBar = false}) async {
    await _prefs.setBool(
        'workoutNotificationsEnabled', _workoutNotificationsEnabled);
    await _prefs.setBool('habitRemindersEnabled', _habitRemindersEnabled);
    await _prefs.setBool('dailySummaryEnabled', _dailySummaryEnabled);
    await _prefs.setBool('goalAchievementEnabled', _goalAchievementEnabled);
    await _prefs.setBool('weeklySummaryEnabled', _weeklySummaryEnabled);

    // 확장된 알림 설정 저장
    await _prefs.setBool(
        'missedHabitReminderEnabled', _missedHabitReminderEnabled);
    await _prefs.setInt('missedHabitReminderCount', _missedHabitReminderCount);
    await _prefs.setBool('snoozeEnabled', _snoozeEnabled);
    await _prefs.setInt('snoozeDuration', _snoozeDuration);
    await _prefs.setBool('quietHoursEnabled', _quietHoursEnabled);
    await _prefs.setBool('focusModeRespectEnabled', _focusModeRespectEnabled);

    await _prefs.setInt('quietHoursStartHour', _quietHoursStart.hour);
    await _prefs.setInt('quietHoursStartMinute', _quietHoursStart.minute);
    await _prefs.setInt('quietHoursEndHour', _quietHoursEnd.hour);
    await _prefs.setInt('quietHoursEndMinute', _quietHoursEnd.minute);

    // 요일별 반복 설정 저장
    await _prefs.setStringList('habitReminderDays',
        _habitReminderDays.map((e) => e.toString()).toList());
    await _prefs.setStringList('dailySummaryDays',
        _dailySummaryDays.map((e) => e.toString()).toList());
    await _prefs.setStringList('weeklySummaryDays',
        _weeklySummaryDays.map((e) => e.toString()).toList());

    // 고급 목표 설정 저장
    await _prefs.setBool(
        'progressiveIncreaseEnabled', _progressiveIncreaseEnabled);
    await _prefs.setDouble('progressiveIncreaseRate', _progressiveIncreaseRate);
    await _prefs.setBool('deloadSystemEnabled', _deloadSystemEnabled);
    await _prefs.setInt(
        'consecutiveFailuresForDeload', _consecutiveFailuresForDeload);
    await _prefs.setDouble('deloadRate', _deloadRate);
    await _prefs.setBool('restDaysEnabled', _restDaysEnabled);
    await _prefs.setStringList(
        'restDays', _restDays.map((e) => e.toString()).toList());
    await _prefs.setBool('weeklyResetEnabled', _weeklyResetEnabled);
    await _prefs.setInt('weeklyResetDay', _weeklyResetDay);

    await _prefs.setInt('habitReminderHour', _habitReminderTime.hour);
    await _prefs.setInt('habitReminderMinute', _habitReminderTime.minute);
    await _prefs.setInt('dailySummaryHour', _dailySummaryTime.hour);
    await _prefs.setInt('dailySummaryMinute', _dailySummaryTime.minute);
    await _prefs.setInt('weeklySummaryHour', _weeklySummaryTime.hour);
    await _prefs.setInt('weeklySummaryMinute', _weeklySummaryTime.minute);

    // 설정 저장 후 알림 스케줄 업데이트
    await _updateNotificationSchedules();

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 설정이 저장되었습니다!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateNotificationSchedules() async {
    // 기존 알림 모두 취소
    await LocalNotificationService.instance.cancelAllScheduledNotifications();

    // 새로운 설정으로 알림 스케줄 설정
    if (_habitRemindersEnabled) {
      await LocalNotificationService.instance
          .scheduleHabitReminder(_habitReminderTime);
    }

    if (_weeklySummaryEnabled) {
      await LocalNotificationService.instance.scheduleWeeklyWorkoutSummary();
    }

    print('🔔 알림 스케줄이 업데이트되었습니다');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const AppBarWithNotifications(
          title: 'Settings',
          showProfile: false,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 사용자 정보 섹션
                _buildUserInfoSection(),

                const SizedBox(height: 24),

                // 알림 설정 섹션
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsPage(),
                      ),
                    );
                  },
                  child: _buildNotificationSettingsCard(),
                ),

                const SizedBox(height: 24),

                // 목표 설정 섹션
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSettingsPage(),
                      ),
                    );
                  },
                  child: _buildGoalSettingsCard(),
                ),

                const SizedBox(height: 24),

                // 고급 설정 섹션
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdvancedGoalSettingsPage(),
                      ),
                    );
                  },
                  child: _buildAdvancedNotificationCard(),
                ),

                const SizedBox(height: 24),

                // 러닝 코치 섹션
                _buildSectionHeader('🏃‍♂️ 러닝 코치'),
                _buildRunningCoachCard(),

                const SizedBox(height: 24),

                // 랭킹 섹션
                _buildSectionHeader('🏆 랭킹 & 친구'),
                _buildRankingCard(),

                const SizedBox(height: 24),

                // 스마트 추천 섹션
                _buildSectionHeader('🤖 스마트 추천'),

                if (_isAnalyzing) ...[
                  _buildAnalyzingCard(),
                ] else if (_userPattern != null) ...[
                  _buildPersonalizedInsightCard(),
                  _buildPatternAnalysisCard(),
                  if (_goalAdjustments.isNotEmpty) _buildGoalAdjustmentCard(),
                  if (_habitSuggestions.isNotEmpty) _buildHabitSuggestionCard(),
                ] else ...[
                  _buildNoDataCard(),
                ],

                const SizedBox(height: 24),

                // 워치 연동 테스트 섹션
                _buildSectionHeader('⌚ Apple Watch 연동'),
                _buildWatchTestCard(),

                const SizedBox(height: 16),

                // 버그 리포트 섹션
                _buildBugReportCard(),

                const SizedBox(height: 16),

                // 보안 테스트 섹션
                const TestSecurityButton(),

                const SizedBox(height: 16),

                // 포인트 섹션
                _buildPointsCard(),

                const SizedBox(height: 24),

                _buildNotificationTestSection(),
              ],
            ),
          ),
        ));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserProfilePage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                child: _currentUser?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          _currentUser!.photoURL!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.blue.shade600,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser?.displayName ?? '사용자',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _currentUser?.email ?? '이메일 없음',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '활성 계정',
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              '사용자 패턴을 분석하고 있습니다...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '최근 30일간의 습관 데이터를 분석하여\n개인화된 추천을 준비하고 있어요',
              textAlign: TextAlign.center,
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

  Widget _buildPersonalizedInsightCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternAnalysisCard() {
    if (_userPattern == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  '패턴 분석 결과',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '완료율',
                    '${(_userPattern!.overallCompletionRate * 100).toStringAsFixed(1)}%',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '일관성',
                    '${(_userPattern!.consistencyScore * 100).toStringAsFixed(1)}%',
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_userPattern!.bestTimeSlots.isNotEmpty) ...[
              const Text(
                '최적 시간대',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _userPattern!.bestTimeSlots.map((time) {
                  return Chip(
                    label: Text(time),
                    backgroundColor: Colors.blue.shade100,
                    labelStyle: TextStyle(
                      color: Colors.blue.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalAdjustmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.orange.shade600),
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
            ..._goalAdjustments.map((adjustment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adjustment.reason,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '신뢰도: ${(adjustment.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitSuggestionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  '새로운 습관 제안',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._habitSuggestions.take(3).map((suggestion) {
              return InkWell(
                onTap: () => _addSuggestedHabit(suggestion),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Text(
                        suggestion.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              suggestion.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(suggestion.relevanceScore * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isAddingHabit
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.purple.shade400,
                              ),
                            )
                          : Icon(
                              Icons.add_circle_outline,
                              color: Colors.purple.shade400,
                              size: 20,
                            ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

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

  Widget _buildNotificationTestSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          '🔔 알림 테스트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await LocalNotificationService.instance.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 테스트 알림을 보냈습니다!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('테스트 알림'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                // 습관 리마인더 즉시 테스트
                await LocalNotificationService.instance
                    .showHabitCompletionNotification(
                        '습관 체크 시간입니다!', '오늘의 습관을 완료해보세요 🎯');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📝 습관 리마인더 알림을 보냈습니다!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('습관 리마인더'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              // 잠금 화면 알림 테스트
              await LocalNotificationService.instance
                  .showHabitCompletionNotification(
                      '🔒 잠금 화면 알림 테스트', '화면이 꺼져 있어도 이 알림이 표시됩니다!');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔒 잠금 화면 알림을 보냈습니다!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              }
            },
            icon: const Icon(Icons.screen_lock_portrait, size: 18),
            label: const Text('잠금 화면 테스트'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '💡 잠금 화면 알림이 표시되지 않는다면:\n   • 설정 > 알림 > HabitFit에서 권한을 확인하세요\n   • "잠금 화면에 표시"가 켜져 있는지 확인하세요',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.notifications, color: Colors.blue.shade600, size: 24),
            const SizedBox(width: 12),
            const Text(
              '알림 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: '앱에서 받을 알림의 종류와 시간을 설정하세요',
              child: Icon(Icons.help_outline,
                  color: Colors.grey.shade600, size: 20),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GoalSettingsPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.red.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    '목표 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: '일일 목표를 설정하여 꾸준한 습관 형성을 돕습니다',
                    child: Icon(Icons.help_outline,
                        color: Colors.grey.shade600, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchTestCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WatchTestPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.watch, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apple Watch 연동 테스트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '워치 연결 상태 확인 및 운동 데이터 전송 테스트',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBugReportCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BugReportPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '버그 리포트 & 피드백',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '문제 신고, 기능 요청, 피드백 전송',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PointsPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '포인트 & 레벨업',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '포인트 획득 기록 및 업적 확인',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCleanupCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('데이터 정리'),
              content: const Text(
                '중복된 사용자 문서를 정리하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('정리'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('데이터 정리 중...'),
                backgroundColor: Colors.blue,
              ),
            );

            await UserCleanupService().cleanupDuplicateUsers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('데이터 정리 완료'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.cleaning_services,
                  color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '데이터 정리',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '중복된 사용자 문서 정리',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedNotificationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple.shade600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '고급 목표 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: '고급 목표 관리 기능들입니다',
                  child: Icon(Icons.help_outline,
                      color: Colors.grey.shade600, size: 20),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade600, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 제안된 습관을 실제 습관으로 추가
  Future<void> _addSuggestedHabit(HabitSuggestion suggestion) async {
    if (_currentUser == null ||
        _isAddingHabit ||
        _addingHabits.contains(suggestion.title)) return;

    // 중복 추가 방지 (이중 체크)
    setState(() {
      _isAddingHabit = true;
      _addingHabits.add(suggestion.title);
    });

    try {
      // 습관 추가 (HabitService의 addHabit 메서드 사용)
      final habitId = await _habitService.addHabit(
        title: suggestion.title,
        description: suggestion.description,
        emoji: suggestion.emoji,
      );

      if (habitId == null) {
        throw Exception('습관 추가에 실패했습니다.');
      }

      // 성공 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${suggestion.emoji} ${suggestion.title} 습관이 추가되었습니다!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '습관 보기',
              textColor: Colors.white,
              onPressed: () {
                // 안전한 네비게이션을 위해 전역 네비게이터 사용
                _navigateToHabitsSafely();
              },
            ),
          ),
        );
      }

      // 습관 제안 목록에서 제거 (중복 추가 방지)
      if (mounted) {
        setState(() {
          _habitSuggestions.removeWhere((s) => s.title == suggestion.title);
        });
      }

      // Today 페이지 캐시 무효화 (습관 개수 업데이트를 위해)
      _invalidateTodayCache();
    } catch (e) {
      // 에러 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('습관 추가 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('❌ 제안된 습관 추가 실패: $e');
    } finally {
      // 작업 완료 후 플래그 리셋
      if (mounted) {
        setState(() {
          _isAddingHabit = false;
          _addingHabits.remove(suggestion.title);
        });
      }
    }
  }

  /// Today 페이지 캐시 무효화 (습관 개수 업데이트를 위해)
  void _invalidateTodayCache() {
    try {
      // 캐시 서비스에서 Today 요약 캐시 제거
      CacheService.removeCache(CacheKeys.todaySummary);

      // Riverpod provider 무효화
      ref.invalidate(todaySummaryProvider);

      print('✅ Today 캐시 무효화 완료');
    } catch (e) {
      print('❌ Today 캐시 무효화 실패: $e');
    }
  }

  /// 안전한 습관 페이지 네비게이션
  Widget _buildRunningCoachCard() {
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
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RunningCoachPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '러닝 개인 코치',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI 기반 맞춤형 훈련 계획',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildCoachFeature(Icons.event, '이벤트 목표'),
                    const SizedBox(width: 20),
                    _buildCoachFeature(Icons.schedule, '체계적 계획'),
                    const SizedBox(width: 20),
                    _buildCoachFeature(Icons.analytics, '진도 분석'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '기초체력, 존2, LSD, VO2 Max 등 체계적인 훈련 프로그램',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RankingPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.leaderboard,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '랭킹 & 친구',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '친구들과 함께 경쟁하세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRankingFeature(Icons.emoji_events, '주간/월간'),
                    const SizedBox(width: 20),
                    _buildRankingFeature(Icons.people, '친구 랭킹'),
                    const SizedBox(width: 20),
                    _buildRankingFeature(Icons.group, '클럽 기능'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '포인트, 습관 완성률, 러닝 거리 등 다양한 카테고리별 랭킹',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToHabitsSafely() {
    try {
      // 먼저 스낵바 닫기 (현재 context가 유효한 동안)
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // 전역 라우터를 사용하여 안전하게 네비게이션
      // 약간의 지연을 두어 스낵바가 완전히 닫힌 후 네비게이션
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          // AppRouter의 전역 라우터 인스턴스 사용
          AppRouter.router.go('/today?action=habits');
          print('✅ 습관 페이지로 안전하게 네비게이션 완료');
        } catch (routerError) {
          print('❌ 전역 라우터 네비게이션 실패: $routerError');
          // 최후의 fallback: 단순히 Today 페이지로 이동
          try {
            AppRouter.router.go('/today');
          } catch (finalError) {
            print('❌ 최종 Fallback도 실패: $finalError');
          }
        }
      });
    } catch (e) {
      print('❌ 습관 페이지 네비게이션 초기화 실패: $e');
    }
  }
}
