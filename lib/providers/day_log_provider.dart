import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/day_log.dart';

/// 특정 날짜의 로그 데이터 Provider
final dayLogProvider = FutureProvider.family<DayLog, DateTime>((ref, date) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('사용자가 로그인되지 않았습니다.');
  }

  final dateId = _getDateId(date);
  
  // 해당 날짜의 습관 완료 데이터
  final habitsQuery = await FirebaseFirestore.instance
      .collection('habit_completions')
      .where('uid', isEqualTo: user.uid)
      .where('done', isEqualTo: true)
      .where('date', isEqualTo: dateId)
      .get();

  // 해당 날짜의 운동 데이터
  final workoutsQuery = await FirebaseFirestore.instance
      .collection('workouts')
      .where('uid', isEqualTo: user.uid)
      .where('date', isEqualTo: dateId)
      .get();

  // 해당 날짜의 달리기 데이터 (HealthKit에서 가져오는 경우)
  final runningData = await _getDayRunningData(date);

  // 해당 날짜의 식사 데이터 (미구현)
  final mealsData = await _getDayMealsData(date);

  return DayLog(
    date: date,
    habits: habitsQuery.docs.map((doc) => doc.data()).toList(),
    workouts: workoutsQuery.docs.map((doc) => doc.data()).toList(),
    runningData: runningData,
    meals: mealsData,
  );
});

/// 특정 날짜의 달리기 데이터 가져오기
Future<Map<String, dynamic>?> _getDayRunningData(DateTime date) async {
  // TODO: HealthKit에서 해당 날짜의 달리기 데이터 가져오기
  return null;
}

/// 특정 날짜의 식사 데이터 가져오기
Future<List<Map<String, dynamic>>> _getDayMealsData(DateTime date) async {
  // TODO: 식사 데이터 연동 시 실제 구현
  return [];
}

/// 날짜 ID 생성 (YYYY-MM-DD 형식)
String _getDateId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// 특정 날짜 로그 데이터 새로고침 Provider
final dayLogRefreshProvider = Provider<void Function(DateTime)>((ref) {
  return (date) {
    ref.invalidate(dayLogProvider(date));
  };
});
