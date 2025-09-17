import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/running_coach.dart';

/// 러닝 코치 서비스
class RunningCoachService {
  static final RunningCoachService _instance = RunningCoachService._internal();
  factory RunningCoachService() => _instance;
  RunningCoachService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _eventsCollection = 'running_events';
  static const String _settingsCollection = 'running_coach_settings';
  static const String _plansCollection = 'training_plans';

  /// 러닝 이벤트 생성
  Future<String?> createRunningEvent({
    required String name,
    required DateTime eventDate,
    required double targetDistance,
    required Duration targetTime,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final eventId = _firestore.collection(_eventsCollection).doc().id;

      final event = RunningEvent(
        id: eventId,
        userId: user.uid,
        name: name,
        eventDate: eventDate,
        targetDistance: targetDistance,
        targetTime: targetTime,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .set(event.toMap());

      print('✅ 러닝 이벤트 생성 완료: $name');
      return eventId;
    } catch (e) {
      print('❌ 러닝 이벤트 생성 오류: $e');
      return null;
    }
  }

  /// 사용자의 러닝 이벤트 목록 조회
  Future<List<RunningEvent>> getUserRunningEvents() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection(_eventsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('eventDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RunningEvent.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 러닝 이벤트 목록 조회 오류: $e');
      return [];
    }
  }

  /// 러닝 코치 설정 저장/업데이트
  Future<bool> saveCoachSettings({
    required Duration averagePace,
    required List<int> runningDays,
    required List<int> lsdDays,
    required int weeklyRunningDays,
    required int weeklyLsdDays,
    required double currentWeeklyDistance,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final settingsId = user.uid; // 사용자당 하나의 설정

      // 기존 설정 조회
      final existingDoc = await _firestore
          .collection(_settingsCollection)
          .doc(settingsId)
          .get();

      final settings = RunningCoachSettings(
        id: settingsId,
        userId: user.uid,
        averagePace: averagePace,
        runningDays: runningDays,
        lsdDays: lsdDays,
        weeklyRunningDays: weeklyRunningDays,
        weeklyLsdDays: weeklyLsdDays,
        currentWeeklyDistance: currentWeeklyDistance,
        createdAt: existingDoc.exists
            ? RunningCoachSettings.fromMap(existingDoc.data()!).createdAt
            : now,
        updatedAt: now,
      );

      await _firestore
          .collection(_settingsCollection)
          .doc(settingsId)
          .set(settings.toMap());

      print('✅ 러닝 코치 설정 저장 완료');
      return true;
    } catch (e) {
      print('❌ 러닝 코치 설정 저장 오류: $e');
      return false;
    }
  }

  /// 러닝 코치 설정 조회
  Future<RunningCoachSettings?> getCoachSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection(_settingsCollection).doc(user.uid).get();

      if (doc.exists) {
        return RunningCoachSettings.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 러닝 코치 설정 조회 오류: $e');
      return null;
    }
  }

  /// 훈련 계획 생성
  Future<TrainingPlan?> generateTrainingPlan({
    required String eventId,
    required RunningEvent event,
    required RunningCoachSettings settings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final planId = _firestore.collection(_plansCollection).doc().id;

      // 훈련 기간 계산 (이벤트 날짜까지의 주 수)
      final weeksUntilEvent = event.eventDate.difference(now).inDays ~/ 7;
      final trainingWeeks =
          math.max(4, math.min(weeksUntilEvent - 1, 20)); // 최소 4주, 최대 20주

      final startDate = now;
      final endDate =
          event.eventDate.subtract(const Duration(days: 7)); // 이벤트 1주 전까지

      // 주간 계획 생성
      final weeklyPlans = _generateWeeklyPlans(
        trainingWeeks: trainingWeeks,
        startDate: startDate,
        event: event,
        settings: settings,
      );

      final trainingPlan = TrainingPlan(
        id: planId,
        userId: user.uid,
        eventId: eventId,
        startDate: startDate,
        endDate: endDate,
        totalWeeks: trainingWeeks,
        weeklyPlans: weeklyPlans,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_plansCollection)
          .doc(planId)
          .set(trainingPlan.toMap());

      print('✅ 훈련 계획 생성 완료: $trainingWeeks주 계획');
      return trainingPlan;
    } catch (e) {
      print('❌ 훈련 계획 생성 오류: $e');
      return null;
    }
  }

  /// 주간 훈련 계획 생성 (핵심 알고리즘)
  List<WeeklyPlan> _generateWeeklyPlans({
    required int trainingWeeks,
    required DateTime startDate,
    required RunningEvent event,
    required RunningCoachSettings settings,
  }) {
    final weeklyPlans = <WeeklyPlan>[];
    final baseWeeklyDistance = settings.currentWeeklyDistance;

    for (int week = 1; week <= trainingWeeks; week++) {
      final weekStartDate = startDate.add(Duration(days: (week - 1) * 7));
      final weekEndDate = weekStartDate.add(const Duration(days: 6));

      // 훈련 단계 결정
      final phase = _getTrainingPhase(week, trainingWeeks);
      final weeklyDistance = _calculateWeeklyDistance(
        week: week,
        totalWeeks: trainingWeeks,
        baseDistance: baseWeeklyDistance,
        targetDistance: event.targetDistance,
      );

      // 일일 운동 계획 생성
      final dailyWorkouts = _generateDailyWorkouts(
        weekStartDate: weekStartDate,
        phase: phase,
        weeklyDistance: weeklyDistance,
        settings: settings,
        event: event,
        weekNumber: week,
        totalWeeks: trainingWeeks,
      );

      weeklyPlans.add(WeeklyPlan(
        weekNumber: week,
        startDate: weekStartDate,
        endDate: weekEndDate,
        totalDistance: weeklyDistance,
        dailyWorkouts: dailyWorkouts,
        focus: _getWeeklyFocus(phase, week, trainingWeeks),
      ));
    }

    return weeklyPlans;
  }

  /// 훈련 단계 결정
  String _getTrainingPhase(int week, int totalWeeks) {
    final progress = week / totalWeeks;

    if (progress <= 0.3) {
      return 'base'; // 기초 체력 단계 (첫 30%)
    } else if (progress <= 0.7) {
      return 'build'; // 체력 향상 단계 (30-70%)
    } else if (progress <= 0.9) {
      return 'peak'; // 최고 강도 단계 (70-90%)
    } else {
      return 'taper'; // 테이퍼링 단계 (마지막 10%)
    }
  }

  /// 주간 거리 계산
  double _calculateWeeklyDistance({
    required int week,
    required int totalWeeks,
    required double baseDistance,
    required double targetDistance,
  }) {
    final progress = week / totalWeeks;

    if (progress <= 0.3) {
      // 기초 단계: 점진적 증가
      return baseDistance * (1.0 + progress * 0.5);
    } else if (progress <= 0.7) {
      // 체력 향상 단계: 최대 거리
      final peakDistance = math.max(baseDistance * 1.8, targetDistance * 1.2);
      return peakDistance;
    } else if (progress <= 0.9) {
      // 최고 강도 단계: 약간 감소하되 질적 향상
      final peakDistance = math.max(baseDistance * 1.8, targetDistance * 1.2);
      return peakDistance * 0.9;
    } else {
      // 테이퍼링: 대폭 감소
      return baseDistance * 0.6;
    }
  }

  /// 일일 운동 계획 생성
  List<DailyWorkout> _generateDailyWorkouts({
    required DateTime weekStartDate,
    required String phase,
    required double weeklyDistance,
    required RunningCoachSettings settings,
    required RunningEvent event,
    required int weekNumber,
    required int totalWeeks,
  }) {
    final dailyWorkouts = <DailyWorkout>[];
    final availableRunningDays = List<int>.from(settings.runningDays);
    final availableLsdDays = List<int>.from(settings.lsdDays);

    // 7일간 계획 생성
    for (int day = 0; day < 7; day++) {
      final currentDate = weekStartDate.add(Duration(days: day));
      final dayOfWeek = currentDate.weekday % 7; // 0=일요일, 1=월요일, ...

      final workout = _generateDailyWorkout(
        date: currentDate,
        dayOfWeek: dayOfWeek,
        phase: phase,
        weeklyDistance: weeklyDistance,
        settings: settings,
        event: event,
        availableRunningDays: availableRunningDays,
        availableLsdDays: availableLsdDays,
        weekNumber: weekNumber,
        totalWeeks: totalWeeks,
      );

      dailyWorkouts.add(workout);
    }

    return dailyWorkouts;
  }

  /// 개별 일일 운동 생성
  DailyWorkout _generateDailyWorkout({
    required DateTime date,
    required int dayOfWeek,
    required String phase,
    required double weeklyDistance,
    required RunningCoachSettings settings,
    required RunningEvent event,
    required List<int> availableRunningDays,
    required List<int> availableLsdDays,
    required int weekNumber,
    required int totalWeeks,
  }) {
    // 해당 요일에 운동 가능한지 확인
    final canRun = availableRunningDays.contains(dayOfWeek);
    final canLsd = availableLsdDays.contains(dayOfWeek);

    if (!canRun) {
      return DailyWorkout(
        date: date,
        type: TrainingType.rest,
        description: '완전 휴식일',
      );
    }

    // 훈련 타입과 거리 결정
    final trainingType = _selectTrainingType(
      phase: phase,
      dayOfWeek: dayOfWeek,
      canLsd: canLsd,
      weekNumber: weekNumber,
      totalWeeks: totalWeeks,
    );

    final distance = _calculateDailyDistance(
      trainingType: trainingType,
      weeklyDistance: weeklyDistance,
      settings: settings,
      event: event,
    );

    final targetPace = _calculateTargetPace(
      trainingType: trainingType,
      settings: settings,
      event: event,
    );

    final description = _generateWorkoutDescription(
      trainingType: trainingType,
      distance: distance,
      targetPace: targetPace,
    );

    return DailyWorkout(
      date: date,
      type: trainingType,
      distance: distance,
      targetPace: targetPace,
      description: description,
      intervals: trainingType == TrainingType.interval ||
              trainingType == TrainingType.vo2max
          ? _generateIntervals(trainingType, distance, targetPace)
          : null,
    );
  }

  /// 훈련 타입 선택
  TrainingType _selectTrainingType({
    required String phase,
    required int dayOfWeek,
    required bool canLsd,
    required int weekNumber,
    required int totalWeeks,
  }) {
    switch (phase) {
      case 'base':
        if (canLsd && dayOfWeek == 6) {
          // 토요일 LSD
          return TrainingType.lsd;
        }
        return weekNumber % 2 == 0 ? TrainingType.base : TrainingType.zone2;

      case 'build':
        if (canLsd && dayOfWeek == 6) {
          return TrainingType.lsd;
        }
        if (dayOfWeek == 2) {
          // 화요일 템포런
          return TrainingType.tempo;
        }
        if (dayOfWeek == 4) {
          // 목요일 인터벌
          return TrainingType.interval;
        }
        return TrainingType.base;

      case 'peak':
        if (canLsd && dayOfWeek == 6) {
          return TrainingType.lsd;
        }
        if (dayOfWeek == 2) {
          // 화요일 VO2 Max
          return TrainingType.vo2max;
        }
        if (dayOfWeek == 4) {
          // 목요일 템포런
          return TrainingType.tempo;
        }
        return TrainingType.recovery;

      case 'taper':
        if (dayOfWeek == 2) {
          // 가벼운 템포런
          return TrainingType.tempo;
        }
        return TrainingType.recovery;

      default:
        return TrainingType.base;
    }
  }

  /// 일일 거리 계산
  double _calculateDailyDistance({
    required TrainingType trainingType,
    required double weeklyDistance,
    required RunningCoachSettings settings,
    required RunningEvent event,
  }) {
    switch (trainingType) {
      case TrainingType.rest:
        return 0.0;
      case TrainingType.recovery:
        return math.max(3.0, weeklyDistance * 0.15);
      case TrainingType.base:
        return math.max(5.0, weeklyDistance * 0.25);
      case TrainingType.zone2:
        return math.max(6.0, weeklyDistance * 0.3);
      case TrainingType.lsd:
        return math.max(10.0, weeklyDistance * 0.4);
      case TrainingType.tempo:
        return math.max(8.0, weeklyDistance * 0.25);
      case TrainingType.interval:
        return math.max(6.0, weeklyDistance * 0.2);
      case TrainingType.vo2max:
        return math.max(5.0, weeklyDistance * 0.15);
    }
  }

  /// 목표 페이스 계산
  Duration _calculateTargetPace({
    required TrainingType trainingType,
    required RunningCoachSettings settings,
    required RunningEvent event,
  }) {
    final basePace = settings.averagePace;
    final targetPace = event.targetPace;

    switch (trainingType) {
      case TrainingType.rest:
        return Duration.zero;
      case TrainingType.recovery:
        return Duration(seconds: (basePace.inSeconds * 1.2).round());
      case TrainingType.base:
        return Duration(seconds: (basePace.inSeconds * 1.1).round());
      case TrainingType.zone2:
        return basePace;
      case TrainingType.lsd:
        return Duration(seconds: (basePace.inSeconds * 1.15).round());
      case TrainingType.tempo:
        return Duration(
            seconds: ((basePace.inSeconds + targetPace.inSeconds) / 2).round());
      case TrainingType.interval:
        return Duration(seconds: (targetPace.inSeconds * 0.95).round());
      case TrainingType.vo2max:
        return Duration(seconds: (targetPace.inSeconds * 0.9).round());
    }
  }

  /// 운동 설명 생성
  String _generateWorkoutDescription({
    required TrainingType trainingType,
    required double distance,
    required Duration targetPace,
  }) {
    final paceStr = targetPace != Duration.zero
        ? '${targetPace.inMinutes}:${(targetPace.inSeconds % 60).toString().padLeft(2, '0')}/km'
        : '';

    switch (trainingType) {
      case TrainingType.rest:
        return '완전 휴식 - 몸의 회복에 집중하세요';
      case TrainingType.recovery:
        return '회복 러닝 ${distance.toStringAsFixed(1)}km - 편안한 페이스 ($paceStr)로 가볍게';
      case TrainingType.base:
        return '기초 체력 러닝 ${distance.toStringAsFixed(1)}km - 대화 가능한 강도 ($paceStr)';
      case TrainingType.zone2:
        return '존2 러닝 ${distance.toStringAsFixed(1)}km - 유산소 기반 체력 향상 ($paceStr)';
      case TrainingType.lsd:
        return 'LSD ${distance.toStringAsFixed(1)}km - 장거리 저강도 러닝 ($paceStr)';
      case TrainingType.tempo:
        return '템포런 ${distance.toStringAsFixed(1)}km - 젖산 역치 개선 ($paceStr)';
      case TrainingType.interval:
        return '인터벌 훈련 ${distance.toStringAsFixed(1)}km - 속도 향상 훈련 ($paceStr)';
      case TrainingType.vo2max:
        return 'VO2 Max ${distance.toStringAsFixed(1)}km - 최대 산소 섭취량 향상 ($paceStr)';
    }
  }

  /// 인터벌 훈련 구성 생성
  List<WorkoutInterval> _generateIntervals(
      TrainingType type, double totalDistance, Duration targetPace) {
    switch (type) {
      case TrainingType.interval:
        // 1km x 4회 인터벌
        return [
          WorkoutInterval(
            distance: 1.0,
            targetTime: Duration(seconds: targetPace.inSeconds),
            restTime: const Duration(minutes: 2),
            repetitions: math.min(4, (totalDistance / 1.5).round()),
          ),
        ];
      case TrainingType.vo2max:
        // 400m x 8회 인터벌
        return [
          WorkoutInterval(
            distance: 0.4,
            targetTime: Duration(seconds: (targetPace.inSeconds * 0.4).round()),
            restTime: const Duration(minutes: 1, seconds: 30),
            repetitions: math.min(8, (totalDistance / 0.6).round()),
          ),
        ];
      default:
        return [];
    }
  }

  /// 주간 포커스 설명
  String _getWeeklyFocus(String phase, int week, int totalWeeks) {
    switch (phase) {
      case 'base':
        return '기초 체력 양성 - 편안한 페이스로 러닝 습관 형성';
      case 'build':
        return '체력 향상 - 템포런과 인터벌로 속도와 지구력 개선';
      case 'peak':
        return '최고 강도 - VO2 Max와 고강도 훈련으로 경기력 극대화';
      case 'taper':
        return '테이퍼링 - 회복과 컨디션 조절로 이벤트 준비';
      default:
        return '훈련 계획 진행 중';
    }
  }

  /// 사용자의 훈련 계획 조회
  Future<List<TrainingPlan>> getUserTrainingPlans() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection(_plansCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TrainingPlan.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 훈련 계획 목록 조회 오류: $e');
      return [];
    }
  }

  /// 특정 훈련 계획 조회
  Future<TrainingPlan?> getTrainingPlan(String planId) async {
    try {
      final doc =
          await _firestore.collection(_plansCollection).doc(planId).get();

      if (doc.exists) {
        return TrainingPlan.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 훈련 계획 조회 오류: $e');
      return null;
    }
  }

  /// 특정 러닝 이벤트 조회
  Future<RunningEvent?> getRunningEvent(String eventId) async {
    try {
      final doc =
          await _firestore.collection(_eventsCollection).doc(eventId).get();

      if (doc.exists) {
        return RunningEvent.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 러닝 이벤트 조회 오류: $e');
      return null;
    }
  }

  /// 훈련 계획 삭제
  Future<bool> deleteTrainingPlan(String planId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 훈련 계획이 존재하는지 확인
      final plan = await getTrainingPlan(planId);
      if (plan == null || plan.userId != user.uid) {
        print('❌ 훈련 계획을 찾을 수 없거나 권한이 없습니다');
        return false;
      }

      // 훈련 계획 삭제
      await _firestore.collection(_plansCollection).doc(planId).delete();

      print('✅ 훈련 계획 삭제 완료: $planId');
      return true;
    } catch (e) {
      print('❌ 훈련 계획 삭제 오류: $e');
      return false;
    }
  }

  /// 러닝 이벤트 삭제
  Future<bool> deleteRunningEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 이벤트가 존재하는지 확인
      final event = await getRunningEvent(eventId);
      if (event == null || event.userId != user.uid) {
        print('❌ 러닝 이벤트를 찾을 수 없거나 권한이 없습니다');
        return false;
      }

      // 관련된 훈련 계획들도 함께 삭제
      final relatedPlans = await getUserTrainingPlans();
      final plansToDelete = relatedPlans.where((plan) => plan.eventId == eventId).toList();
      
      // 배치 삭제
      final batch = _firestore.batch();
      
      // 이벤트 삭제
      batch.delete(_firestore.collection(_eventsCollection).doc(eventId));
      
      // 관련 훈련 계획들 삭제
      for (final plan in plansToDelete) {
        batch.delete(_firestore.collection(_plansCollection).doc(plan.id));
      }
      
      await batch.commit();

      print('✅ 러닝 이벤트 및 관련 훈련 계획 삭제 완료: $eventId (${plansToDelete.length}개 계획)');
      return true;
    } catch (e) {
      print('❌ 러닝 이벤트 삭제 오류: $e');
      return false;
    }
  }
}
