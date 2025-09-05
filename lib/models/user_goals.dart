/// 사용자 목표 설정 모델
class UserGoals {
  final double activeCaloriesGoal;
  final int exerciseMinutesGoal;
  final int stepsGoal;
  final DateTime lastUpdated;

  const UserGoals({
    required this.activeCaloriesGoal,
    required this.exerciseMinutesGoal,
    required this.stepsGoal,
    required this.lastUpdated,
  });

  /// 기본 목표값 생성자
  factory UserGoals.defaultGoals() {
    return UserGoals(
      activeCaloriesGoal: 400.0,
      exerciseMinutesGoal: 30,
      stepsGoal: 10000,
      lastUpdated: DateTime.now(),
    );
  }

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

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'activeCaloriesGoal': activeCaloriesGoal,
      'exerciseMinutesGoal': exerciseMinutesGoal,
      'stepsGoal': stepsGoal,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 복사본 생성 (특정 필드만 변경)
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
        other.stepsGoal == stepsGoal;
  }

  @override
  int get hashCode {
    return activeCaloriesGoal.hashCode ^
        exerciseMinutesGoal.hashCode ^
        stepsGoal.hashCode;
  }
}
