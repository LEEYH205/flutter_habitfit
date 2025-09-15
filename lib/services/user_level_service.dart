import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_level.dart';

/// 사용자 레벨 관리 서비스
class UserLevelService {
  static final UserLevelService _instance = UserLevelService._internal();
  factory UserLevelService() => _instance;
  UserLevelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionName = 'user_levels';

  /// 현재 사용자의 레벨 정보 가져오기
  Future<UserLevel?> getCurrentUserLevel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection(_collectionName).doc(user.uid).get();

      if (doc.exists) {
        return UserLevel.fromMap(doc.data()!);
      } else {
        // 기본 무료 레벨로 생성
        return await _createDefaultUserLevel(user.uid);
      }
    } catch (e) {
      print('❌ 사용자 레벨 조회 오류: $e');
      return null;
    }
  }

  /// 기본 무료 레벨 생성
  Future<UserLevel> _createDefaultUserLevel(String userId) async {
    try {
      final now = DateTime.now();
      final userLevel = UserLevel(
        userId: userId,
        level: UserLevelType.free,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(userLevel.toMap());

      print('✅ 기본 사용자 레벨 생성 완료');
      return userLevel;
    } catch (e) {
      print('❌ 기본 사용자 레벨 생성 오류: $e');
      rethrow;
    }
  }

  /// 사용자 레벨 업데이트
  Future<bool> updateUserLevel({
    required UserLevelType newLevel,
    DateTime? premiumExpiryDate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final updateData = {
        'level': newLevel.value,
        'updatedAt': now.toIso8601String(),
      };

      if (premiumExpiryDate != null) {
        updateData['premiumExpiryDate'] = premiumExpiryDate.toIso8601String();
      }

      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .update(updateData);

      print('✅ 사용자 레벨 업데이트 완료: ${newLevel.displayName}');
      return true;
    } catch (e) {
      print('❌ 사용자 레벨 업데이트 오류: $e');
      return false;
    }
  }

  /// 프리미엄 구독 시작
  Future<bool> startPremiumSubscription({
    required Duration duration,
    required double price,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final expiryDate = DateTime.now().add(duration);
      final now = DateTime.now();

      final subscriptionData = {
        'level': UserLevelType.premium.value,
        'premiumExpiryDate': expiryDate.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'metadata': {
          'subscriptionStartDate': now.toIso8601String(),
          'subscriptionPrice': price,
          'paymentMethod': paymentMethod,
          'subscriptionDuration': duration.inDays,
        },
      };

      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .update(subscriptionData);

      // 구독 기록 저장
      await _firestore.collection('subscriptions').add({
        'userId': user.uid,
        'level': UserLevelType.premium.value,
        'startDate': now.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'price': price,
        'paymentMethod': paymentMethod,
        'status': 'active',
        'createdAt': now.toIso8601String(),
      });

      print('✅ 프리미엄 구독 시작 완료');
      return true;
    } catch (e) {
      print('❌ 프리미엄 구독 시작 오류: $e');
      return false;
    }
  }

  /// 프리미엄 구독 연장
  Future<bool> extendPremiumSubscription({
    required Duration additionalDuration,
    required double price,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final currentLevel = await getCurrentUserLevel();
      if (currentLevel == null || currentLevel.level != UserLevelType.premium) {
        print('❌ 프리미엄 구독이 활성화되지 않음');
        return false;
      }

      final currentExpiry = currentLevel.premiumExpiryDate ?? DateTime.now();
      final newExpiryDate = currentExpiry.add(additionalDuration);
      final now = DateTime.now();

      await _firestore.collection(_collectionName).doc(user.uid).update({
        'premiumExpiryDate': newExpiryDate.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'metadata.subscriptionExtensions': FieldValue.arrayUnion([
          {
            'extensionDate': now.toIso8601String(),
            'additionalDuration': additionalDuration.inDays,
            'price': price,
            'paymentMethod': paymentMethod,
          }
        ]),
      });

      // 연장 기록 저장
      await _firestore.collection('subscriptions').add({
        'userId': user.uid,
        'level': UserLevelType.premium.value,
        'startDate': now.toIso8601String(),
        'expiryDate': newExpiryDate.toIso8601String(),
        'price': price,
        'paymentMethod': paymentMethod,
        'status': 'extension',
        'createdAt': now.toIso8601String(),
      });

      print('✅ 프리미엄 구독 연장 완료');
      return true;
    } catch (e) {
      print('❌ 프리미엄 구독 연장 오류: $e');
      return false;
    }
  }

  /// 코치 레벨 승격
  Future<bool> promoteToCoach({
    required String reason,
    required String approvedBy,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      await _firestore.collection(_collectionName).doc(user.uid).update({
        'level': UserLevelType.coach.value,
        'updatedAt': now.toIso8601String(),
        'metadata': {
          'coachPromotionDate': now.toIso8601String(),
          'coachPromotionReason': reason,
          'approvedBy': approvedBy,
        },
      });

      // 코치 승격 기록 저장
      await _firestore.collection('coach_promotions').add({
        'userId': user.uid,
        'promotionDate': now.toIso8601String(),
        'reason': reason,
        'approvedBy': approvedBy,
        'status': 'active',
      });

      print('✅ 코치 레벨 승격 완료');
      return true;
    } catch (e) {
      print('❌ 코치 레벨 승격 오류: $e');
      return false;
    }
  }

  /// 관리자 레벨 승격
  Future<bool> promoteToAdmin({
    required String reason,
    required String approvedBy,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      await _firestore.collection(_collectionName).doc(user.uid).update({
        'level': UserLevelType.admin.value,
        'updatedAt': now.toIso8601String(),
        'metadata': {
          'adminPromotionDate': now.toIso8601String(),
          'adminPromotionReason': reason,
          'approvedBy': approvedBy,
        },
      });

      // 관리자 승격 기록 저장
      await _firestore.collection('admin_promotions').add({
        'userId': user.uid,
        'promotionDate': now.toIso8601String(),
        'reason': reason,
        'approvedBy': approvedBy,
        'status': 'active',
      });

      print('✅ 관리자 레벨 승격 완료');
      return true;
    } catch (e) {
      print('❌ 관리자 레벨 승격 오류: $e');
      return false;
    }
  }

  /// 특정 기능 사용 권한 확인
  Future<bool> canUseFeature(String featureName) async {
    try {
      final userLevel = await getCurrentUserLevel();
      if (userLevel == null) return false;

      return userLevel.canUseFeature(featureName);
    } catch (e) {
      print('❌ 기능 사용 권한 확인 오류: $e');
      return false;
    }
  }

  /// 만료된 프리미엄 구독 확인 및 처리
  Future<void> checkExpiredSubscriptions() async {
    try {
      final now = DateTime.now();
      final expiredSubscriptions = await _firestore
          .collection(_collectionName)
          .where('level', isEqualTo: UserLevelType.premium.value)
          .where('premiumExpiryDate', isLessThan: now.toIso8601String())
          .get();

      for (final doc in expiredSubscriptions.docs) {
        await doc.reference.update({
          'level': UserLevelType.free.value,
          'updatedAt': now.toIso8601String(),
          'metadata.expiredAt': now.toIso8601String(),
        });

        print('✅ 만료된 구독 처리 완료: ${doc.id}');
      }
    } catch (e) {
      print('❌ 만료된 구독 확인 오류: $e');
    }
  }

  /// 업그레이드 옵션 목록 가져오기
  List<UpgradeOption> getUpgradeOptions(UserLevelType currentLevel) {
    final options = <UpgradeOption>[];

    switch (currentLevel) {
      case UserLevelType.free:
        options.addAll([
          UpgradeOption(
            targetLevel: UserLevelType.premium,
            title: '프리미엄 월간',
            description: '모든 프리미엄 기능을 1개월간 이용하세요',
            price: 9900,
            currency: 'KRW',
            duration: Duration(days: 30),
            benefits: [
              '무제한 습관 추적',
              '고급 분석 및 인사이트',
              '맞춤형 운동 계획',
              '데이터 내보내기',
              '우선 고객 지원',
              '광고 제거',
            ],
            isPopular: true,
          ),
          UpgradeOption(
            targetLevel: UserLevelType.premium,
            title: '프리미엄 연간',
            description: '모든 프리미엄 기능을 1년간 이용하세요 (2개월 무료)',
            price: 99000,
            currency: 'KRW',
            duration: Duration(days: 365),
            benefits: [
              '무제한 습관 추적',
              '고급 분석 및 인사이트',
              '맞춤형 운동 계획',
              '데이터 내보내기',
              '우선 고객 지원',
              '광고 제거',
              '연간 구독 할인 (17% 할인)',
            ],
          ),
        ]);
        break;
      case UserLevelType.premium:
        // 프리미엄 사용자는 코치 레벨로 업그레이드할 수 없음 (수동 승격 필요)
        break;
      case UserLevelType.coach:
        // 코치는 관리자 레벨로 업그레이드할 수 없음 (수동 승격 필요)
        break;
      case UserLevelType.admin:
        // 관리자는 최고 레벨
        break;
    }

    return options;
  }

  /// 사용자 레벨 변경 이력 조회
  Future<List<Map<String, dynamic>>> getUserLevelHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final subscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return subscriptions.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ 사용자 레벨 이력 조회 오류: $e');
      return [];
    }
  }

  /// 사용자 레벨 통계 조회
  Future<Map<String, dynamic>> getUserLevelStats() async {
    try {
      final userLevel = await getCurrentUserLevel();
      if (userLevel == null) return {};

      final history = await getUserLevelHistory();

      return {
        'currentLevel': userLevel.level.displayName,
        'currentLevelValue': userLevel.level.value,
        'isPremiumActive': userLevel.isPremiumActive,
        'premiumExpiryDate': userLevel.premiumExpiryDate?.toIso8601String(),
        'totalSubscriptions': history.length,
        'benefits': userLevel.benefits,
        'limitations': userLevel.limitations,
        'canUpgrade': userLevel.level.canUpgrade(),
        'nextLevel': userLevel.level.getNextLevel()?.displayName,
      };
    } catch (e) {
      print('❌ 사용자 레벨 통계 조회 오류: $e');
      return {};
    }
  }
}
