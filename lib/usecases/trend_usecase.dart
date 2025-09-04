import '../models/trend_data.dart';

/// 트렌드 분석 UseCase - Insights 페이지에서 사용
class TrendUseCase {
  /// 트렌드 데이터 분석
  static TrendAnalysisResult analyzeTrend(TrendData trendData) {
    return TrendAnalysisResult(
      direction: trendData.trendDirection,
      consistency: trendData.consistencyScore,
      habitCompletionRate: trendData.habitCompletionRate,
      workoutCompletionRate: trendData.workoutCompletionRate,
      maxConsecutiveDays: trendData.maxConsecutiveHabitDays,
      averageDailyHabits: trendData.averageDailyHabits,
      averageDailyWorkouts: trendData.averageDailyWorkouts,
    );
  }

  /// 개선 제안 생성
  static List<String> generateImprovementSuggestions(TrendData trendData) {
    final suggestions = <String>[];
    
    if (trendData.habitCompletionRate < 50) {
      suggestions.add('습관 목표를 조금 낮춰보는 것을 고려해보세요.');
    }
    if (trendData.workoutCompletionRate < 30) {
      suggestions.add('운동 빈도를 늘려보세요.');
    }
    if (trendData.maxConsecutiveHabitDays < 3) {
      suggestions.add('연속성을 높이기 위해 작은 목표부터 시작해보세요.');
    }
    if (trendData.consistencyScore < 60) {
      suggestions.add('규칙적인 루틴을 만들어보세요.');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('현재 패턴을 유지하세요!');
    }
    
    return suggestions;
  }

  /// 트렌드 요약 생성
  static String generateTrendSummary(TrendData trendData) {
    final consistency = trendData.consistencyScore;
    
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

  /// 다음 주 계획 제안
  static List<String> generateNextWeekPlan(TrendData trendData) {
    final plans = <String>[];
    
    if (trendData.habitCompletionRate < 70) {
      plans.add('습관 목표를 1-2개 줄여보세요.');
    }
    if (trendData.workoutCompletionRate < 50) {
      plans.add('주 3회 운동을 목표로 해보세요.');
    }
    if (trendData.maxConsecutiveHabitDays < 5) {
      plans.add('연속 5일 달성을 목표로 해보세요.');
    }
    
    if (plans.isEmpty) {
      plans.add('현재 목표를 유지하면서 새로운 도전을 해보세요.');
    }
    
    return plans;
  }

  /// 성과 비교 (이전 기간 대비)
  static ComparisonResult compareWithPreviousPeriod(
    TrendData current,
    TrendData previous,
  ) {
    final habitImprovement = current.habitCompletionRate - previous.habitCompletionRate;
    final workoutImprovement = current.workoutCompletionRate - previous.workoutCompletionRate;
    final consistencyImprovement = current.consistencyScore - previous.consistencyScore;
    
    return ComparisonResult(
      habitImprovement: habitImprovement,
      workoutImprovement: workoutImprovement,
      consistencyImprovement: consistencyImprovement,
      overallImprovement: (habitImprovement + workoutImprovement + consistencyImprovement) / 3,
    );
  }
}

/// 트렌드 분석 결과
class TrendAnalysisResult {
  final TrendDirection direction;
  final double consistency;
  final double habitCompletionRate;
  final double workoutCompletionRate;
  final int maxConsecutiveDays;
  final double averageDailyHabits;
  final double averageDailyWorkouts;

  const TrendAnalysisResult({
    required this.direction,
    required this.consistency,
    required this.habitCompletionRate,
    required this.workoutCompletionRate,
    required this.maxConsecutiveDays,
    required this.averageDailyHabits,
    required this.averageDailyWorkouts,
  });
}

/// 비교 결과
class ComparisonResult {
  final double habitImprovement;
  final double workoutImprovement;
  final double consistencyImprovement;
  final double overallImprovement;

  const ComparisonResult({
    required this.habitImprovement,
    required this.workoutImprovement,
    required this.consistencyImprovement,
    required this.overallImprovement,
  });

  /// 전체적인 개선 여부
  bool get isOverallImproving => overallImprovement > 0;

  /// 개선 정도 텍스트
  String get improvementText {
    if (overallImprovement > 10) {
      return '크게 개선되었습니다!';
    } else if (overallImprovement > 0) {
      return '조금씩 개선되고 있습니다.';
    } else if (overallImprovement > -10) {
      return '비슷한 수준을 유지하고 있습니다.';
    } else {
      return '조금 더 노력이 필요합니다.';
    }
  }
}
