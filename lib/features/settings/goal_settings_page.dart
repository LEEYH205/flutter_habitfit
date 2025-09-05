import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../providers/user_goals_provider.dart';

/// 목표 설정 페이지
class GoalSettingsPage extends ConsumerStatefulWidget {
  const GoalSettingsPage({super.key});

  @override
  ConsumerState<GoalSettingsPage> createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends ConsumerState<GoalSettingsPage> {
  final TextEditingController _activeCaloriesController =
      TextEditingController();
  final TextEditingController _exerciseMinutesController =
      TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  // 운동 목표 변수들
  int _dailySquatGoal = 20;
  int _dailyPushupGoal = 15;
  int _dailyHabitGoal = 1;
  double _dailyRunningGoal = 5.0;

  @override
  void initState() {
    super.initState();
    // 초기 로드 시 기본값 설정
    _activeCaloriesController.text = '400';
    _exerciseMinutesController.text = '30';
    _stepsController.text = '10000';
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailySquatGoal = prefs.getInt('dailySquatGoal') ?? 20;
      _dailyPushupGoal = prefs.getInt('dailyPushupGoal') ?? 15;
      _dailyHabitGoal = prefs.getInt('dailyHabitGoal') ?? 1;
      _dailyRunningGoal = prefs.getDouble('dailyRunningGoal') ?? 5.0;
    });
  }

  @override
  void dispose() {
    _activeCaloriesController.dispose();
    _exerciseMinutesController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userGoalsAsync = ref.watch(userGoalsProvider);

    return Scaffold(
      appBar: const AppBarWithNotifications(title: '목표 설정'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: userGoalsAsync.when(
          data: (goals) {
            // 데이터가 로드되면 컨트롤러에 값 설정
            if (_activeCaloriesController.text == '400') {
              _activeCaloriesController.text =
                  goals.activeCaloriesGoal.toInt().toString();
            }
            if (_exerciseMinutesController.text == '30') {
              _exerciseMinutesController.text =
                  goals.exerciseMinutesGoal.toString();
            }
            if (_stepsController.text == '10000') {
              _stepsController.text = goals.stepsGoal.toString();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '일일 목표 설정',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '매일 달성하고 싶은 목표를 설정하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // 움직이기 칼로리 목표
                _buildGoalTile(
                  '움직이기 칼로리',
                  '일일 칼로리 소모 목표',
                  goals.activeCaloriesGoal.toDouble(),
                  Icons.local_fire_department,
                  Colors.red,
                  (value) {
                    _activeCaloriesController.text = value.toInt().toString();
                  },
                  isDouble: true,
                ),

                const SizedBox(height: 16),

                // 운동 시간 목표
                _buildGoalTile(
                  '운동 시간',
                  '일일 운동 시간 목표',
                  goals.exerciseMinutesGoal.toDouble(),
                  Icons.timer,
                  Colors.blue,
                  (value) {
                    _exerciseMinutesController.text = value.toInt().toString();
                  },
                  isDouble: true,
                ),

                const SizedBox(height: 16),

                // 걸음 수 목표
                _buildGoalTile(
                  '걸음 수',
                  '일일 걸음 수 목표',
                  goals.stepsGoal.toDouble(),
                  Icons.directions_walk,
                  Colors.green,
                  (value) {
                    _stepsController.text = value.toInt().toString();
                  },
                  isDouble: true,
                ),

                const SizedBox(height: 32),
// 운동 목표들
                _buildGoalTile(
                  '스쿼트 목표',
                  '일일 스쿼트 횟수 목표',
                  _dailySquatGoal,
                  Icons.fitness_center,
                  Colors.red,
                  (value) {
                    setState(() => _dailySquatGoal = value);
                    _saveGoals();
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
                    _saveGoals();
                  },
                ),

                const SizedBox(height: 16),

                // 습관 목표
                _buildGoalTile(
                  '습관 목표',
                  '일일 습관 완료 목표',
                  _dailyHabitGoal,
                  Icons.check_circle,
                  Colors.green,
                  (value) {
                    setState(() => _dailyHabitGoal = value);
                    _saveGoals();
                  },
                ),

                const SizedBox(height: 16),

                // 러닝 목표
                _buildGoalTile(
                  '러닝 목표',
                  '일일 러닝 거리 목표 (km)',
                  _dailyRunningGoal,
                  Icons.directions_run,
                  Colors.orange,
                  (value) {
                    setState(() => _dailyRunningGoal = value);
                    _saveGoals();
                  },
                  isDouble: true,
                ),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveGoals,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      '목표 저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 기본값 복원 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _resetToDefaults,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('기본값으로 복원'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '목표를 불러올 수 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userGoalsProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveGoals() async {
    final activeCalories =
        double.tryParse(_activeCaloriesController.text) ?? 400.0;
    final exerciseMinutes = int.tryParse(_exerciseMinutesController.text) ?? 30;
    final steps = int.tryParse(_stepsController.text) ?? 10000;

    // 입력값 검증
    if (activeCalories <= 0 || exerciseMinutes <= 0 || steps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('목표 값은 0보다 커야 합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 운동 목표 변수들 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dailySquatGoal', _dailySquatGoal);
      await prefs.setInt('dailyPushupGoal', _dailyPushupGoal);
      await prefs.setInt('dailyHabitGoal', _dailyHabitGoal);
      await prefs.setDouble('dailyRunningGoal', _dailyRunningGoal);

      await updateUserGoal(
        activeCaloriesGoal: activeCalories,
        exerciseMinutesGoal: exerciseMinutes,
        stepsGoal: steps,
      );

      // Provider 새로고침
      ref.invalidate(userGoalsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('목표가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // 이전 화면으로 돌아가기
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetToDefaults() {
    _activeCaloriesController.text = '400';
    _exerciseMinutesController.text = '30';
    _stepsController.text = '10000';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('기본값으로 설정되었습니다. 저장 버튼을 눌러주세요.'),
      ),
    );
  }

  Widget _buildGoalTile(String title, String subtitle, dynamic value,
      IconData icon, Color color, Function(dynamic) onChanged,
      {bool isDouble = false}) {
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
}
