import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 사용자 데이터 정리 서비스
class UserCleanupService {
  static final UserCleanupService _instance = UserCleanupService._internal();
  factory UserCleanupService() => _instance;
  UserCleanupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 중복 사용자 문서 정리
  Future<void> cleanupDuplicateUsers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        return;
      }

      print('🧹 중복 사용자 문서 정리 시작: ${user.email}');

      // 같은 이메일을 가진 모든 문서 조회
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.length <= 1) {
        print('✅ 중복 문서가 없습니다.');
        return;
      }

      print('🔍 ${querySnapshot.docs.length}개의 중복 문서 발견');

      // 가장 최신 문서 찾기 (createdAt 기준)
      DocumentSnapshot? latestDoc;
      DateTime? latestDate;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;

        if (createdAt != null) {
          final docDate = createdAt.toDate();
          if (latestDate == null || docDate.isAfter(latestDate)) {
            latestDate = docDate;
            latestDoc = doc;
          }
        }
      }

      if (latestDoc == null) {
        print('❌ 최신 문서를 찾을 수 없습니다.');
        return;
      }

      print('📄 최신 문서 ID: ${latestDoc.id}');

      // 최신 문서에 모든 데이터 통합
      final latestData = latestDoc.data() as Map<String, dynamic>;
      final mergedData = <String, dynamic>{};

      // 모든 문서의 데이터를 병합
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        data.forEach((key, value) {
          if (value != null && !mergedData.containsKey(key)) {
            mergedData[key] = value;
          }
        });
      }

      // 최신 문서 업데이트
      await _firestore.collection('users').doc(latestDoc.id).update(mergedData);
      print('✅ 최신 문서에 모든 데이터 병합 완료');

      // 나머지 중복 문서 삭제
      for (final doc in querySnapshot.docs) {
        if (doc.id != latestDoc.id) {
          await _firestore.collection('users').doc(doc.id).delete();
          print('🗑️ 중복 문서 삭제: ${doc.id}');
        }
      }

      print('🎉 중복 사용자 문서 정리 완료');
    } catch (e) {
      print('❌ 중복 사용자 문서 정리 실패: $e');
    }
  }

  /// 현재 사용자의 문서 상태 확인
  Future<void> checkUserDocumentStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        return;
      }

      print('🔍 사용자 문서 상태 확인: ${user.email}');

      // 같은 이메일을 가진 모든 문서 조회
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      print('📊 총 문서 수: ${querySnapshot.docs.length}');

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();
        print('📄 문서 ${i + 1}: ${doc.id}');
        print('   - 생성일: ${data['createdAt']}');
        print('   - 이름: ${data['displayName']}');
        print('   - 목표: ${data['goals'] != null ? '있음' : '없음'}');
        print('   - 활성: ${data['isActive']}');
      }
    } catch (e) {
      print('❌ 사용자 문서 상태 확인 실패: $e');
    }
  }
}
