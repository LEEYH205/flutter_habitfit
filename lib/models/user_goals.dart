/// 사용자 목표 설정 모델
class UserGoals {
<<<<<<< HEAD
  final double activeCaloriesGoal; // 움직이기 칼로리 목표 (kcal)
  final int exerciseMinutesGoal; // 운동 시간 목표 (분)
  final int stepsGoal; // 걸음 수 목표 (걸음)
=======
  final double activeCaloriesGoal;
  final int exerciseMinutesGoal;
  final int stepsGoal;
>>>>>>> temp-branch
  final DateTime lastUpdated;

  const UserGoals({
    required this.activeCaloriesGoal,
    required this.exerciseMinutesGoal,
    required this.stepsGoal,
    required this.lastUpdated,
  });

<<<<<<< HEAD
  /// 기본 목표값으로 생성
=======
  /// 기본 목표값 생성자
>>>>>>> temp-branch
  factory UserGoals.defaultGoals() {
    return UserGoals(
      activeCaloriesGoal: 400.0,
      exerciseMinutesGoal: 30,
      stepsGoal: 10000,
      lastUpdated: DateTime.now(),
    );
  }

<<<<<<< HEAD
=======
  /// JSON에서 생성
  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      activeCaloriesGoal: (json['activeCaloriesGoal'] ?? 400.0).toDouble(),
      exerciseMinutesGoal: (json['exerciseMinutesGoal'] ?? 30) as int,
      stepsGoal: (json['stepsGoal'] ?? 10000) as int,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

>>>>>>> temp-branch
  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'activeCaloriesGoal': activeCaloriesGoal,
      'exerciseMinutesGoal': exerciseMinutesGoal,
      'stepsGoal': stepsGoal,
<<<<<<< HEAD
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  /// JSON에서 객체 생성
  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      activeCaloriesGoal: (json['activeCaloriesGoal'] ?? 400.0).toDouble(),
      exerciseMinutesGoal: json['exerciseMinutesGoal'] ?? 30,
      stepsGoal: json['stepsGoal'] ?? 10000,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// 목표값 복사 (일부 필드만 변경)
=======
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 복사본 생성 (특정 필드만 변경)
>>>>>>> temp-branch
  UserGoals copyWith({
    double? activeCaloriesGoal,
    int? exerciseMinutesGoal,
    int? stepsGoal,
    DateTime? lastUpdated,
  }) {
    return UserGoals(
      activeCaloriesGoal: activeCaloriesGoal ?? this.activeCaloriesGoal,
      exerciseMinutesGoal: exerciseMinutesGoal ?? this.exerciseMinutesGoal,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'UserGoals(activeCalories: ${activeCaloriesGoal}kcal, exercise: $exerciseMinutesGoal분, steps: $stepsGoal걸음)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserGoals &&
        other.activeCaloriesGoal == activeCaloriesGoal &&
        other.exerciseMinutesGoal == exerciseMinutesGoal &&
<<<<<<< HEAD
        other.stepsGoal == stepsGoal &&
        other.lastUpdated == lastUpdated;
=======
        other.stepsGoal == stepsGoal;
>>>>>>> temp-branch
  }

  @override
  int get hashCode {
<<<<<<< HEAD
    return Object.hash(
      activeCaloriesGoal,
      exerciseMinutesGoal,
      stepsGoal,
      lastUpdated,
    );
=======
    return activeCaloriesGoal.hashCode ^
        exerciseMinutesGoal.hashCode ^
        stepsGoal.hashCode;
>>>>>>> temp-branch
  }
}
