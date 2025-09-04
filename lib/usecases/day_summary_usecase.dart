import '../models/today_summary.dart';
import '../models/day_log.dart';
import '../providers/today_summary_provider.dart';
import '../providers/day_log_provider.dart';

/// 일일 요약 UseCase - Today와 Journal 페이지에서 공통으로 사용
class DaySummaryUseCase {
  /// 오늘 요약 데이터 가져오기
  static Future<TodaySummary> getTodaySummary() async {
    // Provider를 통해 데이터 가져오기
    // 실제 구현에서는 Provider 대신 직접 Firebase 호출
    throw UnimplementedError('Provider를 통해 구현 예정');
  }

  /// 특정 날짜의 로그 데이터 가져오기
  static Future<DayLog> getDayLog(DateTime date) async {
    // Provider를 통해 데이터 가져오기
    // 실제 구현에서는 Provider 대신 직접 Firebase 호출
    throw UnimplementedError('Provider를 통해 구현 예정');
  }

  /// 오늘의 권장사항 생성
  static String generateTodayRecommendation(TodaySummary summary) {
    if (summary.habitCompletionRate < 50) {
      return '습관을 조금 더 체크해보세요!';
    }
    if (summary.calories < 1000) {
      return '운동을 더 해보는 건 어떨까요?';
    }
    if (summary.protein < 100) {
      return '단백질 섭취를 늘려보세요!';
    }
    return '오늘도 훌륭합니다!';
  }

  /// 오늘의 성과 요약 생성
  static String generateTodaySummaryText(TodaySummary summary) {
    final completed = summary.completedHabits + summary.completedWorkouts;
    if (completed == 0) return '오늘은 휴식일이에요!';
    if (completed < 3) return '조금 더 화이팅!';
    if (completed < 5) return '좋은 하루네요!';
    return '완벽한 하루입니다!';
  }

  /// 목표 대비 진행률 계산
  static Map<String, double> calculateProgressRates(TodaySummary summary) {
    return {
      'habits': summary.habitProgress,
      'calories': summary.caloriesProgress,
      'protein': summary.proteinProgress,
      'steps': summary.stepsProgress,
    };
  }

  /// 빠른 액션 제안
  static List<String> getQuickActionSuggestions(TodaySummary summary) {
    final suggestions = <String>[];
    
    if (summary.habitProgress < 0.5) {
      suggestions.add('습관 체크하기');
    }
    if (summary.calories < 500) {
      suggestions.add('운동 시작하기');
    }
    if (summary.protein < 50) {
      suggestions.add('식사 기록하기');
    }
    if (summary.steps < 5000) {
      suggestions.add('걷기 시작하기');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('오늘도 완벽해요!');
    }
    
    return suggestions;
  }
}
