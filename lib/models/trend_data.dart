/// 트렌드 데이터 모델 (주/월/범위별 분석)
class TrendData {
  final TrendRange range;
  final DateTime startDate;
  final DateTime endDate;
  final int totalHabits;
  final int completedHabits;
  final int completedWorkouts;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> workouts;

  const TrendData({
    required this.range,
    required this.startDate,
    required this.endDate,
    required this.totalHabits,
    required this.completedHabits,
    required this.completedWorkouts,
    required this.habits,
    required this.workouts,
  });

  /// 기간 길이 (일)
  int get periodLength => endDate.difference(startDate).inDays + 1;

  /// 습관 완료율 (0.0 ~ 100.0)
  double get habitCompletionRate {
    if (totalHabits == 0) return 0.0;
    return (completedHabits / (totalHabits * periodLength)) * 100;
  }

  /// 운동 완료율 (0.0 ~ 100.0)
  double get workoutCompletionRate {
    return (completedWorkouts / periodLength) * 100;
  }

  /// 일관성 점수 (0.0 ~ 100.0)
  double get consistencyScore {
    if (periodLength == 0) return 0.0;
    
    // 매일 습관을 완료한 날의 비율
    final dailyHabitCompletion = _calculateDailyCompletion();
    return dailyHabitCompletion * 100;
  }

  /// 매일 습관 완료율 계산
  double _calculateDailyCompletion() {
    if (totalHabits == 0) return 0.0;
    
    final dailyCompletions = <String, int>{};
    
    // 날짜별 완료된 습관 개수 계산
    for (final habit in habits) {
      final date = habit['date'] as String;
      dailyCompletions[date] = (dailyCompletions[date] ?? 0) + 1;
    }
    
    // 완전히 완료된 날의 개수 (모든 습관 완료)
    int fullyCompletedDays = 0;
    for (int i = 0; i < periodLength; i++) {
      final date = _getDateId(startDate.add(Duration(days: i)));
      final completedCount = dailyCompletions[date] ?? 0;
      if (completedCount >= totalHabits) {
        fullyCompletedDays++;
      }
    }
    
    return fullyCompletedDays / periodLength;
  }

  /// 평균 일일 습관 완료 개수
  double get averageDailyHabits {
    return completedHabits / periodLength;
  }

  /// 평균 일일 운동 완료 개수
  double get averageDailyWorkouts {
    return completedWorkouts / periodLength;
  }

  /// 최고 연속 습관 완료 일수
  int get maxConsecutiveHabitDays {
    int maxConsecutive = 0;
    int currentConsecutive = 0;
    
    final dailyCompletions = <String, int>{};
    for (final habit in habits) {
      final date = habit['date'] as String;
      dailyCompletions[date] = (dailyCompletions[date] ?? 0) + 1;
    }
    
    for (int i = 0; i < periodLength; i++) {
      final date = _getDateId(startDate.add(Duration(days: i)));
      final completedCount = dailyCompletions[date] ?? 0;
      
      if (completedCount >= totalHabits) {
        currentConsecutive++;
        maxConsecutive = maxConsecutive > currentConsecutive ? maxConsecutive : currentConsecutive;
      } else {
        currentConsecutive = 0;
      }
    }
    
    return maxConsecutive;
  }

  /// 최고 연속 운동 완료 일수
  int get maxConsecutiveWorkoutDays {
    int maxConsecutive = 0;
    int currentConsecutive = 0;
    
    final dailyWorkouts = <String, int>{};
    for (final workout in workouts) {
      final date = workout['date'] as String;
      dailyWorkouts[date] = (dailyWorkouts[date] ?? 0) + 1;
    }
    
    for (int i = 0; i < periodLength; i++) {
      final date = _getDateId(startDate.add(Duration(days: i)));
      final workoutCount = dailyWorkouts[date] ?? 0;
      
      if (workoutCount > 0) {
        currentConsecutive++;
        maxConsecutive = maxConsecutive > currentConsecutive ? maxConsecutive : currentConsecutive;
      } else {
        currentConsecutive = 0;
      }
    }
    
    return maxConsecutive;
  }

  /// 트렌드 방향 (상승/하락/유지)
  TrendDirection get trendDirection {
    if (periodLength < 7) return TrendDirection.stable;
    
    final firstHalf = periodLength ~/ 2;
    final secondHalf = periodLength - firstHalf;
    
    final firstHalfHabits = _getHabitsInPeriod(0, firstHalf);
    final secondHalfHabits = _getHabitsInPeriod(firstHalf, secondHalf);
    
    final firstHalfRate = firstHalfHabits / (totalHabits * firstHalf);
    final secondHalfRate = secondHalfHabits / (totalHabits * secondHalf);
    
    if (secondHalfRate > firstHalfRate * 1.1) {
      return TrendDirection.improving;
    } else if (secondHalfRate < firstHalfRate * 0.9) {
      return TrendDirection.declining;
    } else {
      return TrendDirection.stable;
    }
  }

  /// 특정 기간의 습관 완료 개수
  int _getHabitsInPeriod(int startDay, int dayCount) {
    int count = 0;
    for (int i = 0; i < dayCount; i++) {
      final date = _getDateId(startDate.add(Duration(days: startDay + i)));
      for (final habit in habits) {
        if (habit['date'] == date) {
          count++;
        }
      }
    }
    return count;
  }

  /// 트렌드 요약 텍스트
  String get trendSummary {
    final consistency = consistencyScore;
    
    if (consistency >= 80) {
      return '매우 일관적인 패턴을 보이고 있습니다!';
    } else if (consistency >= 60) {
      return '꾸준한 노력을 하고 있습니다.';
    } else if (consistency >= 40) {
      return '조금 더 꾸준함이 필요합니다.';
    } else {
      return '규칙적인 루틴을 만들어보세요.';
    }
  }

  /// 개선 제안
  String get improvementSuggestion {
    if (habitCompletionRate < 50) {
      return '습관 목표를 조금 낮춰보는 것을 고려해보세요.';
    }
    if (workoutCompletionRate < 30) {
      return '운동 빈도를 늘려보세요.';
    }
    if (maxConsecutiveHabitDays < 3) {
      return '연속성을 높이기 위해 작은 목표부터 시작해보세요.';
    }
    return '현재 패턴을 유지하세요!';
  }

  /// 날짜 ID 생성 (YYYY-MM-DD 형식)
  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'TrendData(range: $range, period: $periodLength일, habits: $completedHabits, workouts: $completedWorkouts, consistency: ${consistencyScore.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendData &&
        other.range == range &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalHabits == totalHabits &&
        other.completedHabits == completedHabits &&
        other.completedWorkouts == completedWorkouts;
  }

  @override
  int get hashCode {
    return Object.hash(
      range,
      startDate,
      endDate,
      totalHabits,
      completedHabits,
      completedWorkouts,
    );
  }
}

/// 트렌드 방향 열거형
enum TrendDirection {
  improving,  // 개선 중
  declining,  // 하락 중
  stable,     // 유지
}

/// 트렌드 범위 열거형 (trend_provider.dart에서 import)
enum TrendRange {
  week7,    // 최근 7일
  week14,   // 최근 14일
  month30,  // 최근 30일
  month90,  // 최근 90일
  custom,   // 사용자 정의
}
