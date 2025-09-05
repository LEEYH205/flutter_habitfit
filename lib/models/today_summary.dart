/// 오늘 요약 데이터 모델
class TodaySummary {
  final DateTime date;
  final int completedHabits;
  final int totalHabits;
  final int completedWorkouts;
  final double runningDistance;
  final int runningDuration;
  final double calories;
  final double protein;
  final int steps;
  final double activeCalories; // 움직이기 칼로리
  final int exerciseMinutes; // 운동 시간 (분)
  final double habitCompletionRate;

  const TodaySummary({
    required this.date,
    required this.completedHabits,
    required this.totalHabits,
    required this.completedWorkouts,
    required this.runningDistance,
    required this.runningDuration,
    required this.calories,
    required this.protein,
    required this.steps,
    required this.activeCalories,
    required this.exerciseMinutes,
    required this.habitCompletionRate,
  });

  /// 습관 완료율 (0.0 ~ 1.0)
  double get habitProgress =>
      totalHabits > 0 ? completedHabits / totalHabits : 0.0;

  /// 칼로리 목표 대비 진행률 (목표: 2000kcal)
  double get caloriesProgress => (calories / 2000.0).clamp(0.0, 1.0);

<<<<<<< HEAD
  /// 운동 시간 목표 대비 진행률
  double getExerciseProgress(int goal) =>
      (exerciseMinutes / goal.toDouble()).clamp(0.0, 1.0);
=======
  /// 단백질 목표 대비 진행률 (목표: 100g)
  double get proteinProgress => (protein / 100.0).clamp(0.0, 1.0);

  /// 운동 시간 목표 대비 진행률 (목표: 30분)
  double get exerciseProgress => (exerciseMinutes / 30.0).clamp(0.0, 1.0);
>>>>>>> temp-branch

  /// 움직이기 칼로리 목표 대비 진행률
  double getActiveCaloriesProgress(double goal) =>
      (activeCalories / goal).clamp(0.0, 1.0);

<<<<<<< HEAD
  /// 걸음 수 목표 대비 진행률
  double getStepsProgress(int goal) =>
      (steps / goal.toDouble()).clamp(0.0, 1.0);
=======
  /// 움직이기 칼로리 목표 대비 진행률 (동적 목표)
  double getActiveCaloriesProgress(double goal) =>
      (activeCalories / goal).clamp(0.0, 1.0);

  /// 운동 시간 목표 대비 진행률 (동적 목표)
  double getExerciseProgress(int goal) =>
      (exerciseMinutes / goal.toDouble()).clamp(0.0, 1.0);

  /// 걸음 수 목표 대비 진행률 (목표: 10000걸음)
  double get stepsProgress => (steps / 10000.0).clamp(0.0, 1.0);
>>>>>>> temp-branch

  /// 걸음 수 목표 대비 진행률 (동적 목표)
  double getStepsProgress(int goal) =>
      (steps / goal.toDouble()).clamp(0.0, 1.0);

  /// 오늘의 총 운동 시간 (분)
  int get totalWorkoutMinutes => runningDuration;

  /// 오늘의 총 소모 칼로리
  double get totalBurnedCalories => calories;

  /// 습관 완료 상태 텍스트
  String get habitStatusText => '$completedHabits/$totalHabits';

  /// 운동 완료 상태 텍스트
  String get workoutStatusText =>
      completedWorkouts > 0 ? '$completedWorkouts개 완료' : '운동 없음';

  /// 달리기 상태 텍스트
  String get runningStatusText {
    if (runningDistance == 0) return '달리기 없음';
    return '${runningDistance.toStringAsFixed(1)}km';
  }

  /// 오늘의 성과 요약
  String get todaySummaryText {
    final completed = completedHabits + completedWorkouts;
    if (completed == 0) return '오늘은 휴식일이에요!';
    if (completed < 3) return '조금 더 화이팅!';
    if (completed < 5) return '좋은 하루네요!';
    return '완벽한 하루입니다!';
  }

  /// 오늘의 권장사항
  String get todayRecommendation {
    if (habitCompletionRate < 50) {
      return '습관을 조금 더 체크해보세요!';
    }
    if (calories < 1000) {
      return '운동을 더 해보는 건 어떨까요?';
    }
    if (protein < 100) {
      return '단백질 섭취를 늘려보세요!';
    }
    return '오늘도 훌륭합니다!';
  }

  @override
  String toString() {
    return 'TodaySummary(date: $date, habits: $completedHabits/$totalHabits, workouts: $completedWorkouts, calories: $calories, protein: $protein, steps: $steps, activeCalories: $activeCalories, exerciseMinutes: $exerciseMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodaySummary &&
        other.date == date &&
        other.completedHabits == completedHabits &&
        other.totalHabits == totalHabits &&
        other.completedWorkouts == completedWorkouts &&
        other.runningDistance == runningDistance &&
        other.runningDuration == runningDuration &&
        other.calories == calories &&
        other.protein == protein &&
        other.steps == steps &&
        other.activeCalories == activeCalories &&
        other.exerciseMinutes == exerciseMinutes &&
        other.habitCompletionRate == habitCompletionRate;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      completedHabits,
      totalHabits,
      completedWorkouts,
      runningDistance,
      runningDuration,
      calories,
      protein,
      steps,
      activeCalories,
      exerciseMinutes,
      habitCompletionRate,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'completedHabits': completedHabits,
      'totalHabits': totalHabits,
      'completedWorkouts': completedWorkouts,
      'runningDistance': runningDistance,
      'runningDuration': runningDuration,
      'calories': calories,
      'protein': protein,
      'steps': steps,
      'activeCalories': activeCalories,
      'exerciseMinutes': exerciseMinutes,
      'habitCompletionRate': habitCompletionRate,
    };
  }

  /// JSON에서 객체 생성
  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    return TodaySummary(
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      completedHabits: json['completedHabits'],
      totalHabits: json['totalHabits'],
      completedWorkouts: json['completedWorkouts'],
      runningDistance: json['runningDistance'].toDouble(),
      runningDuration: json['runningDuration'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      steps: json['steps'],
      activeCalories: (json['activeCalories'] ?? 0.0).toDouble(),
      exerciseMinutes: json['exerciseMinutes'] ?? 0,
      habitCompletionRate: json['habitCompletionRate'].toDouble(),
    );
  }
}
