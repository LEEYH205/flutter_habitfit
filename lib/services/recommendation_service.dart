import 'package:flutter/material.dart';
import 'analytics_service.dart';
import 'habit_service.dart';

/// 목표 조정 제안 모델
class GoalAdjustment {
  final String habitType;
  final int currentGoal;
  final int suggestedGoal;
  final String reason;
  final double confidence; // 신뢰도 (0-1)

  GoalAdjustment({
    required this.habitType,
    required this.currentGoal,
    required this.suggestedGoal,
    required this.reason,
    required this.confidence,
  });
}

/// 습관 제안 모델
class HabitSuggestion {
  final String title;
  final String emoji;
  final String description;
  final String category;
  final double relevanceScore; // 관련성 점수 (0-1)
  final List<String> benefits;

  HabitSuggestion({
    required this.title,
    required this.emoji,
    required this.description,
    required this.category,
    required this.relevanceScore,
    required this.benefits,
  });
}

/// 스마트 추천 서비스
class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final AnalyticsService _analyticsService = AnalyticsService();
  final HabitService _habitService = HabitService();

  /// 최적 시간 추천
  Future<TimeOfDay?> recommendOptimalTime(String uid, String habitType) async {
    try {
      print('🤖 최적 시간 추천 시작: $habitType');

      final pattern = await _analyticsService.getUserPattern(uid);
      if (pattern == null) {
        print('⚠️ 사용자 패턴 데이터 없음');
        return null;
      }

      // 시간대별 성과에서 최고 성과 시간대 찾기
      final timePerformance = pattern.timeBasedPerformance;
      if (timePerformance.isEmpty) {
        print('⚠️ 시간대별 성과 데이터 없음');
        return null;
      }

      // 상위 3개 시간대 중에서 추천
      final sortedTimes = timePerformance.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedTimes.isNotEmpty) {
        final bestHour = sortedTimes.first.key;
        final confidence = sortedTimes.first.value;

        print(
            '✅ 최적 시간 추천: $bestHour시 (신뢰도: ${(confidence * 100).toStringAsFixed(1)}%)');
        return TimeOfDay(hour: bestHour, minute: 0);
      }

      return null;
    } catch (e) {
      print('❌ 최적 시간 추천 실패: $e');
      return null;
    }
  }

  /// 목표 조정 제안
  Future<List<GoalAdjustment>> suggestGoalAdjustments(String uid) async {
    try {
      print('🎯 목표 조정 제안 시작');

      final pattern = await _analyticsService.getUserPattern(uid);
      if (pattern == null) {
        print('⚠️ 사용자 패턴 데이터 없음');
        return [];
      }

      final suggestions = <GoalAdjustment>[];

      // 완료율 기반 목표 조정 제안
      final completionRate = pattern.overallCompletionRate;
      final totalHabits = pattern.totalHabits;
      final completedHabits = pattern.completedHabits;

      if (completionRate > 0.8) {
        // 완료율이 80% 이상이면 목표 증가 제안
        final confidence = _calculateConfidence(
          completionRate: completionRate,
          totalHabits: totalHabits,
          completedHabits: completedHabits,
          consistencyScore: pattern.consistencyScore,
          suggestionType: 'increase',
        );

        suggestions.add(GoalAdjustment(
          habitType: '습관',
          currentGoal: 1,
          suggestedGoal: 2,
          reason:
              '완료율이 ${(completionRate * 100).toStringAsFixed(1)}%로 높습니다. 목표를 늘려보세요!',
          confidence: confidence,
        ));
      } else if (completionRate < 0.3) {
        // 완료율이 30% 미만이면 목표 감소 제안
        final confidence = _calculateConfidence(
          completionRate: completionRate,
          totalHabits: totalHabits,
          completedHabits: completedHabits,
          consistencyScore: pattern.consistencyScore,
          suggestionType: 'decrease',
        );

        suggestions.add(GoalAdjustment(
          habitType: '습관',
          currentGoal: 1,
          suggestedGoal: 1,
          reason:
              '완료율이 ${(completionRate * 100).toStringAsFixed(1)}%로 낮습니다. 현재 목표를 꾸준히 달성해보세요.',
          confidence: confidence,
        ));
      }

      // 일관성 점수 기반 제안
      if (pattern.consistencyScore < 0.5) {
        final confidence = _calculateConfidence(
          completionRate: completionRate,
          totalHabits: totalHabits,
          completedHabits: completedHabits,
          consistencyScore: pattern.consistencyScore,
          suggestionType: 'consistency',
        );

        suggestions.add(GoalAdjustment(
          habitType: '일관성',
          currentGoal: 1,
          suggestedGoal: 1,
          reason:
              '일관성 점수가 ${(pattern.consistencyScore * 100).toStringAsFixed(1)}%입니다. 규칙적인 시간에 습관을 실천해보세요.',
          confidence: confidence,
        ));
      }

      print('✅ 목표 조정 제안 완료: ${suggestions.length}개');
      return suggestions;
    } catch (e) {
      print('❌ 목표 조정 제안 실패: $e');
      return [];
    }
  }

  /// 새로운 습관 추천
  Future<List<HabitSuggestion>> suggestNewHabits(String uid) async {
    try {
      print('💡 새로운 습관 추천 시작');

      final pattern = await _analyticsService.getUserPattern(uid);
      if (pattern == null) {
        print('⚠️ 사용자 패턴 데이터 없음');
        return await _filterExistingHabits(uid, _getDefaultHabitSuggestions());
      }

      // 기존 습관 목록 가져오기 (중복 방지용)
      final existingHabits = await _habitService.getUserHabits();
      final existingTitles =
          existingHabits.map((h) => h.title.toLowerCase()).toSet();
      print('🔍 기존 습관 ${existingHabits.length}개: ${existingTitles.join(', ')}');

      final suggestions = <HabitSuggestion>[];

      // 사용자 패턴 기반 맞춤 추천
      if (pattern.bestTimeSlots.isNotEmpty) {
        final bestTime = pattern.bestTimeSlots.first;
        if (bestTime.contains('오전') ||
            bestTime.contains('6시') ||
            bestTime.contains('7시') ||
            bestTime.contains('8시')) {
          suggestions.add(HabitSuggestion(
            title: '아침 물 마시기',
            emoji: '💧',
            description: '아침에 일어나서 물 한 잔 마시기',
            category: '건강',
            relevanceScore: 0.9,
            benefits: ['신진대사 촉진', '수분 보충', '활력 증진'],
          ));
        }
      }

      // 완료율이 높으면 새로운 도전 제안
      if (pattern.overallCompletionRate > 0.7) {
        suggestions.add(HabitSuggestion(
          title: '독서하기',
          emoji: '📚',
          description: '하루 30분 독서하기',
          category: '학습',
          relevanceScore: 0.8,
          benefits: ['지식 습득', '집중력 향상', '스트레스 감소'],
        ));
      }

      // 일관성이 낮으면 간단한 습관 제안
      if (pattern.consistencyScore < 0.5) {
        suggestions.add(HabitSuggestion(
          title: '감사 일기',
          emoji: '🙏',
          description: '하루 한 가지 감사한 일 적기',
          category: '마음챙김',
          relevanceScore: 0.9,
          benefits: ['긍정적 사고', '스트레스 감소', '만족감 증진'],
        ));
      }

      // 기본 추천 습관들 추가
      suggestions.addAll(_getDefaultHabitSuggestions());

      // 기존 습관과 중복되지 않는 제안만 필터링
      final filteredSuggestions = suggestions.where((suggestion) {
        final suggestionTitle = suggestion.title.toLowerCase();
        final isDuplicate = existingTitles.any((existingTitle) {
          // 완전 일치 또는 유사한 제목 체크
          return existingTitle == suggestionTitle ||
              existingTitle.contains(suggestionTitle.split(' ').first) ||
              suggestionTitle.contains(existingTitle.split(' ').first);
        });
        return !isDuplicate;
      }).toList();

      // 관련성 점수 순으로 정렬
      filteredSuggestions
          .sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      print(
          '✅ 새로운 습관 추천 완료: 전체 ${suggestions.length}개 → 필터링 후 ${filteredSuggestions.length}개');
      return filteredSuggestions.take(5).toList(); // 상위 5개만 반환
    } catch (e) {
      print('❌ 새로운 습관 추천 실패: $e');
      return await _filterExistingHabits(uid, _getDefaultHabitSuggestions());
    }
  }

  /// 기존 습관과 중복되지 않는 제안만 필터링
  Future<List<HabitSuggestion>> _filterExistingHabits(
      String uid, List<HabitSuggestion> suggestions) async {
    try {
      final existingHabits = await _habitService.getUserHabits();
      final existingTitles =
          existingHabits.map((h) => h.title.toLowerCase()).toSet();

      final filteredSuggestions = suggestions.where((suggestion) {
        final suggestionTitle = suggestion.title.toLowerCase();
        final isDuplicate = existingTitles.any((existingTitle) {
          return existingTitle == suggestionTitle ||
              existingTitle.contains(suggestionTitle.split(' ').first) ||
              suggestionTitle.contains(existingTitle.split(' ').first);
        });
        return !isDuplicate;
      }).toList();

      print(
          '🔍 중복 필터링: 전체 ${suggestions.length}개 → 필터링 후 ${filteredSuggestions.length}개');
      return filteredSuggestions;
    } catch (e) {
      print('❌ 중복 필터링 실패: $e');
      return suggestions; // 실패 시 원본 반환
    }
  }

  /// 기본 습관 제안 목록
  List<HabitSuggestion> _getDefaultHabitSuggestions() {
    return [
      HabitSuggestion(
        title: '물 마시기',
        emoji: '💧',
        description: '하루 8잔 물 마시기',
        category: '건강',
        relevanceScore: 0.8,
        benefits: ['수분 보충', '신진대사 촉진', '피부 건강'],
      ),
      HabitSuggestion(
        title: '걷기',
        emoji: '🚶',
        description: '하루 30분 걷기',
        category: '운동',
        relevanceScore: 0.7,
        benefits: ['심혈관 건강', '스트레스 해소', '체력 향상'],
      ),
      HabitSuggestion(
        title: '명상하기',
        emoji: '🧘',
        description: '하루 10분 명상하기',
        category: '마음챙김',
        relevanceScore: 0.6,
        benefits: ['스트레스 감소', '집중력 향상', '수면 개선'],
      ),
      HabitSuggestion(
        title: '독서하기',
        emoji: '📚',
        description: '하루 30분 독서하기',
        category: '학습',
        relevanceScore: 0.5,
        benefits: ['지식 습득', '집중력 향상', '상상력 증진'],
      ),
      HabitSuggestion(
        title: '일기 쓰기',
        emoji: '📝',
        description: '하루 한 줄 일기 쓰기',
        category: '성찰',
        relevanceScore: 0.4,
        benefits: ['자기 성찰', '감정 정리', '기억 보존'],
      ),
    ];
  }

  /// 스마트 알림 시간 추천
  Future<TimeOfDay?> recommendNotificationTime(
      String uid, String notificationType) async {
    try {
      print('🔔 스마트 알림 시간 추천: $notificationType');

      final pattern = await _analyticsService.getUserPattern(uid);
      if (pattern == null) {
        print('⚠️ 사용자 패턴 데이터 없음');
        return null;
      }

      // 알림 타입별 최적 시간 추천
      switch (notificationType) {
        case '습관 체크':
          // 습관 완료율이 높은 시간대의 1-2시간 전 추천
          final timePerformance = pattern.timeBasedPerformance;
          if (timePerformance.isNotEmpty) {
            final sortedTimes = timePerformance.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final bestHour = sortedTimes.first.key;
            final reminderHour = (bestHour - 2 + 24) % 24; // 2시간 전

            return TimeOfDay(hour: reminderHour, minute: 0);
          }
          break;

        case '일일 요약':
          // 저녁 시간대 (18-21시) 중에서 추천
          return const TimeOfDay(hour: 20, minute: 0);

        case '주간 요약':
          // 일요일 저녁 추천
          return const TimeOfDay(hour: 19, minute: 0);
      }

      return null;
    } catch (e) {
      print('❌ 스마트 알림 시간 추천 실패: $e');
      return null;
    }
  }

  /// 합리적인 신뢰도 계산
  /// 데이터 샘플 크기, 패턴 일관성, 통계적 유의성을 고려한 신뢰도 계산
  double _calculateConfidence({
    required double completionRate,
    required int totalHabits,
    required int completedHabits,
    required double consistencyScore,
    required String suggestionType,
  }) {
    // 기본 신뢰도 (0.1 ~ 0.9 범위)
    double baseConfidence = 0.1;

    // 1. 샘플 크기 기반 신뢰도 (데이터가 많을수록 신뢰도 증가)
    double sampleConfidence = 0.0;
    if (totalHabits >= 50) {
      sampleConfidence = 0.4; // 충분한 데이터
    } else if (totalHabits >= 20) {
      sampleConfidence = 0.3; // 적당한 데이터
    } else if (totalHabits >= 10) {
      sampleConfidence = 0.2; // 제한적 데이터
    } else {
      sampleConfidence = 0.1; // 부족한 데이터
    }

    // 2. 패턴 명확성 기반 신뢰도
    double patternConfidence = 0.0;
    switch (suggestionType) {
      case 'increase':
        // 완료율이 높을수록, 일관성이 높을수록 신뢰도 증가
        patternConfidence = (completionRate * 0.3) + (consistencyScore * 0.2);
        break;
      case 'decrease':
        // 완료율이 낮을수록, 하지만 극단적이지 않을 때 신뢰도 증가
        if (completionRate < 0.1) {
          patternConfidence = 0.15; // 너무 낮으면 데이터 부족 가능성
        } else {
          patternConfidence =
              (1.0 - completionRate) * 0.3 + (consistencyScore * 0.1);
        }
        break;
      case 'consistency':
        // 일관성 부족이 명확할수록 신뢰도 증가
        patternConfidence =
            (1.0 - consistencyScore) * 0.25 + (completionRate * 0.1);
        break;
    }

    // 3. 통계적 유의성 (완료된 습관 수와 총 습관 수의 비율 고려)
    double statisticalConfidence = 0.0;
    if (completedHabits >= 5) {
      // 최소 5개 이상의 완료된 습관이 있어야 의미있는 분석
      final ratio = completedHabits / totalHabits;
      statisticalConfidence = ratio * 0.2;
    }

    // 4. 극단값 페널티 (너무 극단적인 값은 신뢰도 감소)
    double extremePenalty = 0.0;
    if (completionRate < 0.05 || completionRate > 0.95) {
      extremePenalty = -0.1; // 극단적 완료율은 신뢰도 감소
    }

    // 최종 신뢰도 계산
    final finalConfidence = baseConfidence +
        sampleConfidence +
        patternConfidence +
        statisticalConfidence +
        extremePenalty;

    // 0.1 ~ 0.9 범위로 제한 (너무 높거나 낮은 신뢰도 방지)
    return finalConfidence.clamp(0.1, 0.9);
  }

  /// 개인화된 인사이트 생성
  Future<String> generatePersonalizedInsight(String uid) async {
    try {
      print('💭 개인화된 인사이트 생성');

      final pattern = await _analyticsService.getUserPattern(uid);
      if (pattern == null) {
        return '아직 충분한 데이터가 없어요. 습관을 실천해보세요!';
      }

      final insights = <String>[];

      // 완료율 기반 인사이트
      final completionRate = pattern.overallCompletionRate;
      if (completionRate > 0.8) {
        insights.add(
            '🎉 훌륭해요! ${(completionRate * 100).toStringAsFixed(1)}%의 완료율을 보이고 있습니다.');
      } else if (completionRate > 0.5) {
        insights.add(
            '👍 좋은 시작이에요! ${(completionRate * 100).toStringAsFixed(1)}%의 완료율을 유지하고 있습니다.');
      } else {
        insights.add(
            '💪 조금 더 노력해보세요! 현재 ${(completionRate * 100).toStringAsFixed(1)}%의 완료율입니다.');
      }

      // 최적 시간대 인사이트
      if (pattern.bestTimeSlots.isNotEmpty) {
        insights
            .add('⏰ ${pattern.bestTimeSlots.first}에 습관을 실천하는 것이 가장 효과적입니다.');
      }

      // 일관성 인사이트
      if (pattern.consistencyScore > 0.7) {
        insights.add('🌟 규칙적인 습관 실천이 인상적입니다!');
      } else if (pattern.consistencyScore < 0.3) {
        insights.add('📅 더 규칙적인 시간에 습관을 실천해보세요.');
      }

      return insights.join('\n');
    } catch (e) {
      print('❌ 개인화된 인사이트 생성 실패: $e');
      return '데이터 분석 중 오류가 발생했습니다.';
    }
  }
}
