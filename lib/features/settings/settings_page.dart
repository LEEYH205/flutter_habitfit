import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/services/local_notification_service.dart';
import 'user_profile_page.dart';

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

  // 시간 설정
  TimeOfDay _habitReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _weeklySummaryTime = const TimeOfDay(hour: 20, minute: 0);

  // 목표 설정
  int _dailySquatGoal = 20;
  int _dailyPushupGoal = 15;
  int _dailyHabitGoal = 1;
  double _dailyRunningGoal = 5.0; // km 단위

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadSettings();
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

  Future<void> _saveSettings({bool showSnackBar = false}) async {
    await _prefs.setBool(
        'workoutNotificationsEnabled', _workoutNotificationsEnabled);
    await _prefs.setBool('habitRemindersEnabled', _habitRemindersEnabled);
    await _prefs.setBool('dailySummaryEnabled', _dailySummaryEnabled);
    await _prefs.setBool('goalAchievementEnabled', _goalAchievementEnabled);
    await _prefs.setBool('weeklySummaryEnabled', _weeklySummaryEnabled);

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 사용자 정보 섹션
            _buildUserInfoSection(),

            const SizedBox(height: 24),

            // 알림 설정 섹션
            _buildSectionHeader('🔔 알림 설정'),
            _buildSwitchTile(
              '운동 완료 알림',
              '스쿼트 세션 완료 시 알림',
              _workoutNotificationsEnabled,
              (value) {
                setState(() => _workoutNotificationsEnabled = value);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              '습관 체크 리마인더',
              '매일 설정된 시간에 습관 체크 알림',
              _habitRemindersEnabled,
              (value) {
                setState(() => _habitRemindersEnabled = value);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              '일일 운동 요약',
              '매일 설정된 시간에 운동 요약 알림',
              _dailySummaryEnabled,
              (value) {
                setState(() => _dailySummaryEnabled = value);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              '목표 달성 축하',
              '목표 달성 시 축하 알림',
              _goalAchievementEnabled,
              (value) {
                setState(() => _goalAchievementEnabled = value);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              '주간 운동 요약',
              '매주 일요일에 주간 요약 알림',
              _weeklySummaryEnabled,
              (value) {
                setState(() => _weeklySummaryEnabled = value);
                _saveSettings();
              },
            ),

            const SizedBox(height: 24),

            // 시간 설정 섹션
            _buildSectionHeader('⏰ 시간 설정'),
            _buildTimeTile(
              '습관 체크 리마인더',
              _habitRemindersEnabled ? _habitReminderTime : null,
              (time) {
                setState(() => _habitReminderTime = time);
                _saveSettings();
              },
              enabled: _habitRemindersEnabled,
            ),
            _buildTimeTile(
              '일일 운동 요약',
              _dailySummaryEnabled ? _dailySummaryTime : null,
              (time) {
                setState(() => _dailySummaryTime = time);
                _saveSettings();
              },
              enabled: _dailySummaryEnabled,
            ),
            _buildTimeTile(
              '주간 운동 요약',
              _weeklySummaryEnabled ? _weeklySummaryTime : null,
              (time) {
                setState(() => _weeklySummaryTime = time);
                _saveSettings();
              },
              enabled: _weeklySummaryEnabled,
            ),

            const SizedBox(height: 24),

            // 목표 설정 섹션
            _buildSectionHeader('🎯 목표 설정'),
            _buildNumberTile(
              '일일 스쿼트 목표',
              '하루에 목표로 하는 스쿼트 횟수',
              _dailySquatGoal,
              (value) {
                setState(() => _dailySquatGoal = value);
                _saveSettings();
              },
              min: 1,
              max: 100,
            ),
            _buildNumberTile(
              '일일 푸시업 목표',
              '하루에 목표로 하는 푸시업 횟수',
              _dailyPushupGoal,
              (value) {
                setState(() => _dailyPushupGoal = value);
                _saveSettings();
              },
              min: 1,
              max: 50,
            ),
            _buildNumberTile(
              '일일 습관 목표',
              '하루에 목표로 하는 습관 체크 횟수',
              _dailyHabitGoal,
              (value) {
                setState(() => _dailyHabitGoal = value);
                _saveSettings();
              },
              min: 1,
              max: 10,
            ),
            _buildRunningGoalTile(
              '일일 달리기 목표',
              '하루에 목표로 하는 달리기 거리',
              _dailyRunningGoal,
              (value) {
                setState(() => _dailyRunningGoal = value);
                _saveSettings();
              },
              min: 0.5,
              max: 50.0,
              step: 0.5,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        value ? Icons.notifications_active : Icons.notifications_off,
        color: value ? Colors.green : Colors.grey,
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

  Widget _buildNumberTile(
      String title, String subtitle, int value, Function(int) onChanged,
      {required int min, required int max}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            color: value > min ? Colors.red : Colors.grey,
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            color: value < max ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildRunningGoalTile(
      String title, String subtitle, double value, Function(double) onChanged,
      {required double min, required double max, required double step}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
            color: value > min ? Colors.red : Colors.grey,
          ),
          Text(
            '${value.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
            color: value < max ? Colors.green : Colors.grey,
          ),
        ],
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
                    color: Colors.green.shade700,
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
}
