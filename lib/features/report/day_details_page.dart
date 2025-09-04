import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:habitfit_mvp/features/running/running_analysis_page.dart';
import 'package:habitfit_mvp/services/health_kit_service.dart';

class DayDetailsPage extends StatefulWidget {
  final DateTime selectedDay;

  const DayDetailsPage({
    super.key,
    required this.selectedDay,
  });

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage> {
  Map<String, dynamic>? _dayData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDayDetails();
  }

  Future<void> _loadDayDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateKey = DateTime(widget.selectedDay.year,
          widget.selectedDay.month, widget.selectedDay.day);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      Map<String, dynamic> dayData = {
        'habits': [],
        'workouts': [],
        'runningData': null,
        'meals': [],
      };

      // 사용자 인증 확인
      if (FirebaseAuth.instance.currentUser != null) {
        // 실제 사용자 인증이 된 경우 Firebase 데이터 로드
        try {
          // 습관 완료 데이터 로드 (인덱스 없이 단순 조회)
          final habitSnapshot = await FirebaseFirestore.instance
              .collection('habit_completions')
              .where('uid', isEqualTo: uid)
              .where('done', isEqualTo: true)
              .get();

          // 선택된 날짜의 습관만 필터링
          final selectedDateHabits = habitSnapshot.docs
              .where(
                  (doc) => doc.data()['date'] == _getDateId(widget.selectedDay))
              .map((doc) => doc.data())
              .toList();

          if (selectedDateHabits.isNotEmpty) {
            dayData['habits'] = selectedDateHabits;
          }

          // 운동 데이터 로드 (전역 컬렉션에서 uid로 필터링)
          final workoutSnapshot = await FirebaseFirestore.instance
              .collection('workouts')
              .where('uid', isEqualTo: uid)
              .where('date', isEqualTo: _getDateId(widget.selectedDay))
              .get();

          if (workoutSnapshot.docs.isNotEmpty) {
            dayData['workouts'] =
                workoutSnapshot.docs.map((doc) => doc.data()).toList();
          }

          // 달리기 데이터 로드 (iOS에서는 HealthKit, 다른 플랫폼에서는 Firebase)
          if (Platform.isIOS) {
            // iOS에서는 HealthKit에서 달리기 데이터 가져오기
            try {
              final healthKitService = HealthKitService();
              final workouts =
                  await healthKitService.getRecentWorkouts(days: 30);

              // 선택된 날짜의 달리기 데이터 찾기
              final selectedDayRunning = workouts.where((workout) {
                final workoutDate = DateTime(
                  workout.startTime.year,
                  workout.startTime.month,
                  workout.startTime.day,
                );
                return workoutDate.isAtSameMomentAs(dateKey) &&
                    (workout.type.toLowerCase().contains('running') ||
                        workout.type.toLowerCase().contains('달리기'));
              }).toList();

              if (selectedDayRunning.isNotEmpty) {
                final running = selectedDayRunning.first;
                dayData['runningData'] = {
                  'distance': running.distance ?? 0.0,
                  'duration': running.duration.inSeconds,
                  'avgPace': running.distance != null && running.distance! > 0
                      ? (running.duration.inMinutes / running.distance!)
                      : 0.0,
                  'calories': running.calories ?? 0.0,
                  'date': running.startTime,
                  'source': 'HealthKit',
                };
                print('✅ HealthKit에서 달리기 데이터 로드 완료: ${running.distance}km');
              } else {
                print('ℹ️ 선택된 날짜에 HealthKit 달리기 데이터가 없습니다');
              }
            } catch (e) {
              print('⚠️ HealthKit 달리기 데이터 로드 실패: $e');
            }
          }
          //    } else {
          //      // 다른 플랫폼에서는 Firebase에서 달리기 데이터 가져오기
          //      final runningSnapshot = await FirebaseFirestore.instance
          //          .collection('users')
          //           .doc(user.uid)
          //           .collection('running_sessions')
          //           .where('date', isGreaterThanOrEqualTo: dateKey)
          //           .where('date', isLessThan: dateKey.add(const Duration(days: 1)))
          //           .get();

          //      if (runningSnapshot.docs.isNotEmpty) {
          //        dayData['runningData'] = runningSnapshot.docs.first.data();
          //      }
          //    }
        } catch (e) {
          print('Firebase 데이터 로드 실패, Mock 데이터 사용: $e');
        }
      } else {
        // 사용자가 인증되지 않은 경우 로그인 유도
        print('⚠️ 사용자 인증이 필요합니다.');
        setState(() {
          _error = '로그인이 필요한 서비스입니다.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _dayData = dayData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터 로드 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(widget.selectedDay),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.login,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 로그인 화면으로 이동
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: const Text('로그인하기'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dayData == null) {
      return const Center(
        child: Text('데이터를 불러올 수 없습니다.'),
      );
    }

    final habits = _dayData!['habits'] as List<dynamic>? ?? [];
    final workouts = _dayData!['workouts'] as List<dynamic>? ?? [];
    final runningData = _dayData!['runningData'];

    // 데이터가 모두 비어있는 경우
    if (habits.isEmpty && workouts.isEmpty && runningData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '이 날짜에는 기록된 활동이 없습니다.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 습관 섹션
          if (habits.isNotEmpty) ...[
            _buildSectionHeader('습관', Icons.check_circle, Colors.green),
            const SizedBox(height: 12),
            ...habits.map((habit) => _buildHabitCard(habit)),
            const SizedBox(height: 24),
          ],

          // 운동 섹션
          if (workouts.isNotEmpty || runningData != null) ...[
            _buildSectionHeader('운동', Icons.fitness_center, Colors.blue),
            const SizedBox(height: 12),
            ...workouts.map((workout) => _buildWorkoutCard(workout)),
            if (runningData != null) _buildRunningCard(runningData),
            const SizedBox(height: 24),
          ],

          // 식사 섹션 (미구현)
          _buildSectionHeader('식사', Icons.restaurant, Colors.orange),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '식사 기록 기능은 곧 추가될 예정입니다.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard(dynamic habit) {
    final bool isCompleted = habit['done'] ?? false;
    final String title = habit['title'] ?? '제목 없음';
    final String description = habit['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                isCompleted ? '완료' : '미완료',
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(dynamic workout) {
    final String title = workout['title'] ?? '제목 없음';
    final int duration = workout['duration'] ?? 0;
    final double calories = (workout['calories'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.fitness_center,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (duration > 0) ...[
                        Text(
                          '$duration분',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (calories > 0) ...[
                        Text(
                          '${calories.toInt()}kcal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningCard(dynamic runningData) {
    final double distance = (runningData['distance'] ?? 0).toDouble();
    final int duration = runningData['duration'] ?? 0;
    final double avgPace = (runningData['avgPace'] ?? 0).toDouble();
    final double calories = (runningData['calories'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RunningAnalysisPage(
                runningData: runningData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.directions_run,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '러닝',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (distance > 0) ...[
                          Text(
                            '${distance.toStringAsFixed(2)}km',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (duration > 0) ...[
                          Text(
                            '$duration분',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (avgPace > 0) ...[
                          Text(
                            '${avgPace.toStringAsFixed(1)}분/km',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (calories > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${calories.toInt()}kcal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.map,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
