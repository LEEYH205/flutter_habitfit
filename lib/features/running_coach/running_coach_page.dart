import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/running_coach.dart';
import '../../services/running_coach_service.dart';
import '../../widgets/app_bar_with_notifications.dart';
import 'all_training_plans_page.dart';
import 'progress_tracking_page.dart';
import 'running_coach_setup_page.dart';
import 'training_plan_page.dart';

/// 러닝 코치 메인 페이지
class RunningCoachPage extends ConsumerStatefulWidget {
  const RunningCoachPage({super.key});

  @override
  ConsumerState<RunningCoachPage> createState() => _RunningCoachPageState();
}

class _RunningCoachPageState extends ConsumerState<RunningCoachPage> {
  final RunningCoachService _coachService = RunningCoachService();

  List<RunningEvent> _events = [];
  List<TrainingPlan> _trainingPlans = [];
  RunningCoachSettings? _settings;
  bool _isLoading = true;
  bool _isCreatingPlan = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final events = await _coachService.getUserRunningEvents();
      final plans = await _coachService.getUserTrainingPlans();
      final settings = await _coachService.getCoachSettings();

      setState(() {
        _events = events;
        _trainingPlans = plans;
        _settings = settings;
      });
    } catch (e) {
      print('❌ 러닝 코치 데이터 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBarWithNotifications(
          title: '🏃‍♂️ 러닝 코치',
          showProfile: false,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '🏃‍♂️ 러닝 코치',
        showProfile: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환영 메시지 및 설정 상태
              _buildWelcomeCard(),

              const SizedBox(height: 20),

              // 러닝 이벤트 섹션
              _buildEventsSection(),

              const SizedBox(height: 20),

              // 훈련 계획 섹션
              if (_trainingPlans.isNotEmpty) ...[
                _buildTrainingPlansSection(),
                const SizedBox(height: 20),
              ],

              // 개발자 디버깅 섹션 (디버그 모드에서만 표시)
              if (kDebugMode) ...[
                _buildDeveloperSection(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final hasSettings = _settings != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  '러닝 개인 코치',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasSettings
                  ? '체계적인 훈련 계획으로 목표를 달성해보세요!'
                  : '개인 맞춤형 러닝 훈련 계획을 시작해보세요!',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToSetup(),
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(hasSettings ? '설정 변경' : '설정하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (hasSettings) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToProgressTracking(),
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('진행 상황'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (hasSettings) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '평균 페이스: ${_settings!.averagePace.inMinutes}:${(_settings!.averagePace.inSeconds % 60).toString().padLeft(2, '0')}/km',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '주간 러닝: ${_settings!.weeklyRunningDays}일, LSD: ${_settings!.weeklyLsdDays}일',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🎯 러닝 이벤트',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _navigateToSetup(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('이벤트 추가'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_events.isEmpty)
          _buildEmptyEventsCard()
        else
          ..._events.take(3).map((event) => _buildEventCard(event)),
        if (_events.length > 3) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: 전체 이벤트 목록 페이지로 이동
              },
              child: Text('전체 ${_events.length}개 이벤트 보기'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyEventsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 러닝 이벤트가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 러닝 목표를 설정해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(RunningEvent event) {
    final daysUntilEvent = event.eventDate.difference(DateTime.now()).inDays;
    final isUpcoming = daysUntilEvent > 0;

    return Dismissible(
      key: Key('event_${event.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteEventConfirmation(event);
      },
      onDismissed: (direction) {
        _deleteEventInBackground(event);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUpcoming ? Colors.blue.shade200 : Colors.grey.shade300,
            width: isUpcoming ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                      color: isUpcoming
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.flag,
                      color: isUpcoming
                          ? Colors.blue.shade600
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${event.eventDate.year}.${event.eventDate.month.toString().padLeft(2, '0')}.${event.eventDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'D-$daysUntilEvent',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildEventInfo(
                      Icons.straighten, '${event.targetDistance}km'),
                  const SizedBox(width: 16),
                  _buildEventInfo(Icons.timer,
                      '${event.targetTime.inHours}h${(event.targetTime.inMinutes % 60).toString().padLeft(2, '0')}m'),
                  const SizedBox(width: 16),
                  _buildEventInfo(Icons.speed,
                      '${event.targetPace.inMinutes}:${(event.targetPace.inSeconds % 60).toString().padLeft(2, '0')}/km'),
                ],
              ),
              if (isUpcoming) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingPlan
                        ? null
                        : () => _createTrainingPlan(event),
                    icon: _isCreatingPlan
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.fitness_center, size: 18),
                    label: Text(_isCreatingPlan ? '생성 중...' : '훈련 계획 생성'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isCreatingPlan ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📋 훈련 계획',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToAllTrainingPlans(),
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._trainingPlans
            .where((plan) => _events.any((event) => event.id == plan.eventId))
            .take(2)
            .map((plan) => _buildTrainingPlanCard(plan)),
      ],
    );
  }

  Widget _buildTrainingPlanCard(TrainingPlan plan) {
    final event = _events.firstWhere((e) => e.id == plan.eventId);
    final progress = DateTime.now().difference(plan.startDate).inDays /
        (plan.endDate.difference(plan.startDate).inDays);
    final progressPercent = (progress * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        onTap: () => _navigateToTrainingPlan(plan),
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
                  Text(
                    '$progressPercent%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.green.shade100,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '목표: ${event.targetDistance}km in ${event.targetTime.inHours}h${(event.targetTime.inMinutes % 60).toString().padLeft(2, '0')}m',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteEventConfirmation(RunningEvent event) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('이벤트 삭제'),
              content: Text(
                  '\'${event.name}\' 이벤트와 관련된 모든 훈련 계획을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
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
            );
          },
        ) ??
        false;
  }

  void _deleteEventInBackground(RunningEvent event) async {
    try {
      final success = await _coachService.deleteRunningEvent(event.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'${event.name}\' 이벤트가 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        // UI에서 즉시 제거
        setState(() {
          _events.removeWhere((e) => e.id == event.id);
          _trainingPlans.removeWhere((plan) => plan.eventId == event.id);
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이벤트 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
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
    }
  }

  void _navigateToSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RunningCoachSetupPage(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToTrainingPlan(TrainingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingPlanPage(plan: plan),
      ),
    );
  }

  void _navigateToAllTrainingPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllTrainingPlansPage(
          events: _events,
          trainingPlans: _trainingPlans,
          onPlanDeleted: () {
            // 훈련 계획이 삭제되면 데이터 새로고침
            _loadData();
          },
        ),
      ),
    );
  }

  void _navigateToProgressTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProgressTrackingPage(),
      ),
    );
  }

  Future<void> _createTrainingPlan(RunningEvent event) async {
    if (_settings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 러닝 코치 설정을 완료해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      _navigateToSetup();
      return;
    }

    try {
      // 로딩 상태 시작
      setState(() {
        _isCreatingPlan = true;
      });

      print('🏃‍♂️ 훈련 계획 생성 시작...');

      final plan = await _coachService.generateTrainingPlan(
        eventId: event.id,
        event: event,
        settings: _settings!,
      );

      print('🏃‍♂️ 훈련 계획 생성 완료: ${plan != null}');

      // 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isCreatingPlan = false;
        });
      }

      if (plan != null) {
        print('✅ 훈련 계획 생성 성공 - 네비게이션 시작');

        await _loadData(); // 데이터 새로고침

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 훈련 계획이 성공적으로 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );

          // 네비게이션
          _navigateToTrainingPlan(plan);
          print('🚀 훈련 계획 페이지로 네비게이션 완료');
        }
      } else {
        throw Exception('훈련 계획 생성 실패');
      }
    } catch (e) {
      print('❌ 훈련 계획 생성 오류: $e');

      // 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isCreatingPlan = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 훈련 계획 생성에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 개발자 디버깅 섹션
  Widget _buildDeveloperSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '🔧 개발자 디버깅 도구',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ 주의: 이 버튼들은 Firebase DB 데이터를 완전히 삭제합니다!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeveloperButton(
              '개인 코치 설정 삭제',
              Icons.settings,
              Colors.orange,
              _deleteCoachSettings,
            ),
            const SizedBox(height: 8),
            _buildDeveloperButton(
              '모든 러닝 이벤트 삭제',
              Icons.event,
              Colors.blue,
              _deleteAllRunningEvents,
            ),
            const SizedBox(height: 8),
            _buildDeveloperButton(
              '모든 훈련 계획 삭제',
              Icons.fitness_center,
              Colors.green,
              _deleteAllTrainingPlans,
            ),
            const SizedBox(height: 8),
            _buildDeveloperButton(
              '전체 데이터 초기화',
              Icons.delete_forever,
              Colors.red,
              _resetAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 개인 코치 설정 삭제
  Future<void> _deleteCoachSettings() async {
    final confirmed = await _showConfirmationDialog(
      '개인 코치 설정 삭제',
      '개인 코치 설정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
    );

    if (!confirmed) return;

    try {
      final success = await _coachService.deleteCoachSettings();

      if (success) {
        setState(() {
          _settings = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 개인 코치 설정이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 개인 코치 설정 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 모든 러닝 이벤트 삭제
  Future<void> _deleteAllRunningEvents() async {
    final confirmed = await _showConfirmationDialog(
      '모든 러닝 이벤트 삭제',
      '모든 러닝 이벤트를 삭제하시겠습니까?\n\n관련된 훈련 계획도 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
    );

    if (!confirmed) return;

    try {
      int deletedCount = 0;

      for (final event in _events) {
        final success = await _coachService.deleteRunningEvent(event.id);
        if (success) deletedCount++;
      }

      setState(() {
        _events.clear();
        _trainingPlans.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $deletedCount개의 러닝 이벤트가 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 모든 훈련 계획 삭제
  Future<void> _deleteAllTrainingPlans() async {
    final confirmed = await _showConfirmationDialog(
      '모든 훈련 계획 삭제',
      '모든 훈련 계획을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
    );

    if (!confirmed) return;

    try {
      int deletedCount = 0;

      for (final plan in _trainingPlans) {
        final success = await _coachService.deleteTrainingPlan(plan.id);
        if (success) deletedCount++;
      }

      setState(() {
        _trainingPlans.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $deletedCount개의 훈련 계획이 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 전체 데이터 초기화
  Future<void> _resetAllData() async {
    final confirmed = await _showConfirmationDialog(
      '전체 데이터 초기화',
      '러닝 코치의 모든 데이터를 삭제하시겠습니까?\n\n• 개인 코치 설정\n• 모든 러닝 이벤트\n• 모든 훈련 계획\n\n이 작업은 되돌릴 수 없습니다!',
    );

    if (!confirmed) return;

    try {
      // 1. 개인 코치 설정 삭제
      await _coachService.deleteCoachSettings();

      // 2. 모든 러닝 이벤트 삭제 (관련 훈련 계획도 함께 삭제됨)
      for (final event in _events) {
        await _coachService.deleteRunningEvent(event.id);
      }

      // 3. 남은 훈련 계획들 삭제
      for (final plan in _trainingPlans) {
        await _coachService.deleteTrainingPlan(plan.id);
      }

      setState(() {
        _settings = null;
        _events.clear();
        _trainingPlans.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 모든 데이터가 초기화되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 확인 다이얼로그 표시
  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
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
}
