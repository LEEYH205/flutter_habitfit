import 'package:flutter/material.dart';
import '../../models/running_coach.dart';
import '../../services/running_coach_service.dart';
import '../../widgets/app_bar_with_notifications.dart';
import 'training_plan_page.dart';

/// 전체 훈련 계획 목록 페이지
class AllTrainingPlansPage extends StatefulWidget {
  final List<RunningEvent> events;
  final List<TrainingPlan> trainingPlans;
  final VoidCallback? onPlanDeleted;

  const AllTrainingPlansPage({
    super.key,
    required this.events,
    required this.trainingPlans,
    this.onPlanDeleted,
  });

  @override
  State<AllTrainingPlansPage> createState() => _AllTrainingPlansPageState();
}

class _AllTrainingPlansPageState extends State<AllTrainingPlansPage> {
  final RunningCoachService _coachService = RunningCoachService();
  late List<TrainingPlan> _trainingPlans;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _trainingPlans = List.from(widget.trainingPlans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '📋 전체 훈련 계획',
        showProfile: false,
      ),
      body: _trainingPlans.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trainingPlans.length,
              itemBuilder: (context, index) {
                final plan = _trainingPlans[index];
                return _buildTrainingPlanCard(context, plan);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 생성된 훈련 계획이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '러닝 코치에서 새로운 훈련 계획을 생성해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingPlanCard(BuildContext context, TrainingPlan plan) {
    final event = widget.events.firstWhere(
      (e) => e.id == plan.eventId,
      orElse: () => widget.events.first,
    );
    final progress = DateTime.now().difference(plan.startDate).inDays /
        (plan.endDate.difference(plan.startDate).inDays);
    final progressPercent = (progress * 100).clamp(0, 100).round();

    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 슬라이드
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, plan);
      },
      onDismissed: (direction) {
        // 즉시 목록에서 제거
        setState(() {
          _trainingPlans.removeWhere((p) => p.id == plan.id);
        });
        // 백그라운드에서 삭제 처리
        _deleteTrainingPlanInBackground(plan);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _navigateToTrainingPlan(context, plan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event.name} 훈련 계획',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plan.totalWeeks}주 계획',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progressPercent / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                  minHeight: 6,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '목표: ${event.targetDistance}km in ${event.targetTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTrainingPlan(BuildContext context, TrainingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingPlanPage(plan: plan),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, TrainingPlan plan) async {
    final event = widget.events.firstWhere(
      (e) => e.id == plan.eventId,
      orElse: () => widget.events.first,
    );

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('훈련 계획 삭제'),
            content: Text(
              '${event.name} 훈련 계획을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTrainingPlan(
      BuildContext context, TrainingPlan plan) async {
    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _coachService.deleteTrainingPlan(plan.id);

      if (success) {
        if (mounted) {
          setState(() {
            _trainingPlans.removeWhere((p) => p.id == plan.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('훈련 계획이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('훈련 계획 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _deleteTrainingPlanInBackground(TrainingPlan plan) async {
    try {
      final success = await _coachService.deleteTrainingPlan(plan.id);

      if (success) {
        print('✅ 훈련 계획 삭제 완료: ${plan.id}');
        // 부모에게 삭제 완료 알림
        widget.onPlanDeleted?.call();
      } else {
        print('❌ 훈련 계획 삭제 실패: ${plan.id}');
        // 삭제 실패 시 다시 목록에 추가
        if (mounted) {
          setState(() {
            _trainingPlans.add(plan);
            _trainingPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('훈련 계획 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 훈련 계획 삭제 오류: $e');
      // 삭제 실패 시 다시 목록에 추가
      if (mounted) {
        setState(() {
          _trainingPlans.add(plan);
          _trainingPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
