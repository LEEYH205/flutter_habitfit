import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// 인증 상태를 관리하는 Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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

    // Firebase Auth 상태 변경 감지
    _authService.user.listen((User? user) {
      _user = user;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      print('🔄 인증 상태 변경: ${user?.email ?? '로그아웃됨'}');
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
}
