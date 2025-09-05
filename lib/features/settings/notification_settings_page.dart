import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 설정 페이지
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  late SharedPreferences _prefs;

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
  bool _focusModeRespectEnabled = true;

  // 시간 설정
  TimeOfDay _habitReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _weeklySummaryTime = const TimeOfDay(hour: 20, minute: 0);

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

      _missedHabitReminderEnabled =
          _prefs.getBool('missedHabitReminderEnabled') ?? true;
      _missedHabitReminderCount =
          _prefs.getInt('missedHabitReminderCount') ?? 2;
      _snoozeEnabled = _prefs.getBool('snoozeEnabled') ?? true;
      _snoozeDuration = _prefs.getInt('snoozeDuration') ?? 15;
      _quietHoursEnabled = _prefs.getBool('quietHoursEnabled') ?? true;
      _focusModeRespectEnabled =
          _prefs.getBool('focusModeRespectEnabled') ?? true;

      _habitReminderTime = TimeOfDay(
        hour: _prefs.getInt('habitReminderHour') ?? 20,
        minute: _prefs.getInt('habitReminderMinute') ?? 0,
      );
      _dailySummaryTime = TimeOfDay(
        hour: _prefs.getInt('dailySummaryHour') ?? 21,
        minute: _prefs.getInt('dailySummaryMinute') ?? 0,
      );
      _weeklySummaryTime = TimeOfDay(
        hour: _prefs.getInt('weeklySummaryHour') ?? 20,
        minute: _prefs.getInt('weeklySummaryMinute') ?? 0,
      );
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool(
        'workoutNotificationsEnabled', _workoutNotificationsEnabled);
    await _prefs.setBool('habitRemindersEnabled', _habitRemindersEnabled);
    await _prefs.setBool('dailySummaryEnabled', _dailySummaryEnabled);
    await _prefs.setBool('goalAchievementEnabled', _goalAchievementEnabled);
    await _prefs.setBool('weeklySummaryEnabled', _weeklySummaryEnabled);

    await _prefs.setBool(
        'missedHabitReminderEnabled', _missedHabitReminderEnabled);
    await _prefs.setInt('missedHabitReminderCount', _missedHabitReminderCount);
    await _prefs.setBool('snoozeEnabled', _snoozeEnabled);
    await _prefs.setInt('snoozeDuration', _snoozeDuration);
    await _prefs.setBool('quietHoursEnabled', _quietHoursEnabled);
    await _prefs.setBool('focusModeRespectEnabled', _focusModeRespectEnabled);

    await _prefs.setInt('habitReminderHour', _habitReminderTime.hour);
    await _prefs.setInt('habitReminderMinute', _habitReminderTime.minute);
    await _prefs.setInt('dailySummaryHour', _dailySummaryTime.hour);
    await _prefs.setInt('dailySummaryMinute', _dailySummaryTime.minute);
    await _prefs.setInt('weeklySummaryHour', _weeklySummaryTime.hour);
    await _prefs.setInt('weeklySummaryMinute', _weeklySummaryTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _saveSettings(),
            child: const Text(
              '저장',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 알림 설정
            _buildSectionCard(
              title: '기본 알림',
              icon: Icons.notifications,
              color: Colors.blue,
              children: [
                _buildSwitchTile(
                  '운동 알림',
                  '운동 관련 알림을 받습니다',
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
              ],
            ),

            const SizedBox(height: 20),

            // 고급 알림 설정
            _buildSectionCard(
              title: '고급 알림',
              icon: Icons.settings,
              color: Colors.purple,
              children: [
                _buildSwitchTile(
                  '놓친 습관 리마인더',
                  '습관을 놓쳤을 때 추가 알림',
                  _missedHabitReminderEnabled,
                  (value) {
                    setState(() => _missedHabitReminderEnabled = value);
                    _saveSettings();
                  },
                ),
                _buildSwitchTile(
                  '스누즈 기능',
                  '알림을 잠시 연기할 수 있습니다',
                  _snoozeEnabled,
                  (value) {
                    setState(() => _snoozeEnabled = value);
                    _saveSettings();
                  },
                ),
                _buildSwitchTile(
                  '방해 금지 시간',
                  '설정된 시간에는 알림을 받지 않습니다',
                  _quietHoursEnabled,
                  (value) {
                    setState(() => _quietHoursEnabled = value);
                    _saveSettings();
                  },
                ),
                _buildSwitchTile(
                  '집중 모드 존중',
                  '집중 모드가 활성화된 동안 알림을 받지 않습니다',
                  _focusModeRespectEnabled,
                  (value) {
                    setState(() => _focusModeRespectEnabled = value);
                    _saveSettings();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 시간 설정
            _buildSectionCard(
              title: '알림 시간',
              icon: Icons.access_time,
              color: Colors.orange,
              children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
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
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.blue,
    );
  }

  Widget _buildTimeTile(
    String title,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged, {
    bool enabled = true,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: Text(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 14,
          color: enabled ? Colors.grey.shade600 : Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.access_time,
        color: enabled ? Colors.blue : Colors.grey,
      ),
      enabled: enabled,
      onTap: enabled
          ? () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null && picked != time) {
                onChanged(picked);
              }
            }
          : null,
    );
  }
}
