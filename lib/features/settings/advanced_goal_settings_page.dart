import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 고급 목표 설정 페이지
class AdvancedGoalSettingsPage extends ConsumerStatefulWidget {
  const AdvancedGoalSettingsPage({super.key});

  @override
  ConsumerState<AdvancedGoalSettingsPage> createState() =>
      _AdvancedGoalSettingsPageState();
}

class _AdvancedGoalSettingsPageState
    extends ConsumerState<AdvancedGoalSettingsPage> {
  late SharedPreferences _prefs;

  // 운동 목표들
  int _dailySquatGoal = 20;
  int _dailyPushupGoal = 15;
  int _dailyHabitGoal = 1;
  double _dailyRunningGoal = 5.0;

  // 고급 설정
  bool _progressiveIncreaseEnabled = true;
  double _progressiveIncreaseRate = 0.1; // 10% 증가
  bool _deloadSystemEnabled = true;
  int _consecutiveFailuresForDeload = 3;
  bool _restDaysEnabled = true;
  List<int> _restDays = [6, 7]; // 토, 일
  bool _weeklyResetEnabled = true;
  int _weeklyResetDay = 1; // 월요일

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailySquatGoal = _prefs.getInt('dailySquatGoal') ?? 20;
      _dailyPushupGoal = _prefs.getInt('dailyPushupGoal') ?? 15;
      _dailyHabitGoal = _prefs.getInt('dailyHabitGoal') ?? 1;
      _dailyRunningGoal = _prefs.getDouble('dailyRunningGoal') ?? 5.0;

      _progressiveIncreaseEnabled =
          _prefs.getBool('progressiveIncreaseEnabled') ?? true;
      _progressiveIncreaseRate =
          _prefs.getDouble('progressiveIncreaseRate') ?? 0.1;
      _deloadSystemEnabled = _prefs.getBool('deloadSystemEnabled') ?? true;
      _consecutiveFailuresForDeload =
          _prefs.getInt('consecutiveFailuresForDeload') ?? 3;
      _restDaysEnabled = _prefs.getBool('restDaysEnabled') ?? true;
      _weeklyResetEnabled = _prefs.getBool('weeklyResetEnabled') ?? true;
      _weeklyResetDay = _prefs.getInt('weeklyResetDay') ?? 1;

      final restDaysList = _prefs.getStringList('restDays') ?? ['6', '7'];
      _restDays = restDaysList.map((e) => int.parse(e)).toList();
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt('dailySquatGoal', _dailySquatGoal);
    await _prefs.setInt('dailyPushupGoal', _dailyPushupGoal);
    await _prefs.setInt('dailyHabitGoal', _dailyHabitGoal);
    await _prefs.setDouble('dailyRunningGoal', _dailyRunningGoal);

    await _prefs.setBool(
        'progressiveIncreaseEnabled', _progressiveIncreaseEnabled);
    await _prefs.setDouble('progressiveIncreaseRate', _progressiveIncreaseRate);
    await _prefs.setBool('deloadSystemEnabled', _deloadSystemEnabled);
    await _prefs.setInt(
        'consecutiveFailuresForDeload', _consecutiveFailuresForDeload);
    await _prefs.setBool('restDaysEnabled', _restDaysEnabled);
    await _prefs.setStringList(
        'restDays', _restDays.map((e) => e.toString()).toList());
    await _prefs.setBool('weeklyResetEnabled', _weeklyResetEnabled);
    await _prefs.setInt('weeklyResetDay', _weeklyResetDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('고급 목표 설정'),
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
            // 운동 목표 설정
            _buildSectionCard(
              title: '운동 목표',
              icon: Icons.fitness_center,
              color: Colors.red,
              children: [
                _buildGoalTile(
                  '스쿼트 목표',
                  '일일 스쿼트 횟수 목표',
                  _dailySquatGoal,
                  Icons.fitness_center,
                  Colors.red,
                  (value) {
                    setState(() => _dailySquatGoal = value);
                    _saveSettings();
                  },
                ),
                _buildGoalTile(
                  '푸시업 목표',
                  '일일 푸시업 횟수 목표',
                  _dailyPushupGoal,
                  Icons.accessibility,
                  Colors.blue,
                  (value) {
                    setState(() => _dailyPushupGoal = value);
                    _saveSettings();
                  },
                ),
                _buildGoalTile(
                  '습관 목표',
                  '일일 습관 완료 목표',
                  _dailyHabitGoal,
                  Icons.check_circle,
                  Colors.green,
                  (value) {
                    setState(() => _dailyHabitGoal = value);
                    _saveSettings();
                  },
                ),
                _buildGoalTile(
                  '러닝 목표',
                  '일일 러닝 거리 목표 (km)',
                  _dailyRunningGoal,
                  Icons.directions_run,
                  Colors.orange,
                  (value) {
                    setState(() => _dailyRunningGoal = value);
                    _saveSettings();
                  },
                  isDouble: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 고급 설정
            _buildSectionCard(
              title: '고급 설정',
              icon: Icons.settings,
              color: Colors.purple,
              children: [
                _buildSwitchTile(
                  '점진적 증가',
                  '목표를 점진적으로 증가시킵니다',
                  _progressiveIncreaseEnabled,
                  (value) {
                    setState(() => _progressiveIncreaseEnabled = value);
                    _saveSettings();
                  },
                ),
                if (_progressiveIncreaseEnabled) ...[
                  _buildProgressiveIncreaseTile(),
                ],
                _buildSwitchTile(
                  '딜로드 시스템',
                  '연속 실패 시 목표를 낮춥니다',
                  _deloadSystemEnabled,
                  (value) {
                    setState(() => _deloadSystemEnabled = value);
                    _saveSettings();
                  },
                ),
                if (_deloadSystemEnabled) ...[
                  _buildDeloadSettingsTile(),
                ],
                _buildSwitchTile(
                  '휴식일 설정',
                  '특정 요일에 휴식을 취합니다',
                  _restDaysEnabled,
                  (value) {
                    setState(() => _restDaysEnabled = value);
                    _saveSettings();
                  },
                ),
                if (_restDaysEnabled) ...[
                  _buildDaySelectorTile(
                    '휴식일',
                    _restDays,
                    (days) {
                      setState(() => _restDays = days);
                      _saveSettings();
                    },
                  ),
                ],
                _buildSwitchTile(
                  '주간 리셋',
                  '매주 목표를 초기화합니다',
                  _weeklyResetEnabled,
                  (value) {
                    setState(() => _weeklyResetEnabled = value);
                    _saveSettings();
                  },
                ),
                if (_weeklyResetEnabled) ...[
                  _buildWeeklyResetTile(),
                ],
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

  Widget _buildGoalTile(
    String title,
    String subtitle,
    dynamic value,
    IconData icon,
    Color color,
    Function(dynamic) onChanged, {
    bool isDouble = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.7),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: color, size: 16),
                onPressed: () {
                  final newValue =
                      isDouble ? (value as double) - 0.5 : (value as int) - 1;
                  if ((isDouble && newValue >= 0) ||
                      (!isDouble && newValue >= 0)) {
                    onChanged(newValue);
                  }
                },
              ),
              SizedBox(
                width: 60,
                child: Text(
                  isDouble ? '${value.toStringAsFixed(1)}' : value.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: color, size: 16),
                onPressed: () {
                  final newValue =
                      isDouble ? (value as double) + 0.5 : (value as int) + 1;
                  onChanged(newValue);
                },
              ),
            ],
          ),
        ],
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

  Widget _buildProgressiveIncreaseTile() {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '증가율: ${(_progressiveIncreaseRate * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: _progressiveIncreaseRate,
            min: 0.05,
            max: 0.3,
            divisions: 5,
            onChanged: (value) {
              setState(() => _progressiveIncreaseRate = value);
              _saveSettings();
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDeloadSettingsTile() {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '연속 실패 횟수: $_consecutiveFailuresForDeload회',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
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
              IconButton(
                icon: const Icon(Icons.add, size: 16),
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
        ],
      ),
    );
  }

  Widget _buildDaySelectorTile(
    String title,
    List<int> selectedDays,
    ValueChanged<List<int>> onChanged,
  ) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final isSelected = selectedDays.contains(index + 1);
              return FilterChip(
                label: Text(days[index]),
                selected: isSelected,
                onSelected: (selected) {
                  final newDays = List<int>.from(selectedDays);
                  if (selected) {
                    newDays.add(index + 1);
                  } else {
                    newDays.remove(index + 1);
                  }
                  onChanged(newDays);
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.withOpacity(0.7),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyResetTile() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '리셋 요일: ${days[_weeklyResetDay - 1]}요일',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final isSelected = _weeklyResetDay == index + 1;
              return FilterChip(
                label: Text(days[index]),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _weeklyResetDay = index + 1);
                    _saveSettings();
                  }
                },
                selectedColor: Colors.purple.shade100,
                checkmarkColor: Colors.purple.withOpacity(0.7),
              );
            }),
          ),
        ],
      ),
    );
  }
}
