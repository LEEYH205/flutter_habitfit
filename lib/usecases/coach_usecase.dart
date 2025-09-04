import '../models/today_summary.dart';
import '../models/trend_data.dart';

/// AI 기반 코칭 UseCase - 개인화된 권장사항 생성
class CoachUseCase {
  /// 오늘의 코칭 메시지 생성
  static String generateTodayCoaching(TodaySummary todaySummary, TrendData? trendData) {
    // 시간대별 권장사항
    final hour = DateTime.now().hour;
    
    if (hour < 9) {
      return _generateMorningCoaching(todaySummary);
    } else if (hour < 12) {
      return _generateLateMorningCoaching(todaySummary);
    } else if (hour < 18) {
      return _generateAfternoonCoaching(todaySummary);
    } else {
      return _generateEveningCoaching(todaySummary, trendData);
    }
  }

  /// 아침 코칭 (6-9시)
  static String _generateMorningCoaching(TodaySummary summary) {
    if (summary.habitProgress == 0) {
      return '좋은 아침! 오늘의 첫 습관을 시작해보세요. 🌅';
    }
    if (summary.habitProgress < 0.3) {
      return '아침 습관을 완료했네요! 오늘도 화이팅! 💪';
    }
    return '아침부터 활발하시네요! 오늘도 좋은 하루 되세요! ✨';
  }

  /// 늦은 아침 코칭 (9-12시)
  static String _generateLateMorningCoaching(TodaySummary summary) {
    if (summary.habitProgress < 0.5) {
      return '오전 시간을 활용해서 습관을 더 체크해보세요! 📝';
    }
    if (summary.calories < 200) {
      return '오전 운동을 해보는 건 어떨까요? 🏃‍♂️';
    }
    return '오전 시간을 잘 활용하고 계시네요! 👍';
  }

  /// 오후 코칭 (12-18시)
  static String _generateAfternoonCoaching(TodaySummary summary) {
    if (summary.habitProgress < 0.7) {
      return '오후 시간에 남은 습관들을 완료해보세요! ⏰';
    }
    if (summary.calories < 500) {
      return '오후 운동으로 하루를 마무리해보세요! 🏋️‍♀️';
    }
    return '오후까지도 꾸준하시네요! 계속 화이팅! 🔥';
  }

  /// 저녁 코칭 (18시 이후)
  static String _generateEveningCoaching(TodaySummary summary, TrendData? trendData) {
    if (summary.habitProgress < 1.0) {
      return '하루를 마무리하기 전에 남은 습관을 체크해보세요! 🌙';
    }
    if (summary.calories < 800) {
      return '저녁 운동으로 하루를 마무리해보세요! 🌆';
    }
    
    // 트렌드 데이터가 있으면 더 개인화된 메시지
    if (trendData != null) {
      if (trendData.consistencyScore >= 80) {
        return '완벽한 하루! 일관성도 훌륭합니다! 🎉';
      } else if (trendData.consistencyScore >= 60) {
        return '오늘도 잘하셨네요! 꾸준함이 느껴집니다! 💯';
      }
    }
    
    return '오늘도 수고하셨습니다! 내일도 파이팅! 🌟';
  }

  /// 주간 코칭 메시지 생성
  static String generateWeeklyCoaching(TrendData trendData) {
    final consistency = trendData.consistencyScore;
    final habitRate = trendData.habitCompletionRate;
    final workoutRate = trendData.workoutCompletionRate;
    
    if (consistency >= 80 && habitRate >= 70 && workoutRate >= 50) {
      return '이번 주도 완벽했습니다! 🏆';
    } else if (consistency >= 60) {
      return '이번 주도 꾸준히 노력하셨네요! 💪';
    } else if (consistency >= 40) {
      return '조금 더 꾸준함이 필요해 보입니다. 📈';
    } else {
      return '규칙적인 루틴을 만들어보세요. 🎯';
    }
  }

  /// 개인화된 목표 제안
  static List<String> generatePersonalizedGoals(TodaySummary todaySummary, TrendData trendData) {
    final goals = <String>[];
    
    // 습관 관련 목표
    if (trendData.habitCompletionRate < 60) {
      goals.add('습관 완료율을 70%까지 높여보세요');
    } else if (trendData.habitCompletionRate < 80) {
      goals.add('습관 완료율을 90%까지 높여보세요');
    } else {
      goals.add('새로운 습관을 추가해보세요');
    }
    
    // 운동 관련 목표
    if (trendData.workoutCompletionRate < 40) {
      goals.add('주 3회 운동을 목표로 해보세요');
    } else if (trendData.workoutCompletionRate < 60) {
      goals.add('주 4회 운동을 목표로 해보세요');
    } else {
      goals.add('운동 강도를 높여보세요');
    }
    
    // 연속성 관련 목표
    if (trendData.maxConsecutiveHabitDays < 5) {
      goals.add('연속 7일 습관 달성을 목표로 해보세요');
    } else if (trendData.maxConsecutiveHabitDays < 10) {
      goals.add('연속 14일 습관 달성을 목표로 해보세요');
    } else {
      goals.add('연속 30일 습관 달성을 목표로 해보세요');
    }
    
    return goals;
  }

  /// 동기부여 메시지 생성
  static String generateMotivationalMessage(TodaySummary todaySummary, TrendData? trendData) {
    final messages = <String>[
      '작은 시작이 큰 변화를 만듭니다! 🌱',
      '오늘의 노력이 내일의 성과가 됩니다! ⭐',
      '꾸준함이 만드는 기적을 믿어보세요! ✨',
      '한 걸음씩 나아가고 있어요! 🚀',
      '당신의 노력이 빛나고 있습니다! 💎',
    ];
    
    // 성과에 따른 특별 메시지
    if (todaySummary.habitProgress >= 1.0) {
      return '완벽한 하루! 당신은 정말 대단해요! 🎉';
    } else if (todaySummary.habitProgress >= 0.8) {
      return '거의 다 왔어요! 마지막까지 화이팅! 🔥';
    } else if (todaySummary.habitProgress >= 0.5) {
      return '절반 이상 완료! 계속해서 나아가세요! 💪';
    }
    
    // 랜덤 메시지 반환
    return messages[DateTime.now().day % messages.length];
  }

  /// 다음 액션 제안
  static List<String> generateNextActions(TodaySummary todaySummary) {
    final actions = <String>[];
    
    if (todaySummary.habitProgress < 1.0) {
      actions.add('남은 습관 체크하기');
    }
    if (todaySummary.calories < 1000) {
      actions.add('운동 시작하기');
    }
    if (todaySummary.protein < 100) {
      actions.add('단백질이 풍부한 식사하기');
    }
    if (todaySummary.steps < 8000) {
      actions.add('걷기 시작하기');
    }
    
    if (actions.isEmpty) {
      actions.add('오늘의 성과를 기록하기');
      actions.add('내일 계획 세우기');
    }
    
    return actions;
  }
}
