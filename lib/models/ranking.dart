import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 랭킹 타입
enum RankingType {
  weekly('주간', 'weekly'),
  monthly('월간', 'monthly'),
  allTime('전체', 'all_time');

  const RankingType(this.displayName, this.value);
  final String displayName;
  final String value;
}

/// 랭킹 카테고리
enum RankingCategory {
  totalPoints('총 포인트', 'total_points', Icons.star),
  habitCompletion('습관 완성률', 'habit_completion', Icons.check_circle),
  runningDistance('러닝 거리', 'running_distance', Icons.directions_run),
  workoutTime('운동 시간', 'workout_time', Icons.fitness_center),
  streak('연속 일수', 'streak', Icons.local_fire_department);

  const RankingCategory(this.displayName, this.value, this.icon);
  final String displayName;
  final String value;
  final IconData icon;
}

/// 사용자 랭킹 정보
class UserRanking {
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final int rank;
  final double score;
  final RankingCategory category;
  final RankingType type;
  final String period; // '2024-W01', '2024-01' 등
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserRanking({
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    required this.rank,
    required this.score,
    required this.category,
    required this.type,
    required this.period,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 스코어를 사용자 친화적 형태로 포맷
  String get formattedScore {
    switch (category) {
      case RankingCategory.totalPoints:
        return '${score.toStringAsFixed(0)}점';
      case RankingCategory.habitCompletion:
        return '${(score * 100).toStringAsFixed(1)}%';
      case RankingCategory.runningDistance:
        return '${score.toStringAsFixed(1)}km';
      case RankingCategory.workoutTime:
        return '${(score / 60).toStringAsFixed(0)}분';
      case RankingCategory.streak:
        return '${score.toStringAsFixed(0)}일';
    }
  }

  /// 랭킹 변화량 (metadata에서 추출)
  int get rankChange => metadata['rankChange'] ?? 0;

  /// 스코어 변화량
  double get scoreChange => metadata['scoreChange'] ?? 0.0;

  /// 이전 기간 대비 변화량을 사용자 친화적 형태로 포맷
  String get formattedScoreChange {
    if (scoreChange == 0) return '변화 없음';

    final prefix = scoreChange > 0 ? '+' : '';
    switch (category) {
      case RankingCategory.totalPoints:
        return '$prefix${scoreChange.toStringAsFixed(0)}점';
      case RankingCategory.habitCompletion:
        return '$prefix${(scoreChange * 100).toStringAsFixed(1)}%';
      case RankingCategory.runningDistance:
        return '$prefix${scoreChange.toStringAsFixed(1)}km';
      case RankingCategory.workoutTime:
        return '$prefix${(scoreChange / 60).toStringAsFixed(0)}분';
      case RankingCategory.streak:
        return '$prefix${scoreChange.toStringAsFixed(0)}일';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'rank': rank,
      'score': score,
      'category': category.value,
      'type': type.value,
      'period': period,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserRanking.fromMap(Map<String, dynamic> map) {
    return UserRanking(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      rank: map['rank'] ?? 0,
      score: (map['score'] ?? 0.0).toDouble(),
      category: RankingCategory.values.firstWhere(
        (cat) => cat.value == map['category'],
        orElse: () => RankingCategory.totalPoints,
      ),
      type: RankingType.values.firstWhere(
        (type) => type.value == map['type'],
        orElse: () => RankingType.weekly,
      ),
      period: map['period'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  UserRanking copyWith({
    String? userId,
    String? displayName,
    String? profileImageUrl,
    int? rank,
    double? score,
    RankingCategory? category,
    RankingType? type,
    String? period,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRanking(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      category: category ?? this.category,
      type: type ?? this.type,
      period: period ?? this.period,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 랭킹 통계
class RankingStats {
  final RankingCategory category;
  final RankingType type;
  final String period;
  final int totalParticipants;
  final double averageScore;
  final double topScore;
  final UserRanking? currentUserRanking;
  final List<UserRanking> topRankings; // 상위 10명
  final DateTime lastUpdated;

  const RankingStats({
    required this.category,
    required this.type,
    required this.period,
    required this.totalParticipants,
    required this.averageScore,
    required this.topScore,
    this.currentUserRanking,
    required this.topRankings,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.value,
      'type': type.value,
      'period': period,
      'totalParticipants': totalParticipants,
      'averageScore': averageScore,
      'topScore': topScore,
      'currentUserRanking': currentUserRanking?.toMap(),
      'topRankings': topRankings.map((ranking) => ranking.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory RankingStats.fromMap(Map<String, dynamic> map) {
    return RankingStats(
      category: RankingCategory.values.firstWhere(
        (cat) => cat.value == map['category'],
        orElse: () => RankingCategory.totalPoints,
      ),
      type: RankingType.values.firstWhere(
        (type) => type.value == map['type'],
        orElse: () => RankingType.weekly,
      ),
      period: map['period'] ?? '',
      totalParticipants: map['totalParticipants'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      topScore: (map['topScore'] ?? 0.0).toDouble(),
      currentUserRanking: map['currentUserRanking'] != null
          ? UserRanking.fromMap(map['currentUserRanking'])
          : null,
      topRankings: (map['topRankings'] as List<dynamic>?)
              ?.map((rankingMap) => UserRanking.fromMap(rankingMap))
              .toList() ??
          [],
      lastUpdated: _parseDateTime(map['lastUpdated']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}

/// 친구 관계
class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final String friendDisplayName;
  final String? friendProfileImageUrl;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendDisplayName,
    this.friendProfileImageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'friendDisplayName': friendDisplayName,
      'friendProfileImageUrl': friendProfileImageUrl,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      friendId: map['friendId'] ?? '',
      friendDisplayName: map['friendDisplayName'] ?? '',
      friendProfileImageUrl: map['friendProfileImageUrl'],
      status: FriendshipStatus.values.firstWhere(
        (status) => status.value == map['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}

/// 친구 관계 상태
enum FriendshipStatus {
  pending('대기 중', 'pending'),
  accepted('수락됨', 'accepted'),
  blocked('차단됨', 'blocked');

  const FriendshipStatus(this.displayName, this.value);
  final String displayName;
  final String value;
}

/// 클럽 정보
class Club {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final List<String> memberIds;
  final List<String> adminIds;
  final ClubType type;
  final bool isPublic;
  final int maxMembers;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Club({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.memberIds,
    required this.adminIds,
    required this.type,
    required this.isPublic,
    required this.maxMembers,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  int get memberCount => memberIds.length;
  bool get isFull => memberCount >= maxMembers;

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);
  bool isMember(String userId) => memberIds.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'type': type.value,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      type: ClubType.values.firstWhere(
        (type) => type.value == map['type'],
        orElse: () => ClubType.general,
      ),
      isPublic: map['isPublic'] ?? true,
      maxMembers: map['maxMembers'] ?? 50,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? ownerId,
    String? ownerName,
    List<String>? memberIds,
    List<String>? adminIds,
    ClubType? type,
    bool? isPublic,
    int? maxMembers,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      type: type ?? this.type,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 클럽 타입
enum ClubType {
  general('일반', 'general', Icons.group),
  running('러닝', 'running', Icons.directions_run),
  workout('운동', 'workout', Icons.fitness_center),
  habit('습관', 'habit', Icons.check_circle),
  study('스터디', 'study', Icons.school);

  const ClubType(this.displayName, this.value, this.icon);
  final String displayName;
  final String value;
  final IconData icon;
}

/// 클럽 멤버 정보
class ClubMember {
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final ClubMemberRole role;
  final DateTime joinedAt;
  final Map<String, dynamic> stats; // 클럽 내 활동 통계

  const ClubMember({
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    required this.role,
    required this.joinedAt,
    required this.stats,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'stats': stats,
    };
  }

  factory ClubMember.fromMap(Map<String, dynamic> map) {
    return ClubMember(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      role: ClubMemberRole.values.firstWhere(
        (role) => role.value == map['role'],
        orElse: () => ClubMemberRole.member,
      ),
      joinedAt: _parseDateTime(map['joinedAt']),
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}

/// 클럽 멤버 역할
enum ClubMemberRole {
  owner('소유자', 'owner'),
  admin('관리자', 'admin'),
  member('멤버', 'member');

  const ClubMemberRole(this.displayName, this.value);
  final String displayName;
  final String value;
}
