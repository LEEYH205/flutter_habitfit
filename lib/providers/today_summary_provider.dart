import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import '../models/today_summary.dart';
import '../services/cache_service.dart';
import 'auth_provider.dart';

/// 오늘 요약 데이터 Provider (캐싱 적용)
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  const cacheKey = CacheKeys.todaySummary;

  // 캐시 비활성화 (디버깅용)
  print('🚨 디버깅: 캐시를 비활성화하고 항상 새로 로드합니다.');
  await CacheService.removeCache(cacheKey);

  // 캐시에 없으면 새로 로드
  print('🔄 Today 요약 데이터 새로 로드');
  print('🚀 ===== TodaySummaryProvider.build() 시작 =====');
  print('🚀 이 로그가 보이면 TodaySummaryProvider가 실행된 것입니다!');
  print('🚀 파일 경로: lib/providers/today_summary_provider.dart');

  // AuthProvider에서 현재 사용자 가져오기
  final authProvider = ref.read(authProviderProvider);
  final user = authProvider.user;
  if (user == null) {
    throw Exception('사용자가 로그인되지 않았습니다.');
  }

  final today = DateTime.now();
  final dateId = _getDateId(today);

  try {
    print('🔄 Firebase에서 Today 데이터 로드 시작...');
    // 오늘의 습관 완료 데이터 (타임아웃 5초)
    final habitsQuery = await FirebaseFirestore.instance
        .collection('habit_completions')
        .where('uid', isEqualTo: user.uid)
        .where('done', isEqualTo: true)
        .where('date', isEqualTo: dateId)
        .get()
        .timeout(const Duration(seconds: 5));

    // 오늘의 운동 데이터 (타임아웃 5초)
    final workoutsQuery = await FirebaseFirestore.instance
        .collection('workouts')
        .where('uid', isEqualTo: user.uid)
        .where('date', isEqualTo: dateId)
        .get()
        .timeout(const Duration(seconds: 5));

    // 사용자의 총 활성 습관 개수 (타임아웃 5초)
    final totalHabitsQuery = await FirebaseFirestore.instance
        .collection('user_habits')
        .where('uid', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .get()
        .timeout(const Duration(seconds: 5));

    // 오늘의 달리기 데이터 (HealthKit에서 가져오는 경우)
    final runningData = await _getTodayRunningData(today);

    print(
        '✅ Firebase 데이터 로드 성공: 습관 ${habitsQuery.docs.length}/${totalHabitsQuery.docs.length}, 운동 ${workoutsQuery.docs.length}개');

    final summary = TodaySummary(
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

    // 캐시에 저장 (5분간 유효)
    await CacheService.setCache(cacheKey, summary, expiry: CacheExpiry.short);

    return summary;
  } catch (e) {
    print('❌ Today 요약 데이터 로드 실패: $e');
    print('🔄 HealthKit 데이터로 fallback 시도...');

    try {
      // HealthKit에서 오늘의 데이터 가져오기
      final runningData = await _getTodayRunningData(today);

      // HealthKit 데이터를 기반으로 TodaySummary 생성
      final summary = TodaySummary(
        date: today,
        completedHabits: 0, // Firebase 연결 실패 시 0
        totalHabits: 0, // Firebase 연결 실패 시 0
        completedWorkouts: runningData['workoutCount'] ?? 0,
        runningDistance: runningData['distance'] ?? 0.0,
        runningDuration: runningData['duration'] ?? 0,
        calories: runningData['calories'] ?? 0.0,
        protein: 0.0, // TODO: 식사 데이터 연동 시 실제 계산
        steps: _getTodaySteps(), // TODO: HealthKit 연동 시 실제 데이터
        habitCompletionRate: 0.0, // Firebase 연결 실패 시 0
      );

      print('✅ HealthKit 데이터로 Today 요약 생성 완료');
      return summary;
    } catch (healthKitError) {
      print('❌ HealthKit 데이터 로드도 실패: $healthKitError');

      // 모든 데이터 로드 실패 시 기본값 반환
      final summary = TodaySummary(
        date: today,
        completedHabits: 0,
        totalHabits: 0,
        completedWorkouts: 0,
        runningDistance: 0.0,
        runningDuration: 0,
        calories: 0.0,
        protein: 0.0,
        steps: 0,
        habitCompletionRate: 0.0,
      );

      return summary;
    }
  }
});

/// 오늘의 달리기 데이터 가져오기 (HealthKit 연동)
Future<Map<String, dynamic>> _getTodayRunningData(DateTime today) async {
  try {
    print('🔄 HealthKit에서 오늘의 운동 데이터 로드 시작...');

    // HealthKit에서 오늘의 운동 데이터 가져오기
    final healthFactory = HealthFactory();

    // 오늘의 시작과 끝 시간 설정
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print('📅 조회 기간: $startOfDay ~ $endOfDay');

    // 운동 데이터 조회
    final workouts = await healthFactory.getHealthDataFromTypes(
      startOfDay,
      endOfDay,
      [HealthDataType.WORKOUT],
    );

    print('🏃‍♂️ HealthKit에서 ${workouts.length}개 운동 데이터 조회됨');

    // 오늘의 달리기 데이터 계산
    double totalDistance = 0.0;
    int totalDuration = 0;
    double totalCalories = 0.0;
    int workoutCount = 0;

    for (final workout in workouts) {
      if (workout.type == HealthDataType.WORKOUT) {
        // 운동 시간 계산
        final startTime = workout.dateFrom;
        final endTime = workout.dateTo;
        totalDuration += endTime.difference(startTime).inMinutes;

        // HealthKit에서 운동 데이터는 이미 파싱된 형태로 제공됨
        // 실제 운동 데이터는 Journal 페이지에서 로드된 것을 참고
        workoutCount++;

        // 기본값 설정 (실제 데이터는 Journal 페이지에서 가져옴)
        totalDistance += 5.0; // 기본값
        totalCalories += 300.0; // 기본값
      }
    }

    print(
        '📊 오늘의 HealthKit 데이터: 거리 ${totalDistance.toStringAsFixed(2)}km, 시간 $totalDuration분, 칼로리 ${totalCalories.toStringAsFixed(1)}kcal, 운동 $workoutCount개');

    // 오늘 운동 데이터가 없으면 기본값 제공
    if (workoutCount == 0) {
      print('⚠️ 오늘 운동 데이터가 없습니다. 기본 통계값을 제공합니다.');
      return {
        'distance': 0.0,
        'duration': 0,
        'calories': 0.0,
        'workoutCount': 0,
      };
    }

    return {
      'distance': totalDistance,
      'duration': totalDuration,
      'calories': totalCalories,
      'workoutCount': workoutCount,
    };
  } catch (e) {
    print('❌ HealthKit 데이터 로드 실패: $e');
    return {
      'distance': 0.0,
      'duration': 0,
      'calories': 0.0,
      'workoutCount': 0,
    };
  }
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

/// 오늘 요약 데이터 새로고침 Provider (캐시 무효화)
final todaySummaryRefreshProvider = Provider<void Function()>((ref) {
  return () async {
    // 캐시 삭제
    await CacheService.removeCache(CacheKeys.todaySummary);
    // Provider 무효화
    ref.invalidate(todaySummaryProvider);
  };
});
