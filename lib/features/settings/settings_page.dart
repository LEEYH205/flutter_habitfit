import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/services/local_notification_service.dart';
import '../../services/analytics_service.dart';
import '../../services/recommendation_service.dart';
import 'user_profile_page.dart';
import 'goal_settings_page.dart';
import 'notification_settings_page.dart';
import 'advanced_goal_settings_page.dart';

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
    } catch (e) {
      print('❌ 스마트 추천 로드 실패: $e');
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
        appBar: AppBar(
          title: const Text('설정'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
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
              return Container(
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
                  ],
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
}
