import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';

/// 인증 상태를 관리하는 Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  AuthProvider() {
    // 앱 시작 시 현재 사용자 상태 확인
    _init();
  }

  /// 초기화 - 현재 인증 상태 확인
  void _init() {
    _isLoading = true;
    notifyListeners();

    // 개발 모드에서 자동 로그아웃 옵션 (개발 편의용)
    _checkDebugModeAutoSignOut();

    // Firebase Auth 상태 변경 감지
    _authService.user.listen((User? user) {
      _user = user;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      print('🔄 인증 상태 변경: ${user?.email ?? '로그아웃됨'}');

      // 사용자가 로그인했을 때 users 컬렉션에 문서 생성
      if (user != null) {
        _createUserDocument(user);
      }
    });
  }

  /// 이메일/비밀번호 회원가입
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 이메일/비밀번호 로그인
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      await _authService.signInWithGoogle();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 익명 로그인 (게스트 모드)
  Future<bool> signInAnonymously() async {
    try {
      _setLoading(true);
      await _authService.signInAnonymously();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃
  Future<bool> signOut() async {
    try {
      _setLoading(true);

      // 캐시 먼저 정리
      await CacheService.clearAllCache();
      print('🗑️ 로그아웃 시 모든 캐시 정리 완료');

      await _authService.signOut();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _authService.sendPasswordResetEmail(email);
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 정보 업데이트
  Future<bool> updateDisplayName(String displayName) async {
    try {
      _setLoading(true);
      await _authService.updateDisplayName(displayName);
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 계정 삭제
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);

      // 캐시 먼저 정리
      await CacheService.clearAllCache();
      print('🗑️ 계정 삭제 시 모든 캐시 정리 완료');

      await _authService.deleteAccount();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 문서 생성 (users 컬렉션)
  Future<void> _createUserDocument(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // 사용자 문서가 없으면 완전한 문서 생성
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'maxHabitStreak': 0,
          'totalHabits': 0,
          'totalWorkouts': 0,
          'isActive': true,
          // 기본 목표 설정
          'goals': {
            'activeCaloriesGoal': 400.0,
            'exerciseMinutesGoal': 30,
            'stepsGoal': 10000,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        });
        print('✅ 사용자 문서 생성 완료: ${user.uid}');
      } else {
        // 기존 문서가 있으면 필수 필드만 업데이트
        final updateData = <String, dynamic>{
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // 필수 필드가 없으면 추가
        final data = userDoc.data()!;
        if (data['email'] == null) updateData['email'] = user.email;
        if (data['displayName'] == null)
          updateData['displayName'] = user.displayName;
        if (data['photoURL'] == null) updateData['photoURL'] = user.photoURL;
        if (data['goals'] == null) {
          updateData['goals'] = {
            'activeCaloriesGoal': 400.0,
            'exerciseMinutesGoal': 30,
            'stepsGoal': 10000,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
        print('✅ 사용자 문서 업데이트 완료: ${user.uid}');
      }
    } catch (e) {
      print('❌ 사용자 문서 생성/업데이트 실패: $e');
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 메시지 설정
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 에러 메시지 초기화
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 에러 메시지 수동 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 개발 모드에서 자동 로그아웃 확인 (개발 편의용)
  void _checkDebugModeAutoSignOut() {
    // 개발 모드가 아니면 무시
    if (!kDebugMode) return;

    // 환경변수나 설정으로 자동 로그아웃 여부 결정
    // 기본값: true (앱 재설치 테스트를 위해 임시로 활성화)
    const bool autoSignOutInDebug = false; // 이 값을 false로 변경하면 개발 모드에서 로그인 상태 유지

    if (autoSignOutInDebug && _authService.currentUser != null) {
      print('🔧 개발 모드: 자동 로그아웃 실행');
      Future.microtask(() async {
        await CacheService.clearAllCache();
        await _authService.signOut();
        print('✅ 개발 모드: 자동 로그아웃 완료');
      });
    } else if (kDebugMode && _authService.currentUser != null) {
      print('🔧 개발 모드: 로그인 상태 유지됨 (${_authService.currentUser?.email})');
      print(
          '💡 자동 로그아웃을 원하면 AuthProvider._checkDebugModeAutoSignOut()에서 autoSignOutInDebug를 true로 변경하세요');
    }
  }
}

/// AuthProvider의 Riverpod Provider
final authProviderProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});
