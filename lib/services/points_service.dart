import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/points_system.dart';

/// 포인트 시스템 관리 서비스
class PointsService {
  static final PointsService _instance = PointsService._internal();
  factory PointsService() => _instance;
  PointsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _pointsCollection = 'user_points';
  static const String _pointsEarnedCollection = 'points_earned';
  static const String _achievementsCollection = 'achievements';

  /// 포인트 획득
  Future<bool> earnPoints({
    required PointType type,
    int? customPoints,
    String? description,
    String? relatedId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 포인트 계산
      final points = customPoints ?? _calculatePoints(type, context ?? {});

      // 포인트 획득 기록 생성
      final pointEarned = PointEarned(
        id: _firestore.collection(_pointsEarnedCollection).doc().id,
        userId: user.uid,
        type: type,
        points: points,
        description: description,
        relatedId: relatedId,
        earnedAt: DateTime.now(),
        metadata: context ?? {},
      );

      // Firestore에 기록 저장
      await _firestore
          .collection(_pointsEarnedCollection)
          .doc(pointEarned.id)
          .set(pointEarned.toMap());

      // 사용자 포인트 업데이트
      await _updateUserPoints(points);

      // 업적 확인
      await _checkAchievements();

      print('✅ 포인트 획득: ${type.displayName} (+$points)');
      return true;
    } catch (e) {
      print('❌ 포인트 획득 오류: $e');
      return false;
    }
  }

  /// 습관 완료 시 포인트 획득
  Future<bool> earnHabitCompletedPoints({
    required String habitId,
    required String habitName,
    int streak = 1,
    bool isFirstTime = false,
  }) async {
    try {
      int points = PointType.habitCompleted.basePoints;

      // 연속 달성 보너스
      if (streak > 1) {
        points += (streak - 1) * 5; // 연속일수당 5포인트 추가
      }

      // 첫 완료 보너스
      if (isFirstTime) {
        points += 20;
      }

      return await earnPoints(
        type: PointType.habitCompleted,
        customPoints: points,
        description: '$habitName 완료 (연속 $streak일)',
        relatedId: habitId,
        context: {
          'habitName': habitName,
          'streak': streak,
          'isFirstTime': isFirstTime,
        },
      );
    } catch (e) {
      print('❌ 습관 완료 포인트 획득 오류: $e');
      return false;
    }
  }

  /// 운동 완료 시 포인트 획득
  Future<bool> earnWorkoutCompletedPoints({
    required String workoutType,
    required Duration duration,
    double? calories,
    int? heartRate,
  }) async {
    try {
      int points = PointType.workoutCompleted.basePoints;

      // 운동 시간 보너스 (10분당 5포인트)
      points += (duration.inMinutes ~/ 10) * 5;

      // 칼로리 보너스 (100칼로리당 10포인트)
      if (calories != null) {
        points += (calories ~/ 100) * 10;
      }

      return await earnPoints(
        type: PointType.workoutCompleted,
        customPoints: points,
        description: '$workoutType 완료 (${duration.inMinutes}분)',
        context: {
          'workoutType': workoutType,
          'duration': duration.inMinutes,
          'calories': calories,
          'heartRate': heartRate,
        },
      );
    } catch (e) {
      print('❌ 운동 완료 포인트 획득 오류: $e');
      return false;
    }
  }

  /// 목표 달성 시 포인트 획득
  Future<bool> earnGoalAchievedPoints({
    required String goalType,
    required String goalDescription,
    int? targetValue,
    int? achievedValue,
  }) async {
    try {
      int points = PointType.goalAchieved.basePoints;

      // 목표 달성도에 따른 보너스
      if (targetValue != null && achievedValue != null) {
        final achievementRate = achievedValue / targetValue;
        if (achievementRate >= 1.5) {
          points += 50; // 목표의 150% 달성
        } else if (achievementRate >= 1.2) {
          points += 25; // 목표의 120% 달성
        }
      }

      return await earnPoints(
        type: PointType.goalAchieved,
        customPoints: points,
        description: '$goalDescription 목표 달성',
        context: {
          'goalType': goalType,
          'goalDescription': goalDescription,
          'targetValue': targetValue,
          'achievedValue': achievedValue,
        },
      );
    } catch (e) {
      print('❌ 목표 달성 포인트 획득 오류: $e');
      return false;
    }
  }

  /// 현재 사용자 포인트 정보 가져오기
  Future<UserPoints?> getCurrentUserPoints() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection(_pointsCollection).doc(user.uid).get();

      if (doc.exists) {
        return UserPoints.fromMap(doc.data()!);
      } else {
        // 기본 포인트 정보 생성
        return await _createDefaultUserPoints(user.uid);
      }
    } catch (e) {
      print('❌ 사용자 포인트 조회 오류: $e');
      return null;
    }
  }

  /// 기본 사용자 포인트 정보 생성
  Future<UserPoints> _createDefaultUserPoints(String userId) async {
    try {
      final now = DateTime.now();
      final userPoints = UserPoints(
        userId: userId,
        totalPoints: 0,
        currentLevel: 1,
        pointsToNextLevel: LevelCalculator.getPointsForLevel(2),
        pointsInCurrentLevel: 0,
        lastUpdated: now,
      );

      await _firestore
          .collection(_pointsCollection)
          .doc(userId)
          .set(userPoints.toMap());

      print('✅ 기본 사용자 포인트 정보 생성 완료');
      return userPoints;
    } catch (e) {
      print('❌ 기본 사용자 포인트 정보 생성 오류: $e');
      rethrow;
    }
  }

  /// 사용자 포인트 업데이트
  Future<void> _updateUserPoints(int earnedPoints) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc =
          await _firestore.collection(_pointsCollection).doc(user.uid).get();

      UserPoints userPoints;
      if (doc.exists) {
        userPoints = UserPoints.fromMap(doc.data()!);
      } else {
        userPoints = await _createDefaultUserPoints(user.uid);
      }

      // 새로운 총 포인트 계산
      final newTotalPoints = userPoints.totalPoints + earnedPoints;

      // 새로운 레벨 계산
      final newLevel = LevelCalculator.getLevelFromPoints(newTotalPoints);
      final pointsInCurrentLevel =
          LevelCalculator.getPointsInCurrentLevel(newTotalPoints);
      final pointsToNextLevel =
          LevelCalculator.getPointsToNextLevel(newTotalPoints);

      // 레벨업 확인
      final leveledUp = newLevel > userPoints.currentLevel;

      // 업데이트된 포인트 정보
      final updatedUserPoints = userPoints.copyWith(
        totalPoints: newTotalPoints,
        currentLevel: newLevel,
        pointsToNextLevel: pointsToNextLevel,
        pointsInCurrentLevel: pointsInCurrentLevel,
        lastUpdated: DateTime.now(),
      );

      // Firestore 업데이트
      await _firestore
          .collection(_pointsCollection)
          .doc(user.uid)
          .set(updatedUserPoints.toMap());

      // 레벨업 알림
      if (leveledUp) {
        await _notifyLevelUp(userPoints.currentLevel, newLevel);
      }

      print('✅ 사용자 포인트 업데이트 완료: +$earnedPoints (레벨 $newLevel)');
    } catch (e) {
      print('❌ 사용자 포인트 업데이트 오류: $e');
    }
  }

  /// 레벨업 알림
  Future<void> _notifyLevelUp(int oldLevel, int newLevel) async {
    try {
      // 레벨업 포인트 보너스
      final levelUpBonus = (newLevel - oldLevel) * 100;

      await earnPoints(
        type: PointType.bonus,
        customPoints: levelUpBonus,
        description: '레벨업 보너스! (Lv.$oldLevel → Lv.$newLevel)',
        context: {
          'oldLevel': oldLevel,
          'newLevel': newLevel,
          'levelUpBonus': levelUpBonus,
        },
      );

      print('🎉 레벨업! Lv.$oldLevel → Lv.$newLevel (+$levelUpBonus 보너스)');
    } catch (e) {
      print('❌ 레벨업 알림 오류: $e');
    }
  }

  /// 포인트 획득 기록 조회
  Future<List<PointEarned>> getPointsHistory({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection(_pointsEarnedCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('earnedAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('earnedAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('earnedAt',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PointEarned.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ 포인트 기록 조회 오류: $e');
      return [];
    }
  }

  /// 포인트 계산
  int _calculatePoints(PointType type, Map<String, dynamic> context) {
    int basePoints = type.basePoints;

    // 컨텍스트에 따른 보너스 계산
    switch (type) {
      case PointType.habitCompleted:
        final streak = context['streak'] ?? 1;
        final isFirstTime = context['isFirstTime'] ?? false;

        if ((streak as int) > 1) {
          basePoints += ((streak) - 1) * 5;
        }
        if (isFirstTime) {
          basePoints += 20;
        }
        break;

      case PointType.workoutCompleted:
        final duration = context['duration'] ?? 0;
        final calories = context['calories'] ?? 0.0;

        basePoints += ((duration as int) ~/ 10) * 5; // 10분당 5포인트
        basePoints += ((calories as double) ~/ 100) * 10; // 100칼로리당 10포인트
        break;

      case PointType.goalAchieved:
        final targetValue = context['targetValue'] ?? 0;
        final achievedValue = context['achievedValue'] ?? 0;

        if (targetValue > 0 && achievedValue > 0) {
          final achievementRate = achievedValue / targetValue;
          if (achievementRate >= 1.5) {
            basePoints += 50;
          } else if (achievementRate >= 1.2) {
            basePoints += 25;
          }
        }
        break;

      default:
        break;
    }

    return basePoints;
  }

  /// 업적 확인
  Future<void> _checkAchievements() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userPoints = await getCurrentUserPoints();
      if (userPoints == null) return;

      // 기본 업적들 확인
      await _checkBasicAchievements(userPoints);
    } catch (e) {
      print('❌ 업적 확인 오류: $e');
    }
  }

  /// 기본 업적 확인
  Future<void> _checkBasicAchievements(UserPoints userPoints) async {
    try {
      final achievements = [
        // 레벨 업적
        if (userPoints.currentLevel >= 5)
          await _unlockAchievement('level_5', '첫 번째 레벨업', '레벨 5 달성', '🎯', 50),
        if (userPoints.currentLevel >= 10)
          await _unlockAchievement('level_10', '습관러', '레벨 10 달성', '🌿', 100),
        if (userPoints.currentLevel >= 20)
          await _unlockAchievement('level_20', '달성자', '레벨 20 달성', '🌳', 200),
        if (userPoints.currentLevel >= 30)
          await _unlockAchievement('level_30', '마스터', '레벨 30 달성', '🏆', 300),

        // 포인트 업적
        if (userPoints.totalPoints >= 1000)
          await _unlockAchievement(
              'points_1000', '첫 1000점', '1000 포인트 달성', '💯', 100),
        if (userPoints.totalPoints >= 5000)
          await _unlockAchievement(
              'points_5000', '포인트 마스터', '5000 포인트 달성', '💰', 200),
        if (userPoints.totalPoints >= 10000)
          await _unlockAchievement(
              'points_10000', '포인트 레전드', '10000 포인트 달성', '💎', 500),
      ];

      // null 값 제거
      final validAchievements = achievements.where((a) => a != null).toList();

      if (validAchievements.isNotEmpty) {
        print('🏆 ${validAchievements.length}개의 업적을 달성했습니다!');
      }
    } catch (e) {
      print('❌ 기본 업적 확인 오류: $e');
    }
  }

  /// 업적 달성
  Future<bool> _unlockAchievement(String id, String title, String description,
      String icon, int pointsReward) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 이미 달성한 업적인지 확인
      final existingAchievement = await _firestore
          .collection(_achievementsCollection)
          .doc('${user.uid}_$id')
          .get();

      if (existingAchievement.exists) {
        return false; // 이미 달성한 업적
      }

      // 업적 달성 기록
      final achievement = Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        pointsReward: pointsReward,
        category: 'level',
        requirements: {},
        unlockedAt: DateTime.now(),
      );

      await _firestore
          .collection(_achievementsCollection)
          .doc('${user.uid}_$id')
          .set(achievement.toMap());

      // 업적 보상 포인트 지급
      await earnPoints(
        type: PointType.achievementUnlocked,
        customPoints: pointsReward,
        description: '업적 달성: $title',
        context: {
          'achievementId': id,
          'achievementTitle': title,
        },
      );

      print('🏆 업적 달성: $title (+$pointsReward 포인트)');
      return true;
    } catch (e) {
      print('❌ 업적 달성 오류: $e');
      return false;
    }
  }

  /// 사용자 업적 목록 조회
  Future<List<Achievement>> getUserAchievements() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_achievementsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('unlockedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Achievement.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 사용자 업적 조회 오류: $e');
      return [];
    }
  }

  /// 포인트 통계 조회
  Future<Map<String, dynamic>> getPointsStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userPoints = await getCurrentUserPoints();
      if (userPoints == null) return {};

      // 최근 30일 포인트 획득 기록
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentPoints = await getPointsHistory(startDate: thirtyDaysAgo);

      // 타입별 포인트 집계
      final pointsByType = <String, int>{};
      for (final point in recentPoints) {
        pointsByType[point.type.value] =
            (pointsByType[point.type.value] ?? 0) + point.points;
      }

      return {
        'totalPoints': userPoints.totalPoints,
        'currentLevel': userPoints.currentLevel,
        'levelName': userPoints.levelName,
        'levelProgress': userPoints.levelProgress,
        'pointsToNextLevel': userPoints.pointsToNextLevel,
        'recentPoints':
            recentPoints.fold(0, (sum, point) => sum + point.points),
        'pointsByType': pointsByType,
        'totalAchievements': (await getUserAchievements()).length,
      };
    } catch (e) {
      print('❌ 포인트 통계 조회 오류: $e');
      return {};
    }
  }
}
