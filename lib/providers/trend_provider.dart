import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trend_data.dart';

/// 트렌드 데이터 Provider (주/월/범위별 분석)
final trendProvider = FutureProvider.family<TrendData, TrendRange>((ref, range) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('사용자가 로그인되지 않았습니다.');
  }

  final now = DateTime.now();
  final startDate = _getStartDate(now, range);
  final endDate = now;

  // 습관 완료 데이터
  final habitsQuery = await FirebaseFirestore.instance
      .collection('habit_completions')
      .where('uid', isEqualTo: user.uid)
      .where('done', isEqualTo: true)
      .where('date', isGreaterThanOrEqualTo: _getDateId(startDate))
      .where('date', isLessThanOrEqualTo: _getDateId(endDate))
      .get();

  // 운동 데이터
  final workoutsQuery = await FirebaseFirestore.instance
      .collection('workouts')
      .where('uid', isEqualTo: user.uid)
      .where('date', isGreaterThanOrEqualTo: _getDateId(startDate))
      .where('date', isLessThanOrEqualTo: _getDateId(endDate))
      .get();

  // 사용자의 총 활성 습관 개수
  final totalHabitsQuery = await FirebaseFirestore.instance
      .collection('user_habits')
      .where('uid', isEqualTo: user.uid)
      .where('isActive', isEqualTo: true)
      .get();

  return TrendData(
    range: range,
    startDate: startDate,
    endDate: endDate,
    totalHabits: totalHabitsQuery.docs.length,
    completedHabits: habitsQuery.docs.length,
    completedWorkouts: workoutsQuery.docs.length,
    habits: habitsQuery.docs.map((doc) => doc.data()).toList(),
    workouts: workoutsQuery.docs.map((doc) => doc.data()).toList(),
  );
});

// TrendRange enum은 trend_data.dart에서 import

/// 트렌드 범위에 따른 시작 날짜 계산
DateTime _getStartDate(DateTime now, TrendRange range) {
  switch (range) {
    case TrendRange.week7:
      return now.subtract(const Duration(days: 7));
    case TrendRange.week14:
      return now.subtract(const Duration(days: 14));
    case TrendRange.month30:
      return now.subtract(const Duration(days: 30));
    case TrendRange.month90:
      return now.subtract(const Duration(days: 90));
    case TrendRange.custom:
      return now.subtract(const Duration(days: 30)); // 기본값
  }
}

/// 트렌드 범위 표시 이름
String getTrendRangeName(TrendRange range) {
  switch (range) {
    case TrendRange.week7:
      return '최근 7일';
    case TrendRange.week14:
      return '최근 14일';
    case TrendRange.month30:
      return '최근 30일';
    case TrendRange.month90:
      return '최근 90일';
    case TrendRange.custom:
      return '사용자 정의';
  }
}

/// 트렌드 데이터 새로고침 Provider
final trendRefreshProvider = Provider<void Function(TrendRange)>((ref) {
  return (range) {
    ref.invalidate(trendProvider(range));
  };
});

/// 특정 트렌드 범위의 습관 완료율 Provider
final habitCompletionRateProvider = FutureProvider.family<double, TrendRange>((ref, range) async {
  final trendData = await ref.watch(trendProvider(range).future);
  return trendData.habitCompletionRate;
});

/// 특정 트렌드 범위의 운동 완료율 Provider
final workoutCompletionRateProvider = FutureProvider.family<double, TrendRange>((ref, range) async {
  final trendData = await ref.watch(trendProvider(range).future);
  return trendData.workoutCompletionRate;
});

/// 특정 트렌드 범위의 일관성 점수 Provider
final consistencyScoreProvider = FutureProvider.family<double, TrendRange>((ref, range) async {
  final trendData = await ref.watch(trendProvider(range).future);
  return trendData.consistencyScore;
});

/// 날짜 ID 생성 (YYYY-MM-DD 형식)
String _getDateId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
