import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:health/health.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/profile_menu.dart';
import '../../providers/day_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/day_log.dart';
import '../insights/insights_page.dart';
import '../notifications/notifications_page.dart';

class ActivityPage extends ConsumerStatefulWidget {
  final DateTime? initialDate; // 초기 선택 날짜

  const ActivityPage({super.key, this.initialDate});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    _checkHealthKitPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // 페이지 상태 유지
  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '활동',
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
      body: Column(
        children: [
          // 탭 바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: '운동 기록', icon: Icon(Icons.fitness_center)),
                Tab(text: '분석', icon: Icon(Icons.analytics)),
              ],
            ),
          ),
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJournalTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Journal 탭 (운동 기록)
  Widget _buildJournalTab() {
    return SafeArea(
      child: RepaintBoundary(
        child: Column(
          children: [
            // 캘린더 헤더
            _buildCalendarHeader(),

            // 캘린더
            _buildCalendar(),

            // 선택된 날짜의 상세 정보
            Expanded(
              child: _buildSelectedDayDetails(),
            ),
          ],
        ),
      ),
    );
  }

  /// Insights 탭 (분석)
  Widget _buildInsightsTab() {
    return const InsightsPage(showAppBar: false);
  }

  /// HealthKit 권한 확인 및 요청
  Future<void> _checkHealthKitPermissions() async {
    try {
      print('🔍 HealthKit 권한 상태 확인 중...');

      final health = HealthFactory();
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
      ];

      final granted = await health.requestAuthorization(types);

      if (granted) {
        print('✅ HealthKit 권한이 승인되었습니다');
      } else {
        print('❌ HealthKit 권한이 거부되었습니다');
      }
    } catch (e) {
      print('❌ HealthKit 권한 확인 오류: $e');
    }
  }

  /// 캘린더 헤더
  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_focusedDay.month}월 ${_focusedDay.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              TextButton(
                onPressed: _goToToday,
                child: const Text('Today'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 캘린더
  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadAllHealthKitData(),
        builder: (context, snapshot) {
          final healthKitData = snapshot.data ?? [];

          return TableCalendar<dynamic>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerVisible: false,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return healthKitData
                  .where((data) => isSameDay(day, data['date']))
                  .toList();
            },
          );
        },
      ),
    );
  }

  /// 선택된 날짜의 상세 정보
  Widget _buildSelectedDayDetails() {
    return Consumer(
      builder: (context, ref, child) {
        final dayLogAsync = ref.watch(dayLogProvider(_selectedDay));

        return dayLogAsync.when(
          data: (dayLog) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더
                Text(
                  '${_selectedDay.month}월 ${_selectedDay.day}일',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 운동 데이터
                _buildWorkoutData(dayLog),
                const SizedBox(height: 16),

                // HealthKit 데이터
                _buildHealthKitData(),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('데이터 로딩 실패: $error'),
          ),
        );
      },
    );
  }

  /// 운동 데이터 섹션
  Widget _buildWorkoutData(DayLog? dayLog) {
    return SectionCard(
      title: '운동',
      child: Column(
        children: [
          if (dayLog?.workouts.isEmpty ?? true)
            const Text('오늘 운동 기록이 없습니다.')
          else
            ...dayLog!.workouts.map((workout) => ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(workout['name'] ?? '운동'),
                  subtitle: Text('${workout['duration'] ?? 0}분'),
                  trailing:
                      Text('${workout['caloriesBurned']?.toInt() ?? 0}kcal'),
                )),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // 운동 추가 페이지로 이동
            },
            icon: const Icon(Icons.add),
            label: const Text('운동 추가'),
          ),
        ],
      ),
    );
  }

  /// HealthKit 데이터 섹션
  Widget _buildHealthKitData() {
    return SectionCard(
      title: 'HealthKit 데이터',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadHealthKitDataForDate(_selectedDay),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('데이터 로딩 실패: ${snapshot.error}');
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Text('오늘의 HealthKit 데이터가 없습니다.');
          }

          return Column(
            children: data
                .map((item) => ListTile(
                      leading: Icon(_getHealthKitIcon(item['type'])),
                      title: Text(item['type']),
                      subtitle: Text(item['value']),
                      trailing: Text(item['unit']),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  /// HealthKit 아이콘 반환
  IconData _getHealthKitIcon(String type) {
    switch (type) {
      case 'STEPS':
        return Icons.directions_walk;
      case 'HEART_RATE':
        return Icons.favorite;
      case 'DISTANCE_WALKING_RUNNING':
        return Icons.directions_run;
      case 'ACTIVE_ENERGY_BURNED':
        return Icons.local_fire_department;
      case 'WORKOUT':
        return Icons.fitness_center;
      default:
        return Icons.health_and_safety;
    }
  }

  /// 모든 HealthKit 데이터 로드
  Future<List<Map<String, dynamic>>> _loadAllHealthKitData() async {
    try {
      print('📅 HealthKit에서 모든 운동 데이터 로드 시작 (달력용)');

      final health = HealthFactory();
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      final steps = await health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.STEPS],
      );

      final workouts = await health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.WORKOUT],
      );

      final List<Map<String, dynamic>> result = [];

      // 걸음 수 데이터 처리
      for (final step in steps) {
        result.add({
          'date': step.dateFrom,
          'type': 'STEPS',
          'value': step.value.toString(),
          'unit': '걸음',
        });
      }

      // 운동 데이터 처리
      for (final workout in workouts) {
        result.add({
          'date': workout.dateFrom,
          'type': 'WORKOUT',
          'value': workout.value.toString(),
          'unit': '분',
        });
      }

      print('✅ HealthKit에서 ${result.length}개 운동 데이터 로드 완료');
      return result;
    } catch (e) {
      print('❌ HealthKit 데이터 로드 실패: $e');
      return [];
    }
  }

  /// 특정 날짜의 HealthKit 데이터 로드
  Future<List<Map<String, dynamic>>> _loadHealthKitDataForDate(
      DateTime date) async {
    try {
      final health = HealthFactory();
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final steps = await health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.STEPS],
      );

      final List<Map<String, dynamic>> result = [];

      for (final step in steps) {
        result.add({
          'type': 'STEPS',
          'value': step.value.toString(),
          'unit': '걸음',
        });
      }

      return result;
    } catch (e) {
      print('❌ HealthKit 데이터 로드 실패: $e');
      return [];
    }
  }

  /// 이전 달로 이동
  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  /// 다음 달로 이동
  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  /// 오늘로 이동
  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileMenu(),
    );
  }
}
