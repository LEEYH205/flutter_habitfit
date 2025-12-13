import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/section_card.dart';
import '../../providers/auth_provider.dart';
import '../running_coach/running_coach_page.dart';
import '../running_coach/running_coach_setup_page.dart';
import '../running_coach/progress_tracking_page.dart';
import '../notifications/notifications_page.dart';
import 'running_notifications_page.dart';
import '../../services/running_coach_service.dart';
import '../../models/running_coach.dart';
import '../settings/user_profile_page.dart';

class RunningPage extends ConsumerStatefulWidget {
  const RunningPage({super.key});

  @override
  ConsumerState<RunningPage> createState() => _RunningPageState();
}

class _RunningPageState extends ConsumerState<RunningPage> {
  final RunningCoachService _coachService = RunningCoachService();
  List<RunningEvent> _events = [];
  List<RunningEvent> _pastEvents = []; // 지난 이벤트
  List<TrainingPlan> _trainingPlans = [];
  RunningCoachSettings? _settings;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '러닝',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
              ),
              // Red dot for unread notifications
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _showProfileMenu(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    ref.read(authProviderProvider).user?.photoURL != null
                        ? NetworkImage(
                            ref.read(authProviderProvider).user!.photoURL!)
                        : null,
                child: ref.read(authProviderProvider).user?.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 러닝 코치 메인 섹션
                    _buildRunningCoachSection(),
                    const SizedBox(height: 24),

                    // 훈련 계획 관리 섹션
                    _buildTrainingPlanSection(),
                    const SizedBox(height: 24),

                    // 진행 상황 추적 섹션
                    _buildProgressTrackingSection(),
                    const SizedBox(height: 24),

                    // 러닝 설정 섹션
                    _buildRunningSettingsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRunningCoachSection() {
    return SectionCard(
      title: '러닝 코치',
      child: Column(
        children: [
          if (_settings == null) ...[
            const Text(
              '러닝 코치를 시작하려면 먼저 설정을 완료해주세요.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RunningCoachSetupPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('설정하기'),
            ),
          ] else ...[
            Text(
              '안녕하세요! 러닝 코치입니다.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 ${_events.length}개의 이벤트와 ${_trainingPlans.length}개의 훈련 계획이 있습니다.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RunningCoachSetupPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('설정 변경'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressTrackingPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.trending_up),
                    label: const Text('진행 상황'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainingPlanSection() {
    return SectionCard(
      title: '훈련 계획 관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 다가오는 이벤트 섹션
          if (_events.isEmpty && _pastEvents.isEmpty) ...[
            const Text(
              '아직 러닝 이벤트가 없습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RunningCoachPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('새 이벤트 생성'),
            ),
          ] else ...[
            if (_events.isNotEmpty) ...[
              Text(
                '다가오는 이벤트 (${_events.length}개)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._events.take(2).map((event) {
                // 날짜 형식: yy/mm/dd
                final year = event.eventDate.year.toString().substring(2);
                final month = event.eventDate.month.toString().padLeft(2, '0');
                final day = event.eventDate.day.toString().padLeft(2, '0');
                final dateStr = '$year/$month/$day';

                return ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(event.name),
                  subtitle: Text(
                      '${event.targetDistance.toStringAsFixed(1)}km - $dateStr'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningCoachPage(),
                      ),
                    );
                  },
                );
              }),
              if (_events.length > 2)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningCoachPage(),
                      ),
                    );
                  },
                  child: Text('전체 ${_events.length}개 보기'),
                ),
            ],

            // 지난 이벤트 섹션
            if (_pastEvents.isNotEmpty) ...[
              if (_events.isNotEmpty) const SizedBox(height: 16),
              Text(
                '지난 이벤트 (${_pastEvents.length}개)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              ..._pastEvents.take(2).map((event) {
                // 날짜 형식: yy/mm/dd
                final year = event.eventDate.year.toString().substring(2);
                final month = event.eventDate.month.toString().padLeft(2, '0');
                final day = event.eventDate.day.toString().padLeft(2, '0');
                final dateStr = '$year/$month/$day';

                return ListTile(
                  leading: Icon(Icons.event, color: Colors.grey.shade400),
                  title: Text(
                    event.name,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '${event.targetDistance.toStringAsFixed(1)}km - $dateStr',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningCoachPage(),
                      ),
                    );
                  },
                );
              }),
              if (_pastEvents.length > 2)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningCoachPage(),
                      ),
                    );
                  },
                  child: Text(
                    '전체 ${_pastEvents.length}개 보기',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTrackingSection() {
    return SectionCard(
      title: '진행 상황 추적',
      child: Column(
        children: [
          const Text(
            '훈련 진행 상황을 확인하고 다음 주 계획을 미리보세요.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressTrackingPage(),
                ),
              );
            },
            icon: const Icon(Icons.trending_up),
            label: const Text('진행 상황 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningSettingsSection() {
    return SectionCard(
      title: '러닝 설정',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('개인 코치 설정'),
            subtitle: Text(_settings != null ? '설정 완료' : '설정되지 않음'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RunningCoachSetupPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('알림 설정'),
            subtitle: const Text('훈련 알림 관리'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RunningNotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _coachService.getUserRunningEvents();
      final trainingPlans = await _coachService.getUserTrainingPlans();
      final settings = await _coachService.getCoachSettings();

      // 날짜가 지난 이벤트와 다가오는 이벤트 분리
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcomingEvents = <RunningEvent>[];
      final pastEvents = <RunningEvent>[];

      for (final event in events) {
        final eventDate = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
        );
        if (eventDate.isBefore(today)) {
          pastEvents.add(event);
        } else {
          upcomingEvents.add(event);
        }
      }

      // 날짜순으로 정렬 (다가오는 이벤트: 오름차순, 지난 이벤트: 내림차순)
      upcomingEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      pastEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));

      setState(() {
        _events = upcomingEvents;
        _pastEvents = pastEvents;
        _trainingPlans = trainingPlans;
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProfileMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserProfilePage(),
      ),
    );
  }
}
