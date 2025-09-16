import 'package:cloud_firestore/cloud_firestore.dart';

/// 러닝 훈련 타입
enum TrainingType {
  base('기초체력', '기초 체력 양성을 위한 편안한 러닝'),
  zone2('존2', '유산소 기반 체력 향상을 위한 중강도 러닝'),
  lsd('LSD', '장거리 저강도 러닝 (Long Slow Distance)'),
  vo2max('VO2 Max', '최대 산소 섭취량 향상을 위한 고강도 인터벌'),
  tempo('템포런', '젖산 역치 개선을 위한 템포 러닝'),
  interval('인터벌', '속도 향상을 위한 인터벌 훈련'),
  recovery('회복', '회복을 위한 가벼운 조깅'),
  rest('휴식', '완전 휴식');

  const TrainingType(this.displayName, this.description);
  final String displayName;
  final String description;

  /// 훈련 강도 (1-10)
  int get intensity {
    switch (this) {
      case TrainingType.rest:
        return 0;
      case TrainingType.recovery:
        return 2;
      case TrainingType.base:
        return 4;
      case TrainingType.lsd:
        return 4;
      case TrainingType.zone2:
        return 6;
      case TrainingType.tempo:
        return 7;
      case TrainingType.interval:
        return 8;
      case TrainingType.vo2max:
        return 9;
    }
  }

  /// 훈련 타입별 색상
  int get colorValue {
    switch (this) {
      case TrainingType.rest:
        return 0xFF9E9E9E; // 회색
      case TrainingType.recovery:
        return 0xFF4CAF50; // 초록
      case TrainingType.base:
        return 0xFF2196F3; // 파랑
      case TrainingType.lsd:
        return 0xFF00BCD4; // 청록
      case TrainingType.zone2:
        return 0xFFFF9800; // 주황
      case TrainingType.tempo:
        return 0xFFFF5722; // 빨강-주황
      case TrainingType.interval:
        return 0xFFE91E63; // 핑크
      case TrainingType.vo2max:
        return 0xFF9C27B0; // 보라
    }
  }
}

/// 러닝 이벤트 정보
class RunningEvent {
  final String id;
  final String userId;
  final String name;
  final DateTime eventDate;
  final double targetDistance; // km
  final Duration targetTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RunningEvent({
    required this.id,
    required this.userId,
    required this.name,
    required this.eventDate,
    required this.targetDistance,
    required this.targetTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 목표 페이스 (분/km)
  Duration get targetPace {
    final totalMinutes = targetTime.inMinutes;
    final paceMinutes = totalMinutes / targetDistance;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return Duration(minutes: minutes, seconds: seconds);
  }

  /// 목표 속도 (km/h)
  double get targetSpeed {
    return targetDistance / (targetTime.inMinutes / 60.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'eventDate': eventDate.toIso8601String(),
      'targetDistance': targetDistance,
      'targetTimeMinutes': targetTime.inMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RunningEvent.fromMap(Map<String, dynamic> map) {
    return RunningEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      eventDate: DateTime.parse(map['eventDate']),
      targetDistance: (map['targetDistance'] ?? 0.0).toDouble(),
      targetTime: Duration(minutes: map['targetTimeMinutes'] ?? 0),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  RunningEvent copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? eventDate,
    double? targetDistance,
    Duration? targetTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RunningEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      eventDate: eventDate ?? this.eventDate,
      targetDistance: targetDistance ?? this.targetDistance,
      targetTime: targetTime ?? this.targetTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 러닝 코치 설정
class RunningCoachSettings {
  final String id;
  final String userId;
  final Duration averagePace; // 현재 평균 페이스
  final List<int> runningDays; // 러닝 가능 요일 (0=일요일, 1=월요일, ...)
  final List<int> lsdDays; // LSD 가능 요일
  final int weeklyRunningDays; // 주간 러닝 일수
  final int weeklyLsdDays; // 주간 LSD 일수
  final double currentWeeklyDistance; // 현재 주간 거리 (km)
  final DateTime createdAt;
  final DateTime updatedAt;

  const RunningCoachSettings({
    required this.id,
    required this.userId,
    required this.averagePace,
    required this.runningDays,
    required this.lsdDays,
    required this.weeklyRunningDays,
    required this.weeklyLsdDays,
    required this.currentWeeklyDistance,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'averagePaceMinutes': averagePace.inMinutes,
      'averagePaceSeconds': averagePace.inSeconds % 60,
      'runningDays': runningDays,
      'lsdDays': lsdDays,
      'weeklyRunningDays': weeklyRunningDays,
      'weeklyLsdDays': weeklyLsdDays,
      'currentWeeklyDistance': currentWeeklyDistance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RunningCoachSettings.fromMap(Map<String, dynamic> map) {
    final paceMinutes = map['averagePaceMinutes'] ?? 0;
    final paceSeconds = map['averagePaceSeconds'] ?? 0;
    
    return RunningCoachSettings(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      averagePace: Duration(minutes: paceMinutes, seconds: paceSeconds),
      runningDays: List<int>.from(map['runningDays'] ?? []),
      lsdDays: List<int>.from(map['lsdDays'] ?? []),
      weeklyRunningDays: map['weeklyRunningDays'] ?? 3,
      weeklyLsdDays: map['weeklyLsdDays'] ?? 1,
      currentWeeklyDistance: (map['currentWeeklyDistance'] ?? 0.0).toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  RunningCoachSettings copyWith({
    String? id,
    String? userId,
    Duration? averagePace,
    List<int>? runningDays,
    List<int>? lsdDays,
    int? weeklyRunningDays,
    int? weeklyLsdDays,
    double? currentWeeklyDistance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RunningCoachSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      averagePace: averagePace ?? this.averagePace,
      runningDays: runningDays ?? this.runningDays,
      lsdDays: lsdDays ?? this.lsdDays,
      weeklyRunningDays: weeklyRunningDays ?? this.weeklyRunningDays,
      weeklyLsdDays: weeklyLsdDays ?? this.weeklyLsdDays,
      currentWeeklyDistance: currentWeeklyDistance ?? this.currentWeeklyDistance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 훈련 계획
class TrainingPlan {
  final String id;
  final String userId;
  final String eventId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalWeeks;
  final List<WeeklyPlan> weeklyPlans;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrainingPlan({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.startDate,
    required this.endDate,
    required this.totalWeeks,
    required this.weeklyPlans,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalWeeks': totalWeeks,
      'weeklyPlans': weeklyPlans.map((plan) => plan.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    return TrainingPlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalWeeks: map['totalWeeks'] ?? 0,
      weeklyPlans: (map['weeklyPlans'] as List<dynamic>?)
          ?.map((planMap) => WeeklyPlan.fromMap(planMap))
          .toList() ?? [],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}

/// 주간 훈련 계획
class WeeklyPlan {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDistance; // km
  final List<DailyWorkout> dailyWorkouts;
  final String focus; // 해당 주의 훈련 포커스

  const WeeklyPlan({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.totalDistance,
    required this.dailyWorkouts,
    required this.focus,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDistance': totalDistance,
      'dailyWorkouts': dailyWorkouts.map((workout) => workout.toMap()).toList(),
      'focus': focus,
    };
  }

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) {
    return WeeklyPlan(
      weekNumber: map['weekNumber'] ?? 0,
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalDistance: (map['totalDistance'] ?? 0.0).toDouble(),
      dailyWorkouts: (map['dailyWorkouts'] as List<dynamic>?)
          ?.map((workoutMap) => DailyWorkout.fromMap(workoutMap))
          .toList() ?? [],
      focus: map['focus'] ?? '',
    );
  }
}

/// 일일 운동 계획
class DailyWorkout {
  final DateTime date;
  final TrainingType type;
  final double? distance; // km (휴식일은 null)
  final Duration? duration; // 목표 시간
  final Duration? targetPace; // 목표 페이스
  final String description;
  final List<WorkoutInterval>? intervals; // 인터벌 훈련의 경우

  const DailyWorkout({
    required this.date,
    required this.type,
    this.distance,
    this.duration,
    this.targetPace,
    required this.description,
    this.intervals,
  });

  bool get isRest => type == TrainingType.rest;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'type': type.name,
      'distance': distance,
      'durationMinutes': duration?.inMinutes,
      'targetPaceMinutes': targetPace?.inMinutes,
      'targetPaceSeconds': targetPace != null ? targetPace!.inSeconds % 60 : null,
      'description': description,
      'intervals': intervals?.map((interval) => interval.toMap()).toList(),
    };
  }

  factory DailyWorkout.fromMap(Map<String, dynamic> map) {
    Duration? targetPace;
    if (map['targetPaceMinutes'] != null) {
      final minutes = map['targetPaceMinutes'] ?? 0;
      final seconds = map['targetPaceSeconds'] ?? 0;
      targetPace = Duration(minutes: minutes, seconds: seconds);
    }

    return DailyWorkout(
      date: DateTime.parse(map['date']),
      type: TrainingType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => TrainingType.rest,
      ),
      distance: map['distance']?.toDouble(),
      duration: map['durationMinutes'] != null 
          ? Duration(minutes: map['durationMinutes']) 
          : null,
      targetPace: targetPace,
      description: map['description'] ?? '',
      intervals: (map['intervals'] as List<dynamic>?)
          ?.map((intervalMap) => WorkoutInterval.fromMap(intervalMap))
          .toList(),
    );
  }
}

/// 운동 인터벌 (인터벌 훈련용)
class WorkoutInterval {
  final double distance; // km
  final Duration targetTime;
  final Duration restTime;
  final int repetitions;

  const WorkoutInterval({
    required this.distance,
    required this.targetTime,
    required this.restTime,
    required this.repetitions,
  });

  Duration get targetPace {
    final totalMinutes = targetTime.inMinutes;
    final paceMinutes = totalMinutes / distance;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return Duration(minutes: minutes, seconds: seconds);
  }

  Map<String, dynamic> toMap() {
    return {
      'distance': distance,
      'targetTimeMinutes': targetTime.inMinutes,
      'restTimeMinutes': restTime.inMinutes,
      'repetitions': repetitions,
    };
  }

  factory WorkoutInterval.fromMap(Map<String, dynamic> map) {
    return WorkoutInterval(
      distance: (map['distance'] ?? 0.0).toDouble(),
      targetTime: Duration(minutes: map['targetTimeMinutes'] ?? 0),
      restTime: Duration(minutes: map['restTimeMinutes'] ?? 0),
      repetitions: map['repetitions'] ?? 1,
    );
  }
}
