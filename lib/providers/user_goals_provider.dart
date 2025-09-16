import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_goals.dart';

/// 사용자 목표 Provider
final userGoalsProvider = FutureProvider<UserGoals>((ref) async {
  return await _loadUserGoals();
});

/// 사용자 목표 로드 함수
Future<UserGoals> _loadUserGoals() async {
  try {
    // Firebase Auth에서 직접 사용자 정보 가져오기
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('🎯 사용자가 로그인되지 않음 - 기본 목표 반환');
      return UserGoals.defaultGoals();
    }

    print('🎯 사용자 목표 로드 시작: ${user.uid}');

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['goals'] != null) {
      final goals = UserGoals.fromJson(doc.data()!['goals']);
      print('✅ 사용자 목표 로드 완료: $goals');
      return goals;
    } else {
      // 목표가 없으면 기본값 반환 (AuthProvider에서 생성하도록 함)
      print('📝 목표가 없음 - 기본값 반환 (AuthProvider에서 생성 예정)');
      return UserGoals.defaultGoals();
    }
  } catch (e) {
    print('❌ 사용자 목표 로드 실패: $e');
    return UserGoals.defaultGoals();
  }
}

/// 사용자 목표 저장 함수
Future<void> _saveUserGoals(UserGoals goals) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ 사용자가 로그인되지 않았습니다.');
      return;
    }

    print('💾 사용자 목표 저장 시작: ${user.uid}');

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'goals': goals.toJson(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    print('✅ 사용자 목표 저장 완료');
  } catch (e) {
    print('❌ 사용자 목표 저장 실패: $e');
  }
}

/// 사용자 목표 업데이트 함수
Future<void> updateUserGoal({
  required double activeCaloriesGoal,
  required int exerciseMinutesGoal,
  required int stepsGoal,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ 사용자가 로그인되지 않았습니다.');
      return;
    }

    print('🔄 사용자 목표 업데이트 시작: ${user.uid}');

    final updatedGoals = UserGoals(
      activeCaloriesGoal: activeCaloriesGoal,
      exerciseMinutesGoal: exerciseMinutesGoal,
      stepsGoal: stepsGoal,
      lastUpdated: DateTime.now(),
    );

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'goals': updatedGoals.toJson(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    print('✅ 사용자 목표 업데이트 완료: $updatedGoals');
  } catch (e) {
    print('❌ 사용자 목표 업데이트 실패: $e');
  }
}
