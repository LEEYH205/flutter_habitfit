import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../running/running_analysis_page.dart';

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
  final int _totalMeals = 0;
  double _habitCompletionRate = 0.0;
  double _workoutCompletionRate = 0.0;

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

      // 더미 데이터로 대체 (Firebase 연결 없이)
      print('📝 더미 습관 데이터 생성 중...');
      print('💪 더미 운동 데이터 생성 중...');

      // 이벤트 맵 구성 (더미 데이터)
      for (int i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        _events[dateKey] = [];

        // 더미 데이터 생성 (랜덤하게)
        if (i % 3 == 0) {
          _events[dateKey]!.add('habit');
          print('✅ ${date.month}/${date.day}: 습관 완료 (더미)');
        }
        if (i % 4 == 0) {
          _events[dateKey]!.add('workout');
          print('💪 ${date.month}/${date.day}: 운동 완료 (더미)');
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

  Future<void> _calculateStatistics(DateTime start, DateTime end) async {
    try {
      final daysInMonth = end.difference(start).inDays + 1;

      // 더미 통계 계산 (Firebase 연결 없이)
      _totalHabits = (daysInMonth / 3).round(); // 3일마다 습관 완료
      _habitCompletionRate =
          daysInMonth > 0 ? (_totalHabits / daysInMonth) * 100 : 0;

      _totalWorkouts = (daysInMonth / 4).round(); // 4일마다 운동 완료
      _workoutCompletionRate =
          daysInMonth > 0 ? (_totalWorkouts / daysInMonth) * 100 : 0;

      print('📊 더미 통계: 습관 $_totalHabits회, 운동 $_totalWorkouts회');
    } catch (e) {
      print('❌ 통계 계산 실패: $e');
    }
  }

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 리포트 & 달력'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
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
                ],
              ),
            ),
    );
  }

  Widget _buildTodaySummary() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayEvents = _events[todayKey] ?? [];

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
                Icons.today,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '오늘 요약 (${today.month}월 ${today.day}일)',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todayEvents.isEmpty)
            const Text(
              '완료된 항목이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...todayEvents.map((event) => _buildSummaryItem(
                  _getEventLabel(event),
                  '완료',
                  _getEventIcon(event),
                )),
          const SizedBox(height: 16),
          const Text(
            '내일도 파이팅! 💪',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                  _loadCalendarData();
                },
                icon: const Icon(Icons.today),
                label: const Text('Today'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
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
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  // 이벤트 타입별로 색상 구분
                  final hasHabit = events.contains('habit');
                  final hasWorkout = events.contains('workout');
                  final hasMeal = events.contains('meal');

                  // 이벤트 개수와 색상 결정
                  Color markerColor;
                  String markerText;

                  if (hasHabit && hasWorkout) {
                    markerColor = Colors.green;
                    markerText = '${events.length}';
                  } else if (hasHabit) {
                    markerColor = Colors.green;
                    markerText = '습';
                  } else if (hasWorkout) {
                    markerColor = Colors.blue;
                    markerText = '운';
                  } else if (hasMeal) {
                    markerColor = Colors.orange;
                    markerText = '식';
                  } else {
                    markerColor = Colors.grey;
                    markerText = '${events.length}';
                  }

                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: markerColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: markerColor.withOpacity(0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        markerText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
              // 날짜 셀 배경색 개선
              defaultBuilder: (context, date, focusedDay) {
                final events = _getEventsForDay(date);
                final hasHabit = events.contains('habit');
                final hasWorkout = events.contains('workout');

                // 활동이 있는 날짜는 연한 배경색 적용
                if (hasHabit || hasWorkout) {
                  Color backgroundColor;
                  if (hasHabit && hasWorkout) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                  } else if (hasHabit) {
                    backgroundColor = Colors.green.withOpacity(0.08);
                  } else {
                    backgroundColor = Colors.blue.withOpacity(0.08);
                  }

                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }
                return null;
              },
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

          // 운동 완료율
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
            final hasHabit = _getEventsForDay(date).contains('habit');
            final hasWorkout = _getEventsForDay(date).contains('workout');

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
                        if (hasHabit)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasWorkout)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
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
}
