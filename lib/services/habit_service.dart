import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

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

      final doc = await _firestore
          .collection('habit_completions')
          .doc(docId)
          .get();

      return doc.exists ? (doc.data()?['done'] ?? false) : false;
    } catch (e) {
      print('❌ 습관 완료 상태 가져오기 실패: $e');
      return false;
    }
  }

  /// 특정 습관의 연속 달성 기록 계산
  Future<Map<String, int>> getHabitStreak(String habitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'current': 0, 'max': 0};

      final today = DateTime.now();
      int currentStreak = 0;
      int maxStreak = 0;
      int tempStreak = 0;

      // 최근 365일 동안의 데이터 확인
      for (int i = 0; i < 365; i++) {
        final date = today.subtract(Duration(days: i));
        final isDone = await getHabitDone(habitId, date);

        if (isDone) {
          if (i == 0) {
            currentStreak = 1;
            tempStreak = 1;
          } else {
            currentStreak++;
            tempStreak++;
          }
        } else {
          if (i == 0) {
            // 오늘 완료하지 않았으면 연속 기록은 0
            currentStreak = 0;
          } else {
            // 과거 날짜에서 완료하지 않았으면 연속 기록 중단
            if (tempStreak > maxStreak) {
              maxStreak = tempStreak;
            }
            tempStreak = 0;
          }
        }
      }

      if (tempStreak > maxStreak) {
        maxStreak = tempStreak;
      }

      return {'current': currentStreak, 'max': maxStreak};
    } catch (e) {
      print('❌ 습관 연속 기록 계산 실패: $e');
      return {'current': 0, 'max': 0};
    }
  }

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

