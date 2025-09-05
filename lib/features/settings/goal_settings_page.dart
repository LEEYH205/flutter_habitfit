import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../widgets/common/section_card.dart';
import '../../models/user_goals.dart';
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

  @override
  void initState() {
    super.initState();
    // 초기 로드 시 기본값 설정
    _activeCaloriesController.text = '400';
    _exerciseMinutesController.text = '30';
    _stepsController.text = '10000';
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
                SectionCard(
                  title: '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '움직이기 칼로리',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _activeCaloriesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '400',
                                suffixText: 'kcal',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재: ${goals.activeCaloriesGoal.toInt()}kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 운동 시간 목표
                SectionCard(
                  title: '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '운동 시간',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _exerciseMinutesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '30',
                                suffixText: '분',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재: ${goals.exerciseMinutesGoal}분',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 걸음 수 목표
                SectionCard(
                  title: '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '걸음 수',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _stepsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '10000',
                                suffixText: '걸음',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재: ${goals.stepsGoal}걸음',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

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
}
