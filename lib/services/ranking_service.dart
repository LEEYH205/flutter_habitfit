import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ranking.dart';
import '../services/points_service.dart';

/// 랭킹 서비스
class RankingService {
  static final RankingService _instance = RankingService._internal();
  factory RankingService() => _instance;
  RankingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PointsService _pointsService = PointsService();

  static const String _rankingsCollection = 'rankings';
  static const String _friendshipsCollection = 'friendships';
  // static const String _clubsCollection = 'clubs';
  // static const String _clubMembersCollection = 'club_members';

  /// 현재 기간 문자열 생성
  String _getCurrentPeriod(RankingType type) {
    final now = DateTime.now();

    switch (type) {
      case RankingType.weekly:
        // ISO 주차 계산 (예: 2024-W01)
        final weekOfYear = _getWeekOfYear(now);
        return '${now.year}-W${weekOfYear.toString().padLeft(2, '0')}';
      case RankingType.monthly:
        // 월간 (예: 2024-01)
        return '${now.year}-${now.month.toString().padLeft(2, '0')}';
      case RankingType.allTime:
        return 'all-time';
    }
  }

  /// ISO 주차 계산
  int _getWeekOfYear(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays + 1;
    // final weekday = jan1.weekday;

    // ISO 8601 주차 계산
    final week = ((dayOfYear - date.weekday + 10) / 7).floor();

    if (week < 1) {
      return _getWeekOfYear(DateTime(date.year - 1, 12, 31));
    } else if (week > 52) {
      final jan1Next = DateTime(date.year + 1, 1, 1);
      if (jan1Next.weekday <= 4) {
        return 1;
      }
    }

    return week;
  }

  /// 사용자 랭킹 데이터 생성/업데이트
  Future<bool> updateUserRanking({
    required String userId,
    required String displayName,
    String? profileImageUrl,
    required RankingCategory category,
    required RankingType type,
    required double score,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final period = _getCurrentPeriod(type);
      final now = DateTime.now();

      // 기존 랭킹 데이터 조회
      final existingQuery = await _firestore
          .collection(_rankingsCollection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.value)
          .where('type', isEqualTo: type.value)
          .where('period', isEqualTo: period)
          .limit(1)
          .get();

      final docId = existingQuery.docs.isNotEmpty
          ? existingQuery.docs.first.id
          : _firestore.collection(_rankingsCollection).doc().id;

      double previousScore = 0;
      if (existingQuery.docs.isNotEmpty) {
        previousScore =
            (existingQuery.docs.first.data()['score'] ?? 0.0).toDouble();
      }

      final rankingData = {
        'userId': userId,
        'displayName': displayName,
        'profileImageUrl': profileImageUrl,
        'score': score,
        'category': category.value,
        'type': type.value,
        'period': period,
        'metadata': {
          ...metadata ?? {},
          'scoreChange': score - previousScore,
          'lastUpdated': now.toIso8601String(),
        },
        'createdAt': existingQuery.docs.isNotEmpty
            ? existingQuery.docs.first.data()['createdAt']
            : now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _firestore
          .collection(_rankingsCollection)
          .doc(docId)
          .set(rankingData);

      // 랭킹 순위 재계산 (백그라운드에서 실행)
      _recalculateRankings(category, type, period);

      print('✅ 사용자 랭킹 업데이트 완료: $userId, ${category.displayName}');
      return true;
    } catch (e) {
      print('❌ 사용자 랭킹 업데이트 오류: $e');
      return false;
    }
  }

  /// 랭킹 순위 재계산
  Future<void> _recalculateRankings(
    RankingCategory category,
    RankingType type,
    String period,
  ) async {
    try {
      // 해당 카테고리/타입/기간의 모든 랭킹 데이터 조회 (점수 내림차순)
      final querySnapshot = await _firestore
          .collection(_rankingsCollection)
          .where('category', isEqualTo: category.value)
          .where('type', isEqualTo: type.value)
          .where('period', isEqualTo: period)
          .orderBy('score', descending: true)
          .get();

      final batch = _firestore.batch();

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final currentData = doc.data();
        final previousRank = currentData['rank'] ?? (i + 1);
        final newRank = i + 1;

        // 랭킹 변화 계산
        final rankChange = previousRank - newRank;

        // 메타데이터 업데이트
        final updatedMetadata =
            Map<String, dynamic>.from(currentData['metadata'] ?? {});
        updatedMetadata['rankChange'] = rankChange;

        batch.update(doc.reference, {
          'rank': newRank,
          'metadata': updatedMetadata,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      print('✅ 랭킹 순위 재계산 완료: ${category.displayName}, ${type.displayName}');
    } catch (e) {
      print('❌ 랭킹 순위 재계산 오류: $e');
    }
  }

  /// 랭킹 통계 조회
  Future<RankingStats?> getRankingStats({
    required RankingCategory category,
    required RankingType type,
    String? customPeriod,
  }) async {
    try {
      final period = customPeriod ?? _getCurrentPeriod(type);

      // 상위 10명 조회
      final topRankingsQuery = await _firestore
          .collection(_rankingsCollection)
          .where('category', isEqualTo: category.value)
          .where('type', isEqualTo: type.value)
          .where('period', isEqualTo: period)
          .orderBy('rank')
          .limit(10)
          .get();

      // 전체 통계 조회
      final allRankingsQuery = await _firestore
          .collection(_rankingsCollection)
          .where('category', isEqualTo: category.value)
          .where('type', isEqualTo: type.value)
          .where('period', isEqualTo: period)
          .get();

      if (allRankingsQuery.docs.isEmpty) {
        return null;
      }

      final topRankings = topRankingsQuery.docs
          .map((doc) => UserRanking.fromMap(doc.data()))
          .toList();

      // 통계 계산
      final scores = allRankingsQuery.docs
          .map((doc) => (doc.data()['score'] ?? 0.0).toDouble())
          .toList();

      final totalParticipants = scores.length;
      final averageScore = scores.fold<double>(0, (sum, score) => sum + score) /
          totalParticipants;
      final topScore =
          scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0.0;

      // 현재 사용자 랭킹 조회
      final user = _auth.currentUser;
      UserRanking? currentUserRanking;

      if (user != null) {
        final userRankingQuery = await _firestore
            .collection(_rankingsCollection)
            .where('userId', isEqualTo: user.uid)
            .where('category', isEqualTo: category.value)
            .where('type', isEqualTo: type.value)
            .where('period', isEqualTo: period)
            .limit(1)
            .get();

        if (userRankingQuery.docs.isNotEmpty) {
          currentUserRanking =
              UserRanking.fromMap(userRankingQuery.docs.first.data());
        }
      }

      return RankingStats(
        category: category,
        type: type,
        period: period,
        totalParticipants: totalParticipants,
        averageScore: averageScore,
        topScore: topScore,
        currentUserRanking: currentUserRanking,
        topRankings: topRankings,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('❌ 랭킹 통계 조회 오류: $e');
      return null;
    }
  }

  /// 사용자의 모든 랭킹 조회
  Future<List<UserRanking>> getUserRankings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_rankingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserRanking.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 사용자 랭킹 조회 오류: $e');
      return [];
    }
  }

  /// 친구 랭킹 조회
  Future<List<UserRanking>> getFriendsRankings({
    required RankingCategory category,
    required RankingType type,
    String? customPeriod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // 친구 목록 조회
      final friendships = await getFriendsList(user.uid);
      final friendIds = friendships.map((f) => f.friendId).toList();
      friendIds.add(user.uid); // 본인도 포함

      if (friendIds.isEmpty) return [];

      final period = customPeriod ?? _getCurrentPeriod(type);

      // 친구들의 랭킹 데이터 조회
      final rankings = <UserRanking>[];

      // Firestore의 'in' 쿼리 제한으로 인해 배치로 처리
      const batchSize = 10;
      for (int i = 0; i < friendIds.length; i += batchSize) {
        final batch = friendIds.skip(i).take(batchSize).toList();

        final querySnapshot = await _firestore
            .collection(_rankingsCollection)
            .where('userId', whereIn: batch)
            .where('category', isEqualTo: category.value)
            .where('type', isEqualTo: type.value)
            .where('period', isEqualTo: period)
            .get();

        final batchRankings = querySnapshot.docs
            .map((doc) => UserRanking.fromMap(doc.data()))
            .toList();

        rankings.addAll(batchRankings);
      }

      // 랭킹 데이터가 없는 친구들을 위해 기본 데이터 생성
      if (rankings.length < friendIds.length) {
        await _createMissingFriendRankings(friendIds, category, type, period);

        // 다시 조회
        rankings.clear();
        for (int i = 0; i < friendIds.length; i += batchSize) {
          final batch = friendIds.skip(i).take(batchSize).toList();

          final querySnapshot = await _firestore
              .collection(_rankingsCollection)
              .where('userId', whereIn: batch)
              .where('category', isEqualTo: category.value)
              .where('type', isEqualTo: type.value)
              .where('period', isEqualTo: period)
              .get();

          final batchRankings = querySnapshot.docs
              .map((doc) => UserRanking.fromMap(doc.data()))
              .toList();

          rankings.addAll(batchRankings);
        }
      }

      // 점수로 정렬
      rankings.sort((a, b) => b.score.compareTo(a.score));

      // 친구 그룹 내에서의 순위 재계산
      for (int i = 0; i < rankings.length; i++) {
        rankings[i] = rankings[i].copyWith(rank: i + 1);
      }

      return rankings;
    } catch (e) {
      print('❌ 친구 랭킹 조회 오류: $e');
      return [];
    }
  }

  /// 누락된 친구 랭킹 데이터 생성
  Future<void> _createMissingFriendRankings(
    List<String> friendIds,
    RankingCategory category,
    RankingType type,
    String period,
  ) async {
    try {
      final batch = _firestore.batch();
      int successCount = 0;
      int errorCount = 0;

      for (final friendId in friendIds) {
        try {
          // 기존 랭킹 데이터 확인
          final existingDoc = await _firestore
              .collection(_rankingsCollection)
              .where('userId', isEqualTo: friendId)
              .where('category', isEqualTo: category.value)
              .where('type', isEqualTo: type.value)
              .where('period', isEqualTo: period)
              .limit(1)
              .get();

          if (existingDoc.docs.isEmpty) {
            // 사용자 정보 조회 (권한 오류 처리)
            String displayName = 'Unknown User';
            String? profileImageUrl;

            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data()!;
                displayName = userData['displayName'] ?? 'Unknown User';
                profileImageUrl = userData['photoURL'];
              }
            } catch (e) {
              // 권한 오류가 발생해도 계속 진행 (기본값 사용)
              // 개별 친구의 권한 오류는 조용히 처리 (너무 많은 로그 방지)
              if (e.toString().contains('permission-denied')) {
                // 권한 오류는 조용히 처리
              } else {
                print('⚠️ 사용자 정보 조회 오류 (friendId: $friendId): $e');
              }
            }

            // 기본 점수 설정 (권한 오류 처리)
            double score = 0.0;
            if (category == RankingCategory.totalPoints) {
              try {
                // 포인트 정보 조회
                final userPoints = await _pointsService.getUserPoints(friendId);
                score = userPoints?.totalPoints.toDouble() ?? 0.0;
              } catch (e) {
                // 권한 오류가 발생해도 계속 진행 (기본값 0.0 사용)
                if (e.toString().contains('permission-denied')) {
                  // 권한 오류는 조용히 처리
                } else {
                  print('⚠️ 포인트 정보 조회 오류 (friendId: $friendId): $e');
                }
              }
            }

            // 기본 랭킹 데이터 생성 (권한 오류 처리)
            try {
              final rankingId = _firestore.collection(_rankingsCollection).doc().id;
              batch.set(
                _firestore.collection(_rankingsCollection).doc(rankingId),
                {
                  'userId': friendId,
                  'displayName': displayName,
                  'profileImageUrl': profileImageUrl,
                  'score': score,
                  'category': category.value,
                  'type': type.value,
                  'period': period,
                  'rank': 0, // 나중에 재계산됨
                  'metadata': {
                    'scoreChange': 0.0,
                    'rankChange': 0,
                    'lastUpdated': DateTime.now().toIso8601String(),
                  },
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                },
              );
              successCount++;
            } catch (e) {
              // 랭킹 데이터 쓰기 권한 오류는 조용히 처리
              if (e.toString().contains('permission-denied')) {
                errorCount++;
                // 권한 오류는 조용히 처리
              } else {
                errorCount++;
                print('⚠️ 랭킹 데이터 쓰기 오류 (friendId: $friendId): $e');
              }
            }
          }
        } catch (e) {
          // 개별 친구 처리 중 오류 발생 시 해당 친구만 건너뛰고 계속 진행
          errorCount++;
          if (!e.toString().contains('permission-denied')) {
            print('⚠️ 친구 랭킹 데이터 생성 중 오류 (friendId: $friendId): $e');
          }
        }
      }

      if (successCount > 0) {
        try {
          await batch.commit();
          print('✅ 누락된 친구 랭킹 데이터 생성 완료: $successCount개 성공, $errorCount개 실패');
        } catch (e) {
          // 배치 커밋 실패 시에도 조용히 처리
          if (e.toString().contains('permission-denied')) {
            print('⚠️ 랭킹 데이터 쓰기 권한 오류: 일부 데이터만 저장되었을 수 있습니다');
          } else {
            print('❌ 랭킹 데이터 배치 커밋 오류: $e');
          }
        }
      } else if (errorCount > 0) {
        // 모든 친구 처리 실패 시에도 조용히 처리 (권한 오류인 경우)
        if (errorCount == friendIds.length) {
          // 모든 친구에서 권한 오류가 발생한 경우 조용히 처리
        } else {
          print('⚠️ 친구 랭킹 데이터 생성 실패: 모든 친구 처리 중 오류 발생 ($errorCount개)');
        }
      }
    } catch (e) {
      // 전체 배치 처리 실패 시에도 앱이 계속 작동하도록 함
      if (e.toString().contains('permission-denied')) {
        // 권한 오류는 조용히 처리
      } else {
        print('❌ 누락된 친구 랭킹 데이터 생성 오류: $e');
      }
    }
  }

  /// 포인트 기반 랭킹 자동 업데이트
  Future<void> updatePointsRanking(String userId) async {
    try {
      final userPoints = await _pointsService.getUserPoints(userId);
      if (userPoints == null) return;

      final user = _auth.currentUser;
      if (user == null) return;

      // 주간 포인트 랭킹 업데이트
      await updateUserRanking(
        userId: userId,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        category: RankingCategory.totalPoints,
        type: RankingType.weekly,
        score: userPoints.totalPoints.toDouble(),
        metadata: {
          'level': userPoints.currentLevel,
          'levelProgress': userPoints.levelProgress,
        },
      );

      // 월간 포인트 랭킹 업데이트
      await updateUserRanking(
        userId: userId,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        category: RankingCategory.totalPoints,
        type: RankingType.monthly,
        score: userPoints.totalPoints.toDouble(),
        metadata: {
          'level': userPoints.currentLevel,
          'levelProgress': userPoints.levelProgress,
        },
      );

      // 전체 포인트 랭킹 업데이트
      await updateUserRanking(
        userId: userId,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        category: RankingCategory.totalPoints,
        type: RankingType.allTime,
        score: userPoints.totalPoints.toDouble(),
        metadata: {
          'level': userPoints.currentLevel,
          'levelProgress': userPoints.levelProgress,
        },
      );
    } catch (e) {
      print('❌ 포인트 랭킹 자동 업데이트 오류: $e');
    }
  }

  /// 습관 완성률 랭킹 업데이트
  Future<void> updateHabitCompletionRanking(
      String userId, double completionRate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 주간 습관 완성률 랭킹 업데이트
      await updateUserRanking(
        userId: userId,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        category: RankingCategory.habitCompletion,
        type: RankingType.weekly,
        score: completionRate,
      );

      // 월간 습관 완성률 랭킹 업데이트
      await updateUserRanking(
        userId: userId,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        category: RankingCategory.habitCompletion,
        type: RankingType.monthly,
        score: completionRate,
      );
    } catch (e) {
      print('❌ 습관 완성률 랭킹 업데이트 오류: $e');
    }
  }

  /// 친구 관계 관리

  /// 친구 요청 보내기
  Future<bool> sendFriendRequest(String friendId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (user.uid == friendId) {
        throw Exception('자기 자신에게는 친구 요청을 보낼 수 없습니다');
      }

      // 기존 친구 관계 확인
      final existingFriendship =
          await _checkExistingFriendship(user.uid, friendId);
      if (existingFriendship != null) {
        throw Exception('이미 친구이거나 요청이 진행 중입니다');
      }

      final now = DateTime.now();
      // final friendshipId = _firestore.collection(_friendshipsCollection).doc().id;

      // 친구 정보 조회
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();

      if (!friendDoc.exists) {
        throw Exception('존재하지 않는 사용자입니다');
      }

      final friendData = friendDoc.data()!;

      // 양방향 친구 관계 생성
      final batch = _firestore.batch();

      // 요청자 -> 친구
      batch.set(
        _firestore
            .collection(_friendshipsCollection)
            .doc('${user.uid}_$friendId'),
        {
          'id': '${user.uid}_$friendId',
          'userId': user.uid,
          'friendId': friendId,
          'friendDisplayName': friendData['displayName'] ?? 'Unknown User',
          'friendProfileImageUrl': friendData['photoURL'],
          'status': FriendshipStatus.pending.value,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );

      // 친구 -> 요청자 (수신된 요청)
      batch.set(
        _firestore
            .collection(_friendshipsCollection)
            .doc('${friendId}_${user.uid}'),
        {
          'id': '${friendId}_${user.uid}',
          'userId': friendId,
          'friendId': user.uid,
          'friendDisplayName': user.displayName ?? 'Unknown User',
          'friendProfileImageUrl': user.photoURL,
          'status': FriendshipStatus.pending.value,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );

      await batch.commit();

      print('✅ 친구 요청 전송 완료: ${user.uid} -> $friendId');
      return true;
    } catch (e) {
      print('❌ 친구 요청 전송 오류: $e');
      return false;
    }
  }

  /// 친구 요청 수락
  Future<bool> acceptFriendRequest(String friendId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final batch = _firestore.batch();
      final now = DateTime.now();

      // 양방향 친구 관계 상태 업데이트
      batch.update(
        _firestore
            .collection(_friendshipsCollection)
            .doc('${user.uid}_$friendId'),
        {
          'status': FriendshipStatus.accepted.value,
          'updatedAt': now.toIso8601String(),
        },
      );

      batch.update(
        _firestore
            .collection(_friendshipsCollection)
            .doc('${friendId}_${user.uid}'),
        {
          'status': FriendshipStatus.accepted.value,
          'updatedAt': now.toIso8601String(),
        },
      );

      await batch.commit();

      print('✅ 친구 요청 수락 완료: ${user.uid} <-> $friendId');
      return true;
    } catch (e) {
      print('❌ 친구 요청 수락 오류: $e');
      return false;
    }
  }

  /// 친구 요청 거절/친구 삭제
  Future<bool> rejectOrRemoveFriend(String friendId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final batch = _firestore.batch();

      // 양방향 친구 관계 삭제
      batch.delete(
        _firestore
            .collection(_friendshipsCollection)
            .doc('${user.uid}_$friendId'),
      );

      batch.delete(
        _firestore
            .collection(_friendshipsCollection)
            .doc('${friendId}_${user.uid}'),
      );

      await batch.commit();

      print('✅ 친구 관계 삭제 완료: ${user.uid} <-> $friendId');
      return true;
    } catch (e) {
      print('❌ 친구 관계 삭제 오류: $e');
      return false;
    }
  }

  /// 친구 목록 조회
  Future<List<Friendship>> getFriendsList(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_friendshipsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: FriendshipStatus.accepted.value)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Friendship.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 친구 목록 조회 오류: $e');
      return [];
    }
  }

  /// 받은 친구 요청 조회
  Future<List<Friendship>> getPendingFriendRequests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_friendshipsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: FriendshipStatus.pending.value)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Friendship.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 친구 요청 조회 오류: $e');
      return [];
    }
  }

  /// 기존 친구 관계 확인
  Future<Friendship?> _checkExistingFriendship(
      String userId, String friendId) async {
    try {
      final doc = await _firestore
          .collection(_friendshipsCollection)
          .doc('${userId}_$friendId')
          .get();

      if (doc.exists) {
        return Friendship.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 친구 관계 확인 오류: $e');
      return null;
    }
  }

  /// 사용자 검색 (친구 추가용)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final user = _auth.currentUser;
      if (user == null) return [];

      // 이메일 또는 표시명으로 검색
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}z')
          .limit(10)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;

        // 본인은 제외
        if (userId == user.uid) continue;

        // 기존 친구 관계 확인
        final friendship = await _checkExistingFriendship(user.uid, userId);

        results.add({
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown User',
          'email': userData['email'] ?? '',
          'photoURL': userData['photoURL'],
          'friendshipStatus': friendship?.status.value,
        });
      }

      return results;
    } catch (e) {
      print('❌ 사용자 검색 오류: $e');
      return [];
    }
  }
}
