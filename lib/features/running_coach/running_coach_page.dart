import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/running_coach.dart';
import '../../services/running_coach_service.dart';
import '../../widgets/app_bar_with_notifications.dart';
import 'all_training_plans_page.dart';
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

              // 퀵 액션 버튼들
              _buildQuickActions(),
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

    return Container(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                _buildEventInfo(Icons.straighten, '${event.targetDistance}km'),
                const SizedBox(width: 16),
                _buildEventInfo(Icons.timer,
                    '${event.targetTime.inHours}:${(event.targetTime.inMinutes % 60).toString().padLeft(2, '0')}'),
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
                  onPressed:
                      _isCreatingPlan ? null : () => _createTrainingPlan(event),
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
        ..._trainingPlans.take(2).map((plan) => _buildTrainingPlanCard(plan)),
      ],
    );
  }

  Widget _buildTrainingPlanCard(TrainingPlan plan) {
    final event = _events.firstWhere((e) => e.id == plan.eventId,
        orElse: () => _events.first);
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
                '목표: ${event.targetDistance}km in ${event.targetTime.inHours}:${(event.targetTime.inMinutes % 60).toString().padLeft(2, '0')}',
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ 빠른 실행',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.settings,
                title: '코치 설정',
                subtitle: '페이스, 일정 설정',
                color: Colors.orange,
                onTap: () => _navigateToSetup(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics,
                title: '진행 상황',
                subtitle: '훈련 분석 보기',
                color: Colors.purple,
                onTap: () {
                  // TODO: 진행 상황 분석 페이지로 이동
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
