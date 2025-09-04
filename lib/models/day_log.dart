/// 특정 날짜의 로그 데이터 모델
class DayLog {
  final DateTime date;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> workouts;
  final Map<String, dynamic>? runningData;
  final List<Map<String, dynamic>> meals;

  const DayLog({
    required this.date,
    required this.habits,
    required this.workouts,
    this.runningData,
    required this.meals,
  });

  /// 완료된 습관 개수
  int get completedHabitsCount => habits.length;

  /// 완료된 운동 개수
  int get completedWorkoutsCount => workouts.length;

  /// 달리기 데이터가 있는지 확인
  bool get hasRunningData => runningData != null;

  /// 식사 데이터가 있는지 확인
  bool get hasMealsData => meals.isNotEmpty;

  /// 해당 날짜에 활동이 있는지 확인
  bool get hasAnyActivity => 
      completedHabitsCount > 0 || 
      completedWorkoutsCount > 0 || 
      hasRunningData || 
      hasMealsData;

  /// 총 운동 시간 (분)
  int get totalWorkoutMinutes {
    int total = 0;
    
    // 일반 운동 시간
    for (final workout in workouts) {
      total += (workout['duration'] ?? 0) as int;
    }
    
    // 달리기 시간
    if (runningData != null) {
      total += (runningData!['duration'] ?? 0) as int;
    }
    
    return total;
  }

  /// 총 소모 칼로리
  double get totalBurnedCalories {
    double total = 0.0;
    
    // 일반 운동 칼로리
    for (final workout in workouts) {
      total += (workout['calories'] ?? 0).toDouble();
    }
    
    // 달리기 칼로리
    if (runningData != null) {
      total += (runningData!['calories'] ?? 0).toDouble();
    }
    
    return total;
  }

  /// 총 섭취 칼로리 (식사 데이터)
  double get totalConsumedCalories {
    double total = 0.0;
    for (final meal in meals) {
      total += (meal['calories'] ?? 0).toDouble();
    }
    return total;
  }

  /// 총 섭취 단백질 (식사 데이터)
  double get totalConsumedProtein {
    double total = 0.0;
    for (final meal in meals) {
      total += (meal['protein'] ?? 0).toDouble();
    }
    return total;
  }

  /// 달리기 거리 (km)
  double get runningDistance => runningData?['distance'] ?? 0.0;

  /// 달리기 평균 페이스 (분/km)
  double get runningAveragePace {
    if (runningData == null) return 0.0;
    final distance = runningData!['distance'] ?? 0.0;
    final duration = runningData!['duration'] ?? 0;
    
    if (distance == 0 || duration == 0) return 0.0;
    return (duration / 60.0) / distance; // 분/km
  }

  /// 날짜 문자열 (YYYY-MM-DD)
  String get dateString => _getDateId(date);

  /// 요일 이름
  String get weekdayName {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  /// 날짜 표시 문자열
  String get displayDate => '${date.month}월 ${date.day}일 ($weekdayName)';

  /// 활동 요약 텍스트
  String get activitySummary {
    final activities = <String>[];
    
    if (completedHabitsCount > 0) {
      activities.add('습관 ${completedHabitsCount}개');
    }
    if (completedWorkoutsCount > 0) {
      activities.add('운동 ${completedWorkoutsCount}개');
    }
    if (hasRunningData) {
      activities.add('달리기 ${runningDistance.toStringAsFixed(1)}km');
    }
    if (hasMealsData) {
      activities.add('식사 ${meals.length}끼');
    }
    
    if (activities.isEmpty) {
      return '활동 없음';
    }
    
    return activities.join(', ');
  }

  /// 칼로리 밸런스 (섭취 - 소모)
  double get calorieBalance => totalConsumedCalories - totalBurnedCalories;

  /// 칼로리 밸런스 상태
  String get calorieBalanceStatus {
    final balance = calorieBalance;
    if (balance > 500) return '과다 섭취';
    if (balance > 0) return '적정 섭취';
    if (balance > -500) return '적정 소모';
    return '과다 소모';
  }

  @override
  String toString() {
    return 'DayLog(date: $date, habits: $completedHabitsCount, workouts: $completedWorkoutsCount, running: $hasRunningData, meals: ${meals.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayLog &&
        other.date == date &&
        other.habits == habits &&
        other.workouts == workouts &&
        other.runningData == runningData &&
        other.meals == meals;
  }

  @override
  int get hashCode {
    return Object.hash(date, habits, workouts, runningData, meals);
  }
}

/// 날짜 ID 생성 (YYYY-MM-DD 형식)
String _getDateId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
