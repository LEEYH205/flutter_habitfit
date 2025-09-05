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

  // 목표 설정
  int _dailySquatGoal = 20;
  int _dailyPushupGoal = 15;
  int _dailyHabitGoal = 1;
  double _dailyRunningGoal = 5.0; // km 단위

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

  // 프리셋 관련

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

      _dailySquatGoal = _prefs.getInt('dailySquatGoal') ?? 20;
      _dailyPushupGoal = _prefs.getInt('dailyPushupGoal') ?? 15;
      _dailyHabitGoal = _prefs.getInt('dailyHabitGoal') ?? 1;
      _dailyRunningGoal = _prefs.getDouble('dailyRunningGoal') ?? 5.0;
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

    await _prefs.setInt('dailySquatGoal', _dailySquatGoal);
    await _prefs.setInt('dailyPushupGoal', _dailyPushupGoal);
    await _prefs.setInt('dailyHabitGoal', _dailyHabitGoal);
    await _prefs.setDouble('dailyRunningGoal', _dailyRunningGoal);

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

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime,
      Function(TimeOfDay) onTimeChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      onTimeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('👤 사용자 & 설정'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
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
                _buildNotificationSettingsCard(),

                const SizedBox(height: 24),

                // 시간 설정 섹션
                _buildTimeSettingsCard(),

                const SizedBox(height: 24),

                // 목표 설정 섹션
                _buildGoalSettingsCard(),

                const SizedBox(height: 24),

                // 고급 설정 섹션
                _buildAdvancedNotificationCard(),

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

  Widget _buildTimeTile(
      String title, TimeOfDay? time, Function(TimeOfDay) onTimeChanged,
      {required bool enabled}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : '설정되지 않음'),
      trailing: IconButton(
        icon: const Icon(Icons.access_time),
        onPressed: enabled
            ? () => _selectTime(context,
                time ?? const TimeOfDay(hour: 12, minute: 0), onTimeChanged)
            : null,
      ),
      enabled: enabled,
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

  Widget _buildProgressiveIncreaseTile() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '점진적 증가 설정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '주간 증가율: ${(_progressiveIncreaseRate * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _progressiveIncreaseRate,
                    min: 0.01, // 1%
                    max: 0.20, // 20%
                    divisions: 19,
                    label: '${(_progressiveIncreaseRate * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _progressiveIncreaseRate = value);
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '매주 월요일에 목표가 ${(_progressiveIncreaseRate * 100).toInt()}%씩 증가합니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeloadSettingsTile() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '딜로드 설정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '연속 실패 $_consecutiveFailuresForDeload회 시',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _consecutiveFailuresForDeload > 1
                            ? () {
                                setState(() => _consecutiveFailuresForDeload--);
                                _saveSettings();
                              }
                            : null,
                        color: _consecutiveFailuresForDeload > 1
                            ? Colors.red
                            : Colors.grey,
                      ),
                      Text(
                        '$_consecutiveFailuresForDeload',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _consecutiveFailuresForDeload < 5
                            ? () {
                                setState(() => _consecutiveFailuresForDeload++);
                                _saveSettings();
                              }
                            : null,
                        color: _consecutiveFailuresForDeload < 5
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '목표 감소율: ${(_deloadRate * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _deloadRate,
                    min: 0.05, // 5%
                    max: 0.30, // 30%
                    divisions: 25,
                    label: '${(_deloadRate * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _deloadRate = value);
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '연속 실패 시 목표가 ${(_deloadRate * 100).toInt()}% 감소하여 부담을 줄입니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyResetTile() {
    const dayNames = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주간 리셋 설정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '리셋 요일: ${dayNames[_weeklyResetDay]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                return FilterChip(
                  label: Text(dayNames[index]),
                  selected: _weeklyResetDay == index,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _weeklyResetDay = index);
                      _saveSettings();
                    }
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.withOpacity(0.7),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '매주 ${dayNames[_weeklyResetDay]}에 목표가 초기값으로 리셋됩니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NotificationSettingsPage(),
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
                  Icon(Icons.notifications,
                      color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    '알림 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.grey.shade600, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '알림 종류와 시간을 설정하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
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
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.grey.shade600, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '움직이기 칼로리, 운동 시간, 걸음 수 목표를 설정하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdvancedGoalSettingsPage(),
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
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.grey.shade600, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '운동 목표와 고급 설정을 관리하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSettingsCard() {
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
                Icon(Icons.access_time,
                    color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '시간 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: '알림 시간과 요일별 반복 설정을 관리하세요',
                  child: Icon(Icons.help_outline,
                      color: Colors.grey.shade600, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeTile(
              '습관 체크 리마인더',
              _habitReminderTime,
              (time) {
                setState(() => _habitReminderTime = time);
                _saveSettings();
              },
              enabled: _habitRemindersEnabled,
            ),
            _buildTimeTile(
              '일일 운동 요약',
              _dailySummaryTime,
              (time) {
                setState(() => _dailySummaryTime = time);
                _saveSettings();
              },
              enabled: _dailySummaryEnabled,
            ),
            _buildTimeTile(
              '주간 운동 요약',
              _weeklySummaryTime,
              (time) {
                setState(() => _weeklySummaryTime = time);
                _saveSettings();
              },
              enabled: _weeklySummaryEnabled,
            ),
          ],
        ),
      ),
    );
  }
}
