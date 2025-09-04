import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import '../running/running_analysis_page.dart';
import 'day_details_page.dart';
import '../healthkit_test_page.dart';

/// 리포트 페이지 - 달력 중심의 통합 시스템
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  // 통계 데이터
  int _totalHabits = 0;
  int _totalWorkouts = 0;
  int _totalRunningWorkouts = 0;
  final int _totalMeals = 0;
  double _habitCompletionRate = 0.0;
  double _workoutCompletionRate = 0.0;
  final double _runningCompletionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 캘린더 데이터 로드 시작...');

      // _focusedDay를 기준으로 월 데이터 로드
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      print(
          '📅 로드 범위: ${startOfMonth.year}-${startOfMonth.month} ~ ${endOfMonth.year}-${endOfMonth.month}');

      await _loadMonthData(startOfMonth, endOfMonth);
      await _loadRunningData(startOfMonth, endOfMonth);
      await _calculateStatistics(startOfMonth, endOfMonth);

      print('✅ 캘린더 데이터 로드 완료');
    } catch (e) {
      print('❌ 캘린더 데이터 로드 실패: $e');
      // 에러 발생 시 기본값으로 초기화
      setState(() {
        _events = {};
        _totalHabits = 0;
        _totalWorkouts = 0;
        _habitCompletionRate = 0.0;
        _workoutCompletionRate = 0.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthData(DateTime start, DateTime end) async {
    try {
      print(
          '🔍 데이터 로드 시작: ${start.year}-${start.month} ~ ${end.year}-${end.month}');

      // 사용자 인증 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ 사용자 인증이 필요합니다.');
        setState(() {
          _events = {};
          _isLoading = false;
        });
        return;
      }

      final uid = user.uid;
      print('👤 사용자 UID: $uid');

      // Firebase에서 사용자별 습관 완료 데이터 로드 (인덱스 없이 단순 조회)
      final habitsQuery = await FirebaseFirestore.instance
          .collection('habit_completions')
          .where('uid', isEqualTo: uid)
          .where('done', isEqualTo: true)
          .get();

      print('📝 습관 데이터: ${habitsQuery.docs.length}개');

      // 습관 데이터 디버깅
      for (final doc in habitsQuery.docs) {
        final data = doc.data();
        print(
            '📝 습관 완료 데이터: ${data['date']} - ${data['habitId']} - ${data['done']}');
      }

      final workoutsQuery = await FirebaseFirestore.instance
          .collection('workouts')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: _getDateId(start))
          .where('date', isLessThanOrEqualTo: _getDateId(end))
          .get();

      print('💪 운동 데이터: ${workoutsQuery.docs.length}개');

      // 이벤트 맵 구성 (실제 Firebase 데이터)
      for (int i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        _events[dateKey] = [];

        final dateId = _getDateId(date);
        print('📅 $dateId 처리 중...');

        // 습관 체크 여부 (클라이언트에서 날짜 필터링)
        final habitDocs = habitsQuery.docs.where(
          (doc) => doc.data()['date'] == dateId,
        );
        if (habitDocs.isNotEmpty) {
          // 습관 완료 개수를 이벤트에 저장
          _events[dateKey]!.add('habit:${habitDocs.length}');
          print('✅ $dateId: 습관 완료 (${habitDocs.length}개)');
        }

        // 운동 완료 여부
        final workoutDocs = workoutsQuery.docs.where(
          (doc) => doc.data()['date'] == dateId,
        );
        if (workoutDocs.isNotEmpty) {
          _events[dateKey]!.add('workout');
          print('💪 $dateId: 운동 완료 (${workoutDocs.length}개)');
        }
      }

      print('🎯 총 이벤트: ${_events.length}일');
      _events.forEach((date, events) {
        if (events.isNotEmpty) {
          print('📊 ${date.month}/${date.day}: ${events.join(', ')}');
        }
      });
    } catch (e) {
      print('❌ 월간 데이터 로드 실패: $e');
    }
  }

  /// 달리기 데이터 로드 (HealthKit) - 운동에 통합
  Future<void> _loadRunningData(DateTime start, DateTime end) async {
    try {
      print('🏃‍♂️ 달리기 데이터 로드 시작...');

      final health = HealthFactory();

      // HealthKit 사용 가능 여부 확인
      try {
        final types = [HealthDataType.WORKOUT];
        final granted = await health.requestAuthorization(types);

        if (granted) {
          // 달리기 운동 데이터 가져오기
          final runningWorkouts = await health.getHealthDataFromTypes(
            start,
            end,
            [HealthDataType.WORKOUT],
          );

          // 달리기 운동만 필터링
          final runningData = runningWorkouts.where((workout) {
            final workoutType = workout.value.toString().toLowerCase();
            return workoutType.contains('running') ||
                workoutType.contains('run') ||
                workoutType.contains('jog');
          }).toList();

          print('🏃‍♂️ 달리기 운동 데이터: ${runningData.length}개');

          // 달리기를 운동으로 통합하여 캘린더에 추가
          for (final workout in runningData) {
            final workoutDate = DateTime(
              workout.dateFrom.year,
              workout.dateFrom.month,
              workout.dateFrom.day,
            );

            if (_events.containsKey(workoutDate)) {
              if (!_events[workoutDate]!.contains('workout')) {
                _events[workoutDate]!.add('workout');
              }
            } else {
              _events[workoutDate] = ['workout'];
            }
          }

          _totalRunningWorkouts = runningData.length;
        } else {
          print('⚠️ HealthKit 권한이 거부되었습니다.');
        }
      } catch (e) {
        print('❌ HealthKit 데이터 로드 실패: $e');
      }
    } catch (e) {
      print('❌ 달리기 데이터 로드 실패: $e');
    }
  }

  Future<void> _calculateStatistics(DateTime start, DateTime end) async {
    try {
      final daysInMonth = end.difference(start).inDays + 1;

      // 사용자 인증 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ 통계 계산을 위한 사용자 인증이 필요합니다.');
        return;
      }

      final uid = user.uid;

      // Firebase에서 사용자별 통계 계산 (habit_completions에서)
      final habitsQuery = await FirebaseFirestore.instance
          .collection('habit_completions')
          .where('uid', isEqualTo: uid)
          .where('done', isEqualTo: true)
          .get();

      // 클라이언트에서 날짜 범위 필터링
      final completedHabits = habitsQuery.docs.where((doc) {
        final date = doc.data()['date'] as String;
        return date.compareTo(_getDateId(start)) >= 0 &&
            date.compareTo(_getDateId(end)) <= 0;
      }).length;
      _totalHabits = completedHabits;
      _habitCompletionRate =
          daysInMonth > 0 ? (completedHabits / daysInMonth) * 100 : 0;

      final workoutsQuery = await FirebaseFirestore.instance
          .collection('workouts')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: _getDateId(start))
          .where('date', isLessThanOrEqualTo: _getDateId(end))
          .get();

      // 운동 + 달리기를 통합하여 계산
      _totalWorkouts = workoutsQuery.docs.length + _totalRunningWorkouts;
      _workoutCompletionRate =
          daysInMonth > 0 ? (_totalWorkouts / daysInMonth) * 100 : 0;

      print('📊 사용자별 통계: 습관 $_totalHabits회, 운동(통합) $_totalWorkouts회');
    } catch (e) {
      print('❌ 통계 계산 실패: $e');
    }
  }

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // 시간 정보를 제거하고 날짜만으로 키 생성
    final dateKey = DateTime(day.year, day.month, day.day);
    final events = _events[dateKey] ?? [];

    // 디버그 로그 추가
    print('🔍 _getEventsForDay 호출: ${day.year}-${day.month}-${day.day}');
    print('🔑 찾는 키: ${dateKey.year}-${dateKey.month}-${dateKey.day}');
    print('📊 찾은 이벤트: $events');
    print(
        '🗺️ 전체 _events 키들: ${_events.keys.map((k) => '${k.year}-${k.month}-${k.day}').toList()}');

    return events;
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'habit':
        return Colors.green;
      case 'workout':
        return Colors.blue;
      case 'meal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEventLabel(String eventType) {
    switch (eventType) {
      case 'habit':
        return '습관';
      case 'workout':
        return '운동';
      case 'meal':
        return '식사';
      default:
        return '';
    }
  }

  Widget _buildAuthRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '로그인이 필요합니다',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '리포트를 보려면 먼저 로그인해주세요.\n개인 데이터를 안전하게 보호합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // 로그인 페이지로 이동하는 로직 추가 가능
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('로그인 기능을 구현해주세요'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('로그인하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 인증 상태 확인
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 리포트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? _buildAuthRequiredView()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 오늘 요약
                      _buildTodaySummary(),

                      const SizedBox(height: 24),

                      // 월간 달력
                      _buildMonthlyCalendar(),

                      const SizedBox(height: 24),

                      // 월간 통계
                      _buildMonthlyStatistics(),

                      const SizedBox(height: 24),

                      // 목표 진행률 (간소화)
                      _buildGoalProgress(),

                      const SizedBox(height: 24),

                      // 이벤트 범례
                      _buildEventLegend(),

                      const SizedBox(height: 24),

                      // HealthKit 테스트 버튼
                      _buildHealthKitTestButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTodaySummary() {
    final selectedKey =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final selectedEvents = _events[selectedKey] ?? [];
    final isToday = DateTime.now().year == _selectedDay.year &&
        DateTime.now().month == _selectedDay.month &&
        DateTime.now().day == _selectedDay.day;

    // 습관 완료 개수 계산
    int habitCount = 0;
    int workoutCount = 0;

    for (final event in selectedEvents) {
      if (event.toString().startsWith('habit:')) {
        final parts = event.toString().split(':');
        if (parts.length > 1) {
          habitCount += int.tryParse(parts[1]) ?? 0;
        }
      } else if (event.toString().startsWith('workout:')) {
        final parts = event.toString().split(':');
        if (parts.length > 1) {
          workoutCount += int.tryParse(parts[1]) ?? 0;
        }
      }
    }

    // 총 습관 개수 가져오기 (비동기로 처리)
    return FutureBuilder<int>(
      future: _getTotalHabitCount(),
      builder: (context, snapshot) {
        final totalHabits = snapshot.data ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isToday ? Icons.today : Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday
                        ? '오늘 요약 (${_selectedDay.month}월 ${_selectedDay.day}일)'
                        : '${_selectedDay.month}월 ${_selectedDay.day}일 요약',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedEvents.isEmpty)
                Text(
                  isToday ? '완료된 항목이 없습니다' : '해당 날짜에 완료된 항목이 없습니다',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Column(
                  children: [
                    if (habitCount > 0)
                      _buildSummaryItem(
                        '습관',
                        '완료 ($habitCount/$totalHabits)',
                        Icons.check_circle,
                      ),
                    if (workoutCount > 0)
                      _buildSummaryItem(
                        '운동',
                        '완료 ($workoutCount개)',
                        Icons.fitness_center,
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Text(
                isToday ? '내일도 파이팅! 💪' : '다음 날도 파이팅! 💪',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 사용자의 총 습관 개수 가져오기
  Future<int> _getTotalHabitCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_habits')
          .where('uid', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ 총 습관 개수 가져오기 실패: $e');
      return 0;
    }
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                '${_focusedDay.month}월 달력',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                int habitCount = 0;
                int workoutCount = 0;

                for (final event in events) {
                  if (event.toString().startsWith('habit:')) {
                    final parts = event.toString().split(':');
                    if (parts.length > 1) {
                      habitCount += int.tryParse(parts[1]) ?? 0;
                    }
                  } else if (event.toString().startsWith('workout:')) {
                    final parts = event.toString().split(':');
                    if (parts.length > 1) {
                      workoutCount += int.tryParse(parts[1]) ?? 0;
                    }
                  }
                }

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (habitCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$habitCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (workoutCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$workoutCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: false,
              leftChevronIcon: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.blue),
                onPressed: () {
                  final previousMonth =
                      DateTime(_focusedDay.year, _focusedDay.month - 1);
                  setState(() {
                    _focusedDay = previousMonth;
                  });
                  _loadCalendarData();
                },
              ),
              rightChevronIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Today 버튼을 헤더에 통합
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDay = DateTime.now();
                        });
                        _loadCalendarData();
                      },
                      icon: const Icon(Icons.today, size: 16),
                      label:
                          const Text('Today', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.blue),
                    onPressed: () {
                      final nextMonth =
                          DateTime(_focusedDay.year, _focusedDay.month + 1);
                      setState(() {
                        _focusedDay = nextMonth;
                      });
                      _loadCalendarData();
                    },
                  ),
                ],
              ),
              titleTextFormatter: (date, locale) {
                return '${date.month}월 ${date.year}';
              },
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              headerMargin: const EdgeInsets.symmetric(vertical: 12),
              headerPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // 날짜 클릭 시 상세 정보 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DayDetailsPage(selectedDay: selectedDay),
                ),
              );
            },
            onPageChanged: (focusedDay) {
              // 같은 월이면 데이터 로드하지 않음
              if (_focusedDay.month != focusedDay.month ||
                  _focusedDay.year != focusedDay.year) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadCalendarData(); // 새로운 월 데이터 로드
              }
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              // 히트맵 배경에 대비되는 날짜 텍스트 색상 - 더 진한 검은색
              defaultTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                '${_focusedDay.month}월 통계',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 습관 완료율
          _buildStatItem(
            '습관 완료율',
            '${_habitCompletionRate.toStringAsFixed(1)}%',
            _totalHabits,
            Colors.green,
            Icons.check_circle,
          ),

          const SizedBox(height: 16),

          // 운동 완료율 (달리기 포함)
          _buildStatItem(
            '운동 완료율',
            '${_workoutCompletionRate.toStringAsFixed(1)}%',
            _totalWorkouts,
            Colors.blue,
            Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.legend_toggle, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '범례',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendItem('습관', Colors.green, Icons.check_circle),
              const SizedBox(width: 24),
              _buildLegendItem('운동', Colors.blue, Icons.fitness_center),
              const SizedBox(width: 24),
              _buildLegendItem('식사', Colors.orange, Icons.restaurant),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String percentage, int count, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($count회)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'habit':
        return Icons.check_circle;
      case 'workout':
        return Icons.fitness_center;
      case 'meal':
        return Icons.restaurant;
      default:
        return Icons.circle;
    }
  }

  Widget _buildRunningAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                '달리기 분석',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '💡 AI 기반 달리기 데이터 분석 및 개인화된 코칭을 제공합니다',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _goToRunningAnalysis(),
              icon: const Icon(Icons.analytics),
              label: const Text('달리기 분석'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToRunningAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RunningAnalysisPage(),
      ),
    );
  }

  // 주간/월간 트렌드 분석
  Widget _buildTrendAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple[600]),
              const SizedBox(width: 8),
              Text(
                '주간/월간 트렌드',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 주간 트렌드
          _buildWeeklyTrend(),

          const SizedBox(height: 16),

          // 월간 트렌드
          _buildMonthlyTrend(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이번 주 (${weekStart.month}/${weekStart.day} ~ ${weekEnd.month}/${weekEnd.day})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            final isToday = date.day == now.day && date.month == now.month;
            final events = _getEventsForDay(date);
            int habitCount = 0;
            int workoutCount = 0;

            for (final event in events) {
              if (event.toString().startsWith('habit:')) {
                final parts = event.toString().split(':');
                if (parts.length > 1) {
                  habitCount += int.tryParse(parts[1]) ?? 0;
                }
              } else if (event.toString().startsWith('workout:')) {
                final parts = event.toString().split(':');
                if (parts.length > 1) {
                  workoutCount += int.tryParse(parts[1]) ?? 0;
                }
              }
            }

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 60,
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday ? Colors.blue : Colors.grey[300]!,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (habitCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$habitCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (workoutCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$workoutCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이번 달 진행률',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTrendItem(
                '습관',
                _habitCompletionRate,
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTrendItem(
                '운동',
                _workoutCompletionRate,
                Colors.blue,
                Icons.fitness_center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendItem(
      String label, double percentage, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 히트맵 기능은 달력의 이벤트 마커로 대체됨

  // 목표 대비 진행률
  Widget _buildGoalProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              Text(
                '${_focusedDay.month}월 목표 진행률',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 목표 진행률 카드들
          Row(
            children: [
              Expanded(
                child: _buildGoalCard(
                  '습관 목표',
                  '$_totalHabits / 30',
                  _totalHabits / 30.0,
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGoalCard(
                  '운동 목표',
                  '$_totalWorkouts / 20',
                  _totalWorkouts / 20.0,
                  Colors.blue,
                  Icons.fitness_center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, String progress, double percentage,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            progress,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(
            '${(percentage * 100).clamp(0.0, 100.0).toStringAsFixed(1)}% 달성',
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthKitTestButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety,
                  color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'HealthKit 테스트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'HealthKit에서 실제 데이터를 가져올 수 있는지 테스트해보세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthKitTestPage(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('HealthKit 테스트 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
