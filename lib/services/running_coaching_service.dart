import 'package:health/health.dart';
import 'dart:math';
import 'health_kit_service.dart';

/// AI 기반 달리기 코칭 시스템
class RunningCoachingService {
  static final RunningCoachingService _instance =
      RunningCoachingService._internal();
  factory RunningCoachingService() => _instance;
  RunningCoachingService._internal();

  /// 달리기 운동 분석 및 코칭 생성
  RunningCoaching generateCoaching(
    WorkoutData workout, {
    List<WorkoutData>? recentWorkouts,
    List<HeartRateData>? heartRateData,
  }) {
    final analysis = _analyzeWorkout(workout, recentWorkouts, heartRateData);
    final coaching = _generatePersonalizedCoaching(analysis);

    return RunningCoaching(
      workout: workout,
      analysis: analysis,
      advice: coaching,
    );
  }

  /// 운동 데이터 분석
  RunningAnalysis _analyzeWorkout(
    WorkoutData workout,
    List<WorkoutData>? recentWorkouts,
    List<HeartRateData>? heartRateData,
  ) {
    // 기본 메트릭 계산
    final distance = workout.distance ?? 0;
    final duration = workout.duration.inMinutes;
    final pace = distance > 0 ? duration / distance : 0.0; // 분/km
    final speed = distance > 0 ? distance / (duration / 60) : 0.0; // km/h

    // 심박수 분석
    final heartRateAnalysis = _analyzeHeartRate(heartRateData);

    // 페이스 분석
    final paceAnalysis = _analyzePace(pace, speed, distance);

    // 트렌딩 분석 (최근 운동들과 비교)
    final trendingAnalysis = _analyzeTrending(workout, recentWorkouts);

    return RunningAnalysis(
      distance: distance,
      duration: duration,
      pace: pace,
      speed: speed,
      calories: workout.calories ?? 0,
      heartRateAnalysis: heartRateAnalysis,
      paceAnalysis: paceAnalysis,
      trendingAnalysis: trendingAnalysis,
    );
  }

  /// 심박수 분석
  HeartRateAnalysis _analyzeHeartRate(List<HeartRateData>? heartRateData) {
    if (heartRateData == null || heartRateData.isEmpty) {
      return HeartRateAnalysis(
        averageHR: 0,
        maxHR: 0,
        zones: {},
        zoneDistribution: {},
        intensity: '알 수 없음',
      );
    }

    final values = heartRateData.map((hr) => hr.value).toList();
    final averageHR = values.reduce((a, b) => a + b) / values.length;
    final maxHR = values.reduce((a, b) => a > b ? a : b);

    // 심박수 구간 분석 (220-나이 기준)
    final maxHRTheoretical = 220 - 30; // 임시로 30세 기준
    final zones = {
      'Z1': {'min': 0.0, 'max': maxHRTheoretical * 0.6, 'name': '휴식'},
      'Z2': {
        'min': maxHRTheoretical * 0.6,
        'max': maxHRTheoretical * 0.7,
        'name': '지속력'
      },
      'Z3': {
        'min': maxHRTheoretical * 0.7,
        'max': maxHRTheoretical * 0.8,
        'name': '유산소'
      },
      'Z4': {
        'min': maxHRTheoretical * 0.8,
        'max': maxHRTheoretical * 0.9,
        'name': '역치'
      },
      'Z5': {
        'min': maxHRTheoretical * 0.9,
        'max': maxHRTheoretical.toDouble(),
        'name': '무산소'
      },
    };

    // 구간별 분포 계산
    final zoneDistribution = <String, int>{};
    for (final hr in values) {
      for (final zone in zones.entries) {
        final min = zone.value['min'] as double;
        final max = zone.value['max'] as double;
        if (hr >= min && hr < max) {
          zoneDistribution[zone.key] = (zoneDistribution[zone.key] ?? 0) + 1;
          break;
        }
      }
    }

    // 강도 평가
    String intensity;
    final z4z5Percentage =
        ((zoneDistribution['Z4'] ?? 0) + (zoneDistribution['Z5'] ?? 0)) /
            values.length;

    if (z4z5Percentage > 0.7) {
      intensity = '매우 높음';
    } else if (z4z5Percentage > 0.5) {
      intensity = '높음';
    } else if (z4z5Percentage > 0.3) {
      intensity = '보통';
    } else {
      intensity = '낮음';
    }

    return HeartRateAnalysis(
      averageHR: averageHR,
      maxHR: maxHR,
      zones: zones,
      zoneDistribution: zoneDistribution,
      intensity: intensity,
    );
  }

  /// 페이스 분석
  PaceAnalysis _analyzePace(double pace, double speed, double distance) {
    // 페이스 평가 (분/km 기준)
    String paceQuality;
    if (pace < 4.5) {
      paceQuality = '매우 빠름';
    } else if (pace < 5.5) {
      paceQuality = '빠름';
    } else if (pace < 6.5) {
      paceQuality = '보통';
    } else if (pace < 7.5) {
      paceQuality = '느림';
    } else {
      paceQuality = '매우 느림';
    }

    // 거리별 페이스 평가
    String distancePace;
    if (distance >= 10) {
      distancePace = '마라톤 준비';
    } else if (distance >= 5) {
      distancePace = '중거리';
    } else {
      distancePace = '단거리';
    }

    return PaceAnalysis(
      pace: pace,
      speed: speed,
      quality: paceQuality,
      distanceType: distancePace,
    );
  }

  /// 트렌딩 분석
  TrendingAnalysis _analyzeTrending(
    WorkoutData currentWorkout,
    List<WorkoutData>? recentWorkouts,
  ) {
    if (recentWorkouts == null || recentWorkouts.length < 2) {
      return TrendingAnalysis(
        improvement: '데이터 부족',
        consistency: '데이터 부족',
        recommendation: '더 많은 운동 데이터가 필요합니다',
      );
    }

    // 최근 5개 운동으로 트렌딩 분석
    final recent = recentWorkouts.take(5).toList();
    final distances = recent.map((w) => w.distance ?? 0).toList();
    final paces = recent
        .map((w) => w.distance != null && w.distance! > 0
            ? w.duration.inMinutes / w.distance!
            : 0)
        .toList();

    // 거리 개선도
    String improvement;
    if (distances.length >= 2) {
      final firstHalf =
          distances.take(distances.length ~/ 2).reduce((a, b) => a + b) /
              (distances.length ~/ 2);
      final secondHalf =
          distances.skip(distances.length ~/ 2).reduce((a, b) => a + b) /
              (distances.length - (distances.length ~/ 2));

      if (secondHalf > firstHalf * 1.1) {
        improvement = '거리 증가';
      } else if (secondHalf < firstHalf * 0.9) {
        improvement = '거리 감소';
      } else {
        improvement = '거리 유지';
      }
    } else {
      improvement = '분석 불가';
    }

    // 일관성 평가
    String consistency;
    final avgDistance = distances.reduce((a, b) => a + b) / distances.length;
    final variance = distances
            .map((d) => (d - avgDistance) * (d - avgDistance))
            .reduce((a, b) => a + b) /
        distances.length;
    final stdDev = sqrt(variance);

    if (stdDev / avgDistance < 0.1) {
      consistency = '매우 일관적';
    } else if (stdDev / avgDistance < 0.2) {
      consistency = '일관적';
    } else {
      consistency = '불규칙';
    }

    // 추천사항
    String recommendation;
    if (improvement == '거리 증가' && consistency == '일관적') {
      recommendation = '좋은 진행을 보이고 있습니다. 현재 페이스를 유지하세요.';
    } else if (improvement == '거리 감소') {
      recommendation = '거리가 줄어들고 있습니다. 훈련 강도를 조절해보세요.';
    } else if (consistency == '불규칙') {
      recommendation = '운동 일정을 더 규칙적으로 만들어보세요.';
    } else {
      recommendation = '꾸준한 훈련을 계속하세요.';
    }

    return TrendingAnalysis(
      improvement: improvement,
      consistency: consistency,
      recommendation: recommendation,
    );
  }

  /// 개인화된 코칭 생성
  List<CoachingAdvice> _generatePersonalizedCoaching(RunningAnalysis analysis) {
    final advice = <CoachingAdvice>[];

    // 심박수 기반 코칭
    if (analysis.heartRateAnalysis.intensity != '알 수 없음') {
      advice.add(_generateHeartRateAdvice(analysis.heartRateAnalysis));
    }

    // 페이스 기반 코칭
    advice.add(_generatePaceAdvice(analysis.paceAnalysis));

    // 트렌딩 기반 코칭
    if (analysis.trendingAnalysis.improvement != '데이터 부족') {
      advice.add(_generateTrendingAdvice(analysis.trendingAnalysis));
    }

    // 일반적인 달리기 팁
    advice.add(_generateGeneralRunningTips(analysis));

    return advice;
  }

  /// 심박수 기반 코칭
  CoachingAdvice _generateHeartRateAdvice(HeartRateAnalysis hrAnalysis) {
    String title, content, category;

    if (hrAnalysis.intensity == '매우 높음') {
      title = '심박수 관리 필요';
      content = '현재 운동 강도가 매우 높습니다. 휴식과 회복에 더 많은 시간을 투자하세요.';
      category = 'warning';
    } else if (hrAnalysis.intensity == '높음') {
      title = '강도 조절 권장';
      content = '운동 강도가 높습니다. Z2 구간(지속력) 훈련을 늘려보세요.';
      category = 'info';
    } else if (hrAnalysis.intensity == '낮음') {
      title = '강도 증가 권장';
      content = '운동 강도가 낮습니다. Z3-Z4 구간 훈련을 늘려보세요.';
      category = 'info';
    } else {
      title = '적절한 강도';
      content = '현재 운동 강도가 적절합니다. 현재 페이스를 유지하세요.';
      category = 'success';
    }

    return CoachingAdvice(
      title: title,
      content: content,
      category: category,
      icon: '❤️',
    );
  }

  /// 페이스 기반 코칭
  CoachingAdvice _generatePaceAdvice(PaceAnalysis paceAnalysis) {
    String title, content, category;

    if (paceAnalysis.quality == '매우 빠름') {
      title = '페이스 조절 필요';
      content = '현재 페이스가 매우 빠릅니다. 지속 가능한 페이스로 조절하세요.';
      category = 'warning';
    } else if (paceAnalysis.quality == '빠름') {
      title = '좋은 페이스';
      content = '현재 페이스가 좋습니다. 이 페이스를 유지하세요.';
      category = 'success';
    } else if (paceAnalysis.quality == '보통') {
      title = '안정적인 페이스';
      content = '안정적인 페이스입니다. 점진적으로 개선해보세요.';
      category = 'info';
    } else {
      title = '페이스 개선 필요';
      content = '페이스 개선이 필요합니다. 훈련 강도를 높여보세요.';
      category = 'info';
    }

    return CoachingAdvice(
      title: title,
      content: content,
      category: category,
      icon: '⚡',
    );
  }

  /// 트렌딩 기반 코칭
  CoachingAdvice _generateTrendingAdvice(TrendingAnalysis trendingAnalysis) {
    return CoachingAdvice(
      title: '트렌딩 분석',
      content: trendingAnalysis.recommendation,
      category: 'info',
      icon: '📈',
    );
  }

  /// 일반적인 달리기 팁
  CoachingAdvice _generateGeneralRunningTips(RunningAnalysis analysis) {
    String title, content;

    if (analysis.distance >= 10) {
      title = '장거리 달리기 팁';
      content = '10km 이상의 장거리는 페이스 조절이 중요합니다. 첫 2km는 워밍업으로 시작하세요.';
    } else if (analysis.distance >= 5) {
      title = '중거리 달리기 팁';
      content = '5km 달리기는 심박수 구간을 고려한 훈련이 효과적입니다.';
    } else {
      title = '단거리 달리기 팁';
      content = '단거리는 기술과 폼에 집중하세요. 보폭과 케이던스를 연습해보세요.';
    }

    return CoachingAdvice(
      title: title,
      content: content,
      category: 'tip',
      icon: '💡',
    );
  }
}

/// 달리기 코칭 데이터 클래스
class RunningCoaching {
  final WorkoutData workout;
  final RunningAnalysis analysis;
  final List<CoachingAdvice> advice;

  RunningCoaching({
    required this.workout,
    required this.analysis,
    required this.advice,
  });
}

/// 달리기 분석 데이터 클래스
class RunningAnalysis {
  final double distance;
  final int duration;
  final double pace;
  final double speed;
  final double calories;
  final HeartRateAnalysis heartRateAnalysis;
  final PaceAnalysis paceAnalysis;
  final TrendingAnalysis trendingAnalysis;

  RunningAnalysis({
    required this.distance,
    required this.duration,
    required this.pace,
    required this.speed,
    required this.calories,
    required this.heartRateAnalysis,
    required this.paceAnalysis,
    required this.trendingAnalysis,
  });
}

/// 심박수 분석 데이터 클래스
class HeartRateAnalysis {
  final double averageHR;
  final double maxHR;
  final Map<String, Map<String, dynamic>> zones;
  final Map<String, int> zoneDistribution;
  final String intensity;

  HeartRateAnalysis({
    required this.averageHR,
    required this.maxHR,
    required this.zones,
    required this.zoneDistribution,
    required this.intensity,
  });
}

/// 페이스 분석 데이터 클래스
class PaceAnalysis {
  final double pace;
  final double speed;
  final String quality;
  final String distanceType;

  PaceAnalysis({
    required this.pace,
    required this.speed,
    required this.quality,
    required this.distanceType,
  });
}

/// 트렌딩 분석 데이터 클래스
class TrendingAnalysis {
  final String improvement;
  final String consistency;
  final String recommendation;

  TrendingAnalysis({
    required this.improvement,
    required this.consistency,
    required this.recommendation,
  });
}

/// 코칭 조언 데이터 클래스
class CoachingAdvice {
  final String title;
  final String content;
  final String category; // 'success', 'warning', 'info', 'tip'
  final String icon;

  CoachingAdvice({
    required this.title,
    required this.content,
    required this.category,
    required this.icon,
  });
}
