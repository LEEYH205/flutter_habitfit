import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/today_summary.dart';

/// 오늘 요약 데이터 Provider
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('사용자가 로그인되지 않았습니다.');
  }

  final today = DateTime.now();
  final dateId = _getDateId(today);

  // 오늘의 습관 완료 데이터
  final habitsQuery = await FirebaseFirestore.instance
      .collection('habit_completions')
      .where('uid', isEqualTo: user.uid)
      .where('done', isEqualTo: true)
      .where('date', isEqualTo: dateId)
      .get();

  // 오늘의 운동 데이터
  final workoutsQuery = await FirebaseFirestore.instance
      .collection('workouts')
      .where('uid', isEqualTo: user.uid)
      .where('date', isEqualTo: dateId)
      .get();

  // 사용자의 총 활성 습관 개수
  final totalHabitsQuery = await FirebaseFirestore.instance
      .collection('user_habits')
      .where('uid', isEqualTo: user.uid)
      .where('isActive', isEqualTo: true)
      .get();

  // 오늘의 달리기 데이터 (HealthKit에서 가져오는 경우)
  // TODO: HealthKit 연동 시 실제 데이터로 교체
  final runningData = await _getTodayRunningData(today);

  return TodaySummary(
    date: today,
    completedHabits: habitsQuery.docs.length,
    totalHabits: totalHabitsQuery.docs.length,
    completedWorkouts: workoutsQuery.docs.length,
    runningDistance: runningData['distance'] ?? 0.0,
    runningDuration: runningData['duration'] ?? 0,
    calories: _calculateTodayCalories(workoutsQuery.docs, runningData),
    protein: _calculateTodayProtein(), // TODO: 식사 데이터 연동 시 실제 계산
    steps: _getTodaySteps(), // TODO: HealthKit 연동 시 실제 데이터
    habitCompletionRate: totalHabitsQuery.docs.isNotEmpty
        ? (habitsQuery.docs.length / totalHabitsQuery.docs.length) * 100
        : 0.0,
  );
});

/// 오늘의 달리기 데이터 가져오기 (HealthKit 연동 예정)
Future<Map<String, dynamic>> _getTodayRunningData(DateTime today) async {
  // TODO: HealthKit에서 오늘의 달리기 데이터 가져오기
  return {
    'distance': 0.0,
    'duration': 0,
    'calories': 0.0,
  };
}

/// 오늘의 칼로리 계산
double _calculateTodayCalories(
    List<QueryDocumentSnapshot> workouts, Map<String, dynamic> runningData) {
  double totalCalories = 0.0;

  // 운동에서 칼로리 합계
  for (final workout in workouts) {
    final data = workout.data() as Map<String, dynamic>;
    totalCalories += (data['calories'] ?? 0).toDouble();
  }

  // 달리기 칼로리 추가
  totalCalories += (runningData['calories'] ?? 0).toDouble();

  return totalCalories;
}

/// 오늘의 단백질 계산 (식사 데이터 연동 예정)
double _calculateTodayProtein() {
  // TODO: 식사 데이터에서 단백질 계산
  return 0.0;
}

/// 오늘의 걸음 수 가져오기 (HealthKit 연동 예정)
int _getTodaySteps() {
  // TODO: HealthKit에서 걸음 수 가져오기
  return 0;
}

/// 날짜 ID 생성 (YYYY-MM-DD 형식)
String _getDateId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// 오늘 요약 데이터 새로고침 Provider
final todaySummaryRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(todaySummaryProvider);
  };
});
