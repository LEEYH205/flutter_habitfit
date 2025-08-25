import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/services/local_notification_service.dart';
import '../../common/services/fcm_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SharedPreferences _prefs;

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
  int _dailyHabitGoal = 1;

  @override
  void initState() {
    super.initState();
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
      _dailyHabitGoal = _prefs.getInt('dailyHabitGoal') ?? 1;
    });
  }

  Future<void> _saveSettings() async {
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
    await _prefs.setInt('dailyHabitGoal', _dailyHabitGoal);

    // 설정 저장 후 알림 스케줄 업데이트
    await _updateNotificationSchedules();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 설정이 저장되었습니다!'),
          backgroundColor: Colors.green,
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
        title: const Text('⚙️ 설정'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: '설정 저장',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 설정 섹션
            _buildSectionHeader('🔔 알림 설정'),
            _buildSwitchTile(
              '운동 완료 알림',
              '스쿼트 세션 완료 시 알림',
              _workoutNotificationsEnabled,
              (value) => setState(() => _workoutNotificationsEnabled = value),
            ),
            _buildSwitchTile(
              '습관 체크 리마인더',
              '매일 설정된 시간에 습관 체크 알림',
              _habitRemindersEnabled,
              (value) => setState(() => _habitRemindersEnabled = value),
            ),
            _buildSwitchTile(
              '일일 운동 요약',
              '매일 설정된 시간에 운동 요약 알림',
              _dailySummaryEnabled,
              (value) => setState(() => _dailySummaryEnabled = value),
            ),
            _buildSwitchTile(
              '목표 달성 축하',
              '목표 달성 시 축하 알림',
              _goalAchievementEnabled,
              (value) => setState(() => _goalAchievementEnabled = value),
            ),
            _buildSwitchTile(
              '주간 운동 요약',
              '매주 일요일에 주간 요약 알림',
              _weeklySummaryEnabled,
              (value) => setState(() => _weeklySummaryEnabled = value),
            ),

            const SizedBox(height: 24),

            // 시간 설정 섹션
            _buildSectionHeader('⏰ 시간 설정'),
            _buildTimeTile(
              '습관 체크 리마인더',
              _habitRemindersEnabled ? _habitReminderTime : null,
              (time) => setState(() => _habitReminderTime = time),
              enabled: _habitRemindersEnabled,
            ),
            _buildTimeTile(
              '일일 운동 요약',
              _dailySummaryEnabled ? _dailySummaryTime : null,
              (time) => setState(() => _dailySummaryTime = time),
              enabled: _dailySummaryEnabled,
            ),
            _buildTimeTile(
              '주간 운동 요약',
              _weeklySummaryEnabled ? _weeklySummaryTime : null,
              (time) => setState(() => _weeklySummaryTime = time),
              enabled: _weeklySummaryEnabled,
            ),

            const SizedBox(height: 24),

            // 목표 설정 섹션
            _buildSectionHeader('🎯 목표 설정'),
            _buildNumberTile(
              '일일 스쿼트 목표',
              '하루에 목표로 하는 스쿼트 횟수',
              _dailySquatGoal,
              (value) => setState(() => _dailySquatGoal = value),
              min: 1,
              max: 100,
            ),
            _buildNumberTile(
              '일일 습관 목표',
              '하루에 목표로 하는 습관 체크 횟수',
              _dailyHabitGoal,
              (value) => setState(() => _dailyHabitGoal = value),
              min: 1,
              max: 10,
            ),

            const SizedBox(height: 32),

            // 테스트 버튼
            _buildSectionHeader('🧪 알림 테스트'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '로컬 알림 기능들을 테스트해보세요.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FcmService.instance.showTestNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🧪 로컬 테스트 알림을 보냈습니다!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('로컬 알림\n테스트'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await LocalNotificationService.instance
                                .showDailyWorkoutSummary(25, 120);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📊 일일 요약 알림을 보냈습니다!'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('일일 요약\n알림'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await LocalNotificationService.instance
                                .showGoalAchievementNotification('스쿼트', 20);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎯 목표 달성 알림을 보냈습니다!'),
                                  backgroundColor: Colors.purple,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.emoji_events),
                          label: const Text('목표 달성\n알림'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await LocalNotificationService.instance
                                .scheduleHabitReminder(
                                    const TimeOfDay(hour: 20, minute: 0));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📝 오후 8시 습관 체크 리마인더를 설정했습니다!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: const Text('습관\n리마인더'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '로컬 알림은 FCM 없이도 완벽하게 작동합니다!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 기존 테스트 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await LocalNotificationService.instance
                          .showTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🧪 테스트 알림을 보냈습니다!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('테스트 알림'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _updateNotificationSchedules,
                    icon: const Icon(Icons.refresh),
                    label: const Text('알림 스케줄 새로고침'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
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
}
