import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 개발/테스트용 관리자 설정 서비스
/// ⚠️ 주의: 실제 프로덕션에서는 사용하지 마세요!
class AdminSetupService {
  static final AdminSetupService _instance = AdminSetupService._internal();
  factory AdminSetupService() => _instance;
  AdminSetupService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 사용자가 관리자인지 확인
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 강제로 토큰 갱신
      await user.getIdToken(true);
      
      // Custom Claims 확인
      final token = await user.getIdToken();
      final claims = token.claims;
      
      return claims?['admin'] == true || claims?['role'] == 'admin';
    } catch (e) {
      print('❌ 관리자 권한 확인 실패: $e');
      return false;
    }
  }

  /// 현재 사용자가 코치인지 확인
  Future<bool> isCurrentUserCoach() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.getIdToken(true);
      final token = await user.getIdToken();
      final claims = token.claims;
      
      return claims?['coach'] == true || claims?['role'] == 'coach';
    } catch (e) {
      print('❌ 코치 권한 확인 실패: $e');
      return false;
    }
  }

  /// 사용자 권한 정보 가져오기
  Future<Map<String, dynamic>> getUserRoleInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      await user.getIdToken(true);
      final token = await user.getIdToken();
      final claims = token.claims ?? {};

      return {
        'uid': user.uid,
        'email': user.email,
        'role': claims['role'] ?? 'user',
        'isAdmin': claims['admin'] == true,
        'isCoach': claims['coach'] == true,
      };
    } catch (e) {
      print('❌ 사용자 권한 정보 조회 실패: $e');
      return {};
    }
  }

  /// 개발용: 특정 이메일을 관리자로 설정 (Firestore 기반)
  /// ⚠️ 실제 프로덕션에서는 Firebase Admin SDK 사용!
  Future<bool> setAdminByEmail(String email) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 현재 사용자가 이미 관리자인지 확인
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        print('❌ 관리자 권한이 필요합니다.');
        return false;
      }

      // Firestore에 관리자 목록 저장 (임시 방법)
      await _firestore.collection('admin_users').doc(email).set({
        'email': email,
        'role': 'admin',
        'grantedBy': user.uid,
        'grantedAt': FieldValue.serverTimestamp(),
      });

      print('✅ 관리자 권한 설정 완료: $email');
      return true;
    } catch (e) {
      print('❌ 관리자 권한 설정 실패: $e');
      return false;
    }
  }

  /// Firestore 기반 관리자 확인
  Future<bool> isAdminByEmail(String email) async {
    try {
      final doc = await _firestore.collection('admin_users').doc(email).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      print('❌ 관리자 확인 실패: $e');
      return false;
    }
  }

  /// 관리자 목록 조회
  Future<List<Map<String, dynamic>>> getAdminList() async {
    try {
      final snapshot = await _firestore.collection('admin_users').get();
      return snapshot.docs.map((doc) => {
        final data = doc.data();
        return {
          'email': doc.id,
          'role': data['role'],
          'grantedBy': data['grantedBy'],
          'grantedAt': data['grantedAt'],
        };
      }).toList();
    } catch (e) {
      print('❌ 관리자 목록 조회 실패: $e');
      return [];
    }
  }
}

