import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';

class RunningNotificationsPage extends ConsumerStatefulWidget {
  const RunningNotificationsPage({super.key});

  @override
  ConsumerState<RunningNotificationsPage> createState() =>
      _RunningNotificationsPageState();
}

class _RunningNotificationsPageState
    extends ConsumerState<RunningNotificationsPage> {
  // 알림 설정 상태
  bool _trainingReminders = true;
  bool _goalAchievements = true;
  bool _weeklyReports = false;
  bool _eventReminders = true;
  bool _weatherAlerts = false;

  // 알림 시간 설정
  TimeOfDay _morningReminder = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _eveningReminder = const TimeOfDay(hour: 19, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(title: '러닝 알림 설정'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 알림 설정
            _buildSectionCard(
              title: '기본 알림',
              children: [
                _buildSwitchTile(
                  title: '훈련 알림',
                  subtitle: '일일 훈련 계획 알림',
                  value: _trainingReminders,
                  onChanged: (value) {
                    setState(() {
                      _trainingReminders = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: '목표 달성 알림',
                  subtitle: '목표 달성 시 축하 메시지',
                  value: _goalAchievements,
                  onChanged: (value) {
                    setState(() {
                      _goalAchievements = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: '주간 리포트',
                  subtitle: '주간 성과 요약 알림',
                  value: _weeklyReports,
                  onChanged: (value) {
                    setState(() {
                      _weeklyReports = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 이벤트 알림 설정
            _buildSectionCard(
              title: '이벤트 알림',
              children: [
                _buildSwitchTile(
                  title: '대회 알림',
                  subtitle: '등록한 대회 관련 알림',
                  value: _eventReminders,
                  onChanged: (value) {
                    setState(() {
                      _eventReminders = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: '날씨 알림',
                  subtitle: '악천후 시 러닝 주의 알림',
                  value: _weatherAlerts,
                  onChanged: (value) {
                    setState(() {
                      _weatherAlerts = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 알림 시간 설정
            _buildSectionCard(
              title: '알림 시간',
              children: [
                _buildTimeTile(
                  title: '오전 알림',
                  subtitle: '훈련 계획 및 동기부여 메시지',
                  time: _morningReminder,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _morningReminder,
                    );
                    if (picked != null) {
                      setState(() {
                        _morningReminder = picked;
                      });
                    }
                  },
                ),
                _buildTimeTile(
                  title: '저녁 알림',
                  subtitle: '일일 성과 및 내일 계획 알림',
                  time: _eveningReminder,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _eveningReminder,
                    );
                    if (picked != null) {
                      setState(() {
                        _eveningReminder = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 알림 테스트
            _buildSectionCard(
              title: '알림 테스트',
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('알림 테스트'),
                  subtitle: const Text('현재 설정으로 테스트 알림 전송'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showTestNotification();
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '설정 저장',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('테스트 알림이 전송되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveSettings() {
    // TODO: 설정을 Firebase에 저장
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('알림 설정이 저장되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
