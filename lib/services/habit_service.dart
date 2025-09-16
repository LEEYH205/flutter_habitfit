import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';
import '../models/points_system.dart';
import 'points_service.dart';

class HabitService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 사용자의 습관 목록 가져오기
  Future<List<Habit>> getUserHabits() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('user_habits')
          .where('uid', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Habit.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 습관 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 새 습관 추가
  Future<String?> addHabit({
    required String title,
    required String description,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final habitId = _firestore.collection('user_habits').doc().id;
      final habit = Habit(
        id: habitId,
        title: title,
        description: description,
        emoji: emoji,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('user_habits').doc(habitId).set({
        ...habit.toMap(),
        'uid': user.uid,
      });

      print('✅ 습관 추가 성공: $title');
      return habitId;
    } catch (e) {
      print('❌ 습관 추가 실패: $e');
      return null;
    }
  }

  /// 습관 수정
  Future<bool> updateHabit({
    required String habitId,
    String? title,
    String? description,
    String? emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (emoji != null) updateData['emoji'] = emoji;

      await _firestore
          .collection('user_habits')
          .doc(habitId)
          .update(updateData);

      print('✅ 습관 수정 성공: $habitId');
      return true;
    } catch (e) {
      print('❌ 습관 수정 실패: $e');
      return false;
    }
  }

  /// 습관 삭제 (소프트 삭제)
  Future<bool> deleteHabit(String habitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('user_habits')
          .doc(habitId)
          .update({'isActive': false});

      print('✅ 습관 삭제 성공: $habitId');
      return true;
    } catch (e) {
      print('❌ 습관 삭제 실패: $e');
      return false;
    }
  }

  /// 특정 습관의 완료 상태 저장
  Future<bool> setHabitDone(String habitId, DateTime date, bool done) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final dateId = _getDateId(date);
      final docId = '${user.uid}-$habitId-$dateId';

      await _firestore.collection('habit_completions').doc(docId).set({
        'uid': user.uid,
        'habitId': habitId,
        'date': dateId,
        'done': done,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 오늘 날짜의 습관 완료 상태가 변경되면 연속 기록 업데이트
      final today = DateTime.now();
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        await _updateHabitStreak(habitId, done);

        // 습관 완료 시 포인트 획득 (중복 방지)
        if (done) {
          await _earnHabitPoints(habitId, dateId);
        } else {
          // 습관 해제 시 오늘 포인트 기록 삭제 (있다면)
          await _removeHabitPointsIfExists(habitId, dateId);
        }
      }

      print('✅ 습관 완료 상태 저장: $habitId - $dateId - $done');
      return true;
    } catch (e) {
      print('❌ 습관 완료 상태 저장 실패: $e');
      return false;
    }
  }

  /// 특정 습관의 완료 상태 가져오기
  Future<bool> getHabitDone(String habitId, DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final dateId = _getDateId(date);
      final docId = '${user.uid}-$habitId-$dateId';

      final doc =
          await _firestore.collection('habit_completions').doc(docId).get();

      return doc.exists ? (doc.data()?['done'] ?? false) : false;
    } catch (e) {
      print('❌ 습관 완료 상태 가져오기 실패: $e');
      return false;
    }
  }

  /// 습관의 연속 기록을 저장된 값에서 가져오기 (빠른 방식)
  Future<Map<String, int>> getHabitStreak(String habitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'current': 0, 'max': 0};

      final habitDoc =
          await _firestore.collection('user_habits').doc(habitId).get();

      if (habitDoc.exists) {
        final data = habitDoc.data()!;
        return {
          'current': data['currentStreak'] ?? 0,
          'max': data['maxStreak'] ?? 0,
        };
      }

      return {'current': 0, 'max': 0};
    } catch (e) {
      print('❌ 습관 연속 기록 가져오기 실패: $e');
      return {'current': 0, 'max': 0};
    }
  }

  /// 습관 완료 상태 변경 시 연속 기록 업데이트
  Future<void> _updateHabitStreak(String habitId, bool isCompleted) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // 현재 연속 기록과 최고 기록 가져오기
      final currentStreakData = await getHabitStreak(habitId);
      int currentStreak = currentStreakData['current'] ?? 0;
      int maxStreak = currentStreakData['max'] ?? 0;

      if (isCompleted) {
        // 습관 완료 시
        final wasCompletedYesterday = await getHabitDone(habitId, yesterday);

        if (wasCompletedYesterday) {
          // 어제도 완료했으면 연속 기록 증가
          currentStreak++;
        } else {
          // 어제 완료하지 않았으면 연속 기록 초기화 (오늘부터 시작)
          currentStreak = 1;
        }
      } else {
        // 습관 해제 시
        currentStreak = 0;
      }

      // 최고 기록 업데이트
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }

      // user_habits 컬렉션에 연속 기록 저장
      await _firestore.collection('user_habits').doc(habitId).update({
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'lastStreakUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ 연속 기록 업데이트: 현재 $currentStreak일, 최고 $maxStreak일');
    } catch (e) {
      print('❌ 연속 기록 업데이트 실패: $e');
    }
  }

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 습관 완료 시 포인트 획득 (중복 방지)
  Future<void> _earnHabitPoints(String habitId, String dateId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 이미 오늘 이 습관으로 포인트를 받았는지 확인
      final pointsQuery = await _firestore
          .collection('points_earned')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'habit_completed')
          .where('relatedId', isEqualTo: habitId)
          .where('metadata.date', isEqualTo: dateId)
          .get();

      if (pointsQuery.docs.isNotEmpty) {
        print('⚠️ 이미 오늘 이 습관으로 포인트를 받았습니다: $habitId');
        return;
      }

      // 습관 정보 가져오기
      final habitDoc =
          await _firestore.collection('user_habits').doc(habitId).get();
      if (!habitDoc.exists) return;

      final habitData = habitDoc.data()!;
      final habitName = habitData['title'] ?? '습관';

      // 현재 연속 기록 가져오기
      final habit = Habit.fromMap(habitData);
      final currentStreak = habit.currentStreak;

      // 첫 완료 여부 확인 (연속 기록이 1이면 첫 완료)
      final isFirstTime = currentStreak == 1;

      // 포인트 획득 (날짜 정보를 메타데이터에 포함)
      final success = await PointsService().earnPoints(
        type: PointType.habitCompleted,
        description: '$habitName 완료 (연속 $currentStreak일)',
        relatedId: habitId,
        context: {
          'habitName': habitName,
          'streak': currentStreak,
          'isFirstTime': isFirstTime,
          'date': dateId, // 날짜 정보 추가로 중복 체크
        },
      );

      if (success) {
        print('✅ 습관 완료 포인트 획득: $habitName (날짜: $dateId)');
      } else {
        print('❌ 습관 완료 포인트 획득 실패: $habitName');
      }
    } catch (e) {
      print('❌ 습관 포인트 획득 오류: $e');
    }
  }

  /// 습관 해제 시 포인트 기록 삭제 (있다면)
  Future<void> _removeHabitPointsIfExists(String habitId, String dateId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 오늘 이 습관으로 받은 포인트 기록 찾기
      final pointsQuery = await _firestore
          .collection('points_earned')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'habit_completed')
          .where('relatedId', isEqualTo: habitId)
          .where('metadata.date', isEqualTo: dateId)
          .get();

      if (pointsQuery.docs.isEmpty) {
        print('ℹ️ 삭제할 포인트 기록이 없습니다: $habitId ($dateId)');
        return;
      }

      // 포인트 기록 삭제 및 사용자 포인트에서 차감
      for (final doc in pointsQuery.docs) {
        final pointData = doc.data();
        final points = pointData['points'] ?? 0;

        // 포인트 기록 삭제
        await doc.reference.delete();

        // 사용자 포인트에서 차감
        await _deductUserPoints(points);

        print('✅ 습관 해제로 포인트 기록 삭제: $habitId (-$points점, 날짜: $dateId)');
      }
    } catch (e) {
      print('❌ 포인트 기록 삭제 오류: $e');
    }
  }

  /// 사용자 포인트 차감
  Future<void> _deductUserPoints(int pointsToDeduct) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc =
          await _firestore.collection('user_points').doc(user.uid).get();
      if (!doc.exists) return;

      final currentPoints = doc.data()!['totalPoints'] ?? 0;
      final newTotalPoints =
          (currentPoints - pointsToDeduct).clamp(0, double.infinity).toInt();

      // 포인트 차감 후 레벨 재계산은 복잡하므로 일단 총 포인트만 업데이트
      await _firestore.collection('user_points').doc(user.uid).update({
        'totalPoints': newTotalPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ 사용자 포인트 차감: -$pointsToDeduct (새 총점: $newTotalPoints)');
    } catch (e) {
      print('❌ 사용자 포인트 차감 오류: $e');
    }
  }
}
