/// 사용자 레벨 타입
enum UserLevelType {
  free('무료', 'free', 0),
  premium('유료개월', 'premium', 1),
  coach('코치', 'coach', 2),
  admin('관리자', 'admin', 3);

  const UserLevelType(this.displayName, this.value, this.priority);

  final String displayName;
  final String value;
  final int priority; // 숫자가 높을수록 권한이 높음

  static UserLevelType fromString(String value) {
    return UserLevelType.values.firstWhere(
      (level) => level.value == value,
      orElse: () => UserLevelType.free,
    );
  }

  /// 권한 비교
  bool hasPermission(UserLevelType requiredLevel) {
    return priority >= requiredLevel.priority;
  }

  /// 다음 레벨로 업그레이드 가능한지 확인
  bool canUpgrade() {
    return this != UserLevelType.admin;
  }

  /// 다음 레벨 반환
  UserLevelType? getNextLevel() {
    switch (this) {
      case UserLevelType.free:
        return UserLevelType.premium;
      case UserLevelType.premium:
        return UserLevelType.coach;
      case UserLevelType.coach:
        return UserLevelType.admin;
      case UserLevelType.admin:
        return null;
    }
  }

  /// 레벨별 색상
  int get colorValue {
    switch (this) {
      case UserLevelType.free:
        return 0xff9e9e9e; // 회색
      case UserLevelType.premium:
        return 0xff2196f3; // 파란색
      case UserLevelType.coach:
        return 0xff4caf50; // 초록색
      case UserLevelType.admin:
        return 0xfff44336; // 빨간색
    }
  }

  /// 레벨별 아이콘
  String get iconName {
    switch (this) {
      case UserLevelType.free:
        return '👤';
      case UserLevelType.premium:
        return '⭐';
      case UserLevelType.coach:
        return '🏆';
      case UserLevelType.admin:
        return '👑';
    }
  }
}

/// 사용자 레벨 정보 모델
class UserLevel {
  final String userId;
  final UserLevelType level;
  final DateTime? premiumExpiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  UserLevel({
    required this.userId,
    required this.level,
    this.premiumExpiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// 프리미엄 만료 여부 확인
  bool get isPremiumExpired {
    if (level != UserLevelType.premium || premiumExpiryDate == null) {
      return false;
    }
    return DateTime.now().isAfter(premiumExpiryDate!);
  }

  /// 프리미엄 활성 상태 확인
  bool get isPremiumActive {
    return level == UserLevelType.premium && !isPremiumExpired;
  }

  /// 코치 권한 확인
  bool get isCoach {
    return level == UserLevelType.coach;
  }

  /// 관리자 권한 확인
  bool get isAdmin {
    return level == UserLevelType.admin;
  }

  /// 특정 기능 사용 가능 여부 확인
  bool canUseFeature(String featureName) {
    switch (featureName) {
      case 'advanced_analytics':
        return level.hasPermission(UserLevelType.premium);
      case 'personal_coaching':
        return level.hasPermission(UserLevelType.coach);
      case 'admin_panel':
        return level.hasPermission(UserLevelType.admin);
      case 'unlimited_habits':
        return level.hasPermission(UserLevelType.premium);
      case 'custom_workouts':
        return level.hasPermission(UserLevelType.premium);
      case 'data_export':
        return level.hasPermission(UserLevelType.premium);
      case 'priority_support':
        return level.hasPermission(UserLevelType.premium);
      default:
        return true; // 기본 기능은 모든 사용자가 사용 가능
    }
  }

  /// 레벨별 혜택 목록
  List<String> get benefits {
    switch (level) {
      case UserLevelType.free:
        return [
          '기본 습관 추적',
          '일일 리포트',
          '기본 운동 추천',
          '커뮤니티 참여',
        ];
      case UserLevelType.premium:
        return [
          '무제한 습관 추적',
          '고급 분석 및 인사이트',
          '맞춤형 운동 계획',
          '데이터 내보내기',
          '우선 고객 지원',
          '광고 제거',
        ];
      case UserLevelType.coach:
        return [
          '모든 프리미엄 기능',
          '개인 코칭 서비스',
          '고급 AI 추천',
          '전용 커뮤니티',
          '코치 인증 배지',
        ];
      case UserLevelType.admin:
        return [
          '모든 기능 접근',
          '관리자 패널',
          '시스템 설정',
          '사용자 관리',
          '데이터 분석 도구',
        ];
    }
  }

  /// 레벨별 제한사항
  List<String> get limitations {
    switch (level) {
      case UserLevelType.free:
        return [
          '습관 5개까지',
          '기본 리포트만',
          '광고 표시',
          '제한된 운동 종류',
        ];
      case UserLevelType.premium:
        return [
          '개인 코칭 제외',
        ];
      case UserLevelType.coach:
        return [
          '관리자 기능 제외',
        ];
      case UserLevelType.admin:
        return [];
    }
  }

  factory UserLevel.fromMap(Map<String, dynamic> map) {
    return UserLevel(
      userId: map['userId'] ?? '',
      level: UserLevelType.fromString(map['level'] ?? 'free'),
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? DateTime.parse(map['premiumExpiryDate'])
          : null,
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'level': level.value,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserLevel copyWith({
    String? userId,
    UserLevelType? level,
    DateTime? premiumExpiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserLevel(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserLevel(userId: $userId, level: ${level.displayName}, premiumExpiryDate: $premiumExpiryDate)';
  }
}

/// 레벨 업그레이드 옵션
class UpgradeOption {
  final UserLevelType targetLevel;
  final String title;
  final String description;
  final double price;
  final String currency;
  final Duration duration;
  final List<String> benefits;
  final bool isPopular;

  UpgradeOption({
    required this.targetLevel,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.duration,
    required this.benefits,
    this.isPopular = false,
  });

  factory UpgradeOption.fromMap(Map<String, dynamic> map) {
    return UpgradeOption(
      targetLevel: UserLevelType.fromString(map['targetLevel'] ?? 'premium'),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'KRW',
      duration: Duration(days: map['durationDays'] ?? 30),
      benefits: List<String>.from(map['benefits'] ?? []),
      isPopular: map['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetLevel': targetLevel.value,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'durationDays': duration.inDays,
      'benefits': benefits,
      'isPopular': isPopular,
    };
  }
}
