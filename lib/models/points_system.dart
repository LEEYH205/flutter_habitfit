import 'package:cloud_firestore/cloud_firestore.dart';

/// 포인트 타입
enum PointType {
  habitCompleted('습관 완료', 'habit_completed'),
  workoutCompleted('운동 완료', 'workout_completed'),
  streakAchieved('연속 달성', 'streak_achieved'),
  goalAchieved('목표 달성', 'goal_achieved'),
  dailyChallenge('일일 챌린지', 'daily_challenge'),
  weeklyChallenge('주간 챌린지', 'weekly_challenge'),
  monthlyChallenge('월간 챌린지', 'monthly_challenge'),
  socialShare('소셜 공유', 'social_share'),
  reviewWritten('리뷰 작성', 'review_written'),
  friendInvited('친구 초대', 'friend_invited'),
  achievementUnlocked('업적 달성', 'achievement_unlocked'),
  bonus('보너스', 'bonus');

  const PointType(this.displayName, this.value);

  final String displayName;
  final String value;

  static PointType fromString(String value) {
    return PointType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PointType.bonus,
    );
  }
}

/// 포인트 획득 기록
class PointEarned {
  final String id;
  final String userId;
  final PointType type;
  final int points;
  final String? description;
  final String? relatedId; // 관련된 습관, 운동 등의 ID
  final DateTime earnedAt;
  final Map<String, dynamic> metadata;

  PointEarned({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    this.description,
    this.relatedId,
    required this.earnedAt,
    this.metadata = const {},
  });

  factory PointEarned.fromMap(Map<String, dynamic> map) {
    // earnedAt 필드 처리 - Timestamp 또는 String 모두 지원
    DateTime earnedAt;
    final earnedAtValue = map['earnedAt'];
    if (earnedAtValue == null) {
      earnedAt = DateTime.now();
    } else if (earnedAtValue is Timestamp) {
      earnedAt = earnedAtValue.toDate();
    } else if (earnedAtValue is String) {
      earnedAt = DateTime.parse(earnedAtValue);
    } else {
      earnedAt = DateTime.now();
    }

    return PointEarned(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: PointType.fromString(map['type'] ?? 'bonus'),
      points: map['points'] ?? 0,
      description: map['description'],
      relatedId: map['relatedId'],
      earnedAt: earnedAt,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'points': points,
      'description': description,
      'relatedId': relatedId,
      'earnedAt': earnedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 사용자 포인트 정보
class UserPoints {
  final String userId;
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final int pointsInCurrentLevel;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.currentLevel,
    required this.pointsToNextLevel,
    required this.pointsInCurrentLevel,
    required this.lastUpdated,
    this.metadata = const {},
  });

  /// 다음 레벨까지 필요한 포인트
  int get pointsNeededForNextLevel {
    return pointsToNextLevel - pointsInCurrentLevel;
  }

  /// 현재 레벨의 진행률 (0.0 ~ 1.0)
  double get levelProgress {
    final currentLevelRequiredPoints =
        LevelCalculator.getPointsForLevel(currentLevel + 1);
    if (currentLevelRequiredPoints == 0) return 1.0;
    return (pointsInCurrentLevel / currentLevelRequiredPoints).clamp(0.0, 1.0);
  }

  /// 레벨명
  String get levelName {
    if (currentLevel < 5) return '초보자';
    if (currentLevel < 10) return '습관러';
    if (currentLevel < 20) return '달성자';
    if (currentLevel < 30) return '마스터';
    if (currentLevel < 50) return '전문가';
    if (currentLevel < 100) return '고수';
    return '레전드';
  }

  /// 레벨별 색상
  int get levelColor {
    if (currentLevel < 5) return 0xff9e9e9e; // 회색
    if (currentLevel < 10) return 0xff4caf50; // 초록색
    if (currentLevel < 20) return 0xff2196f3; // 파란색
    if (currentLevel < 30) return 0xff9c27b0; // 보라색
    if (currentLevel < 50) return 0xffff9800; // 주황색
    if (currentLevel < 100) return 0xfff44336; // 빨간색
    return 0xffe91e63; // 핑크색
  }

  /// 레벨별 아이콘
  String get levelIcon {
    if (currentLevel < 5) return '🌱';
    if (currentLevel < 10) return '🌿';
    if (currentLevel < 20) return '🌳';
    if (currentLevel < 30) return '🏆';
    if (currentLevel < 50) return '👑';
    if (currentLevel < 100) return '💎';
    return '🌟';
  }

  factory UserPoints.fromMap(Map<String, dynamic> map) {
    // lastUpdated 필드 처리 - Timestamp 또는 String 모두 지원
    DateTime lastUpdated;
    final lastUpdatedValue = map['lastUpdated'];
    if (lastUpdatedValue == null) {
      lastUpdated = DateTime.now();
    } else if (lastUpdatedValue is Timestamp) {
      lastUpdated = lastUpdatedValue.toDate();
    } else if (lastUpdatedValue is String) {
      lastUpdated = DateTime.parse(lastUpdatedValue);
    } else {
      lastUpdated = DateTime.now();
    }

    return UserPoints(
      userId: map['userId'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      pointsToNextLevel: map['pointsToNextLevel'] ?? 0,
      pointsInCurrentLevel: map['pointsInCurrentLevel'] ?? 0,
      lastUpdated: lastUpdated,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'pointsToNextLevel': pointsToNextLevel,
      'pointsInCurrentLevel': pointsInCurrentLevel,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserPoints copyWith({
    String? userId,
    int? totalPoints,
    int? currentLevel,
    int? pointsToNextLevel,
    int? pointsInCurrentLevel,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return UserPoints(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      pointsInCurrentLevel: pointsInCurrentLevel ?? this.pointsInCurrentLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 레벨별 요구 포인트 계산
class LevelCalculator {
  /// 특정 레벨에 도달하기 위한 총 포인트 계산
  static int getTotalPointsForLevel(int level) {
    if (level <= 1) return 0;

    // 레벨별 포인트 요구량 (기하급수적 증가)
    int totalPoints = 0;
    for (int i = 2; i <= level; i++) {
      totalPoints += getPointsForLevel(i);
    }
    return totalPoints;
  }

  /// 특정 레벨에 도달하기 위한 포인트 계산
  static int getPointsForLevel(int level,
      {int? basePoints, double? multiplier}) {
    if (level <= 1) return 0;

    // 레벨이 올라갈수록 더 많은 포인트 필요
    // 공식: basePoints * (level - 1) * multiplier^(level - 2)
    final base = basePoints ?? 100;
    final mult = multiplier ?? 1.2;
    return (base * (level - 1) * (mult * (level - 2))).round();
  }

  /// 포인트로부터 레벨 계산
  static int getLevelFromPoints(int totalPoints) {
    if (totalPoints < 0) return 1;

    int level = 1;
    int requiredPoints = 0;

    while (requiredPoints <= totalPoints) {
      level++;
      requiredPoints += getPointsForLevel(level);
    }

    return level - 1;
  }

  /// 현재 레벨에서의 포인트 계산
  static int getPointsInCurrentLevel(int totalPoints) {
    final currentLevel = getLevelFromPoints(totalPoints);
    final previousLevelPoints = getTotalPointsForLevel(currentLevel);
    return totalPoints - previousLevelPoints;
  }

  /// 다음 레벨까지 필요한 포인트 계산
  static int getPointsToNextLevel(int totalPoints) {
    final currentLevel = getLevelFromPoints(totalPoints);
    final nextLevelPoints = getTotalPointsForLevel(currentLevel + 1);
    return nextLevelPoints - totalPoints;
  }
}

/// 업적 시스템
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsReward;
  final String category;
  final Map<String, dynamic> requirements;
  final bool isSecret;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsReward,
    required this.category,
    required this.requirements,
    this.isSecret = false,
    this.unlockedAt,
  });

  /// 업적 달성 여부 확인
  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromMap(Map<String, dynamic> map) {
    // unlockedAt 필드 처리 - Timestamp 또는 String 모두 지원
    DateTime? unlockedAt;
    final unlockedAtValue = map['unlockedAt'];
    if (unlockedAtValue != null) {
      if (unlockedAtValue is Timestamp) {
        unlockedAt = unlockedAtValue.toDate();
      } else if (unlockedAtValue is String) {
        unlockedAt = DateTime.parse(unlockedAtValue);
      }
    }

    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      pointsReward: map['pointsReward'] ?? 0,
      category: map['category'] ?? 'general',
      requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
      isSecret: map['isSecret'] ?? false,
      unlockedAt: unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'pointsReward': pointsReward,
      'category': category,
      'requirements': requirements,
      'isSecret': isSecret,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

/// 포인트 획득 규칙
class PointRule {
  final PointType type;
  final int basePoints;
  final List<PointMultiplier> multipliers;

  PointRule({
    required this.type,
    required this.basePoints,
    this.multipliers = const [],
  });

  /// 최종 포인트 계산
  int calculatePoints(Map<String, dynamic> context) {
    int points = basePoints;

    for (final multiplier in multipliers) {
      if (multiplier.condition(context)) {
        points = (points * multiplier.multiplier).round();
      }
    }

    return points;
  }
}

/// 포인트 배수
class PointMultiplier {
  final String name;
  final double multiplier;
  final bool Function(Map<String, dynamic> context) condition;

  PointMultiplier({
    required this.name,
    required this.multiplier,
    required this.condition,
  });
}
