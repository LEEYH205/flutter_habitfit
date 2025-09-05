import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_goals_provider.dart';
import '../../models/user_goals.dart';

/// 목표 설정 페이지
class GoalSettingsPage extends ConsumerStatefulWidget {
  const GoalSettingsPage({super.key});

  @override
  ConsumerState<GoalSettingsPage> createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends ConsumerState<GoalSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _activeCaloriesController;
  late TextEditingController _exerciseMinutesController;
  late TextEditingController _stepsController;

  @override
  void initState() {
    super.initState();
    _activeCaloriesController = TextEditingController();
    _exerciseMinutesController = TextEditingController();
    _stepsController = TextEditingController();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('목표 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _saveGoals(),
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
      body: userGoalsAsync.when(
        data: (goals) {
          // 컨트롤러 값 초기화
          _activeCaloriesController.text =
              goals.activeCaloriesGoal.toInt().toString();
          _exerciseMinutesController.text =
              goals.exerciseMinutesGoal.toString();
          _stepsController.text = goals.stepsGoal.toString();

          return _buildGoalSettingsForm(goals);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('목표를 불러올 수 없습니다: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userGoalsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSettingsForm(UserGoals goals) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 움직이기 칼로리 목표
            _buildGoalCard(
              title: '움직이기 칼로리',
              icon: Icons.local_fire_department,
              color: Colors.red,
              controller: _activeCaloriesController,
              unit: 'kcal',
              description: '하루에 소모할 활동 칼로리 목표를 설정하세요',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '목표를 입력해주세요';
                }
                final num = double.tryParse(value);
                if (num == null || num <= 0) {
                  return '올바른 숫자를 입력해주세요';
                }
                if (num > 2000) {
                  return '목표는 2000kcal 이하로 설정해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 운동 시간 목표
            _buildGoalCard(
              title: '운동 시간',
              icon: Icons.timer,
              color: Colors.blue,
              controller: _exerciseMinutesController,
              unit: '분',
              description: '하루에 운동할 시간 목표를 설정하세요',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '목표를 입력해주세요';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return '올바른 숫자를 입력해주세요';
                }
                if (num > 300) {
                  return '목표는 300분 이하로 설정해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 걸음 수 목표
            _buildGoalCard(
              title: '걸음 수',
              icon: Icons.directions_walk,
              color: Colors.orange,
              controller: _stepsController,
              unit: '걸음',
              description: '하루에 걸을 걸음 수 목표를 설정하세요',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '목표를 입력해주세요';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return '올바른 숫자를 입력해주세요';
                }
                if (num > 50000) {
                  return '목표는 50,000걸음 이하로 설정해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String unit,
    required String description,
    required String? Function(String?) validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: validator,
            decoration: InputDecoration(
              labelText: '목표 $unit',
              hintText: '목표를 입력하세요',
              suffixText: unit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final activeCalories = double.parse(_activeCaloriesController.text);
      final exerciseMinutes = int.parse(_exerciseMinutesController.text);
      final steps = int.parse(_stepsController.text);

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
            content: Text('목표가 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
