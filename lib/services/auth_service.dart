import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication을 위한 서비스 클래스
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 사용자 스트림
  Stream<User?> get user => _auth.authStateChanges();

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 사용자 로그인 상태
  bool get isSignedIn => _auth.currentUser != null;

  /// 이메일/비밀번호로 회원가입
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ 회원가입 성공: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ 회원가입 오류: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ 로그인 성공: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ 로그인 오류: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// 구글 로그인
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('🔄 구글 로그인 시작...');

      // Google 로그인 프로세스 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ 구글 로그인이 취소되었습니다.');
        throw Exception('구글 로그인이 취소되었습니다.');
      }

      print('✅ 구글 계정 선택됨: ${googleUser.email}');

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ 구글 인증 토큰을 가져올 수 없습니다.');
        throw Exception('구글 인증에 실패했습니다.');
      }

      print('✅ 구글 인증 토큰 획득 성공');

      // Firebase 인증 정보 생성
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final result = await _auth.signInWithCredential(credential);
      print('✅ 구글 로그인 성공: ${result.user?.email}');
      return result;
    } catch (e) {
      print('❌ 구글 로그인 오류: $e');
      throw Exception('구글 로그인에 실패했습니다: $e');
    }
  }

  /// 익명 로그인 (게스트 모드)
  Future<UserCredential> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      print('✅ 익명 로그인 성공');
      return result;
    } catch (e) {
      print('❌ 익명 로그인 오류: $e');
      throw Exception('익명 로그인에 실패했습니다: $e');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('✅ 로그아웃 성공');
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
      throw Exception('로그아웃에 실패했습니다: $e');
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ 비밀번호 재설정 이메일 전송 성공');
    } on FirebaseAuthException catch (e) {
      print('❌ 비밀번호 재설정 이메일 전송 오류: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      print('✅ 사용자 이름 업데이트 성공');
    } catch (e) {
      print('❌ 사용자 이름 업데이트 오류: $e');
      throw Exception('사용자 이름 업데이트에 실패했습니다: $e');
    }
  }

  /// 계정 삭제
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      print('✅ 계정 삭제 성공');
    } catch (e) {
      print('❌ 계정 삭제 오류: $e');
      throw Exception('계정 삭제에 실패했습니다: $e');
    }
  }

  /// Firebase Auth 예외 처리
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('등록되지 않은 이메일입니다.');
      case 'wrong-password':
        return Exception('잘못된 비밀번호입니다.');
      case 'email-already-in-use':
        return Exception('이미 사용중인 이메일입니다.');
      case 'weak-password':
        return Exception('비밀번호가 너무 약합니다.');
      case 'invalid-email':
        return Exception('유효하지 않은 이메일 형식입니다.');
      case 'user-disabled':
        return Exception('비활성화된 계정입니다.');
      case 'too-many-requests':
        return Exception('너무 많은 요청입니다. 잠시 후 다시 시도해주세요.');
      case 'operation-not-allowed':
        return Exception('이 로그인 방법은 허용되지 않습니다.');
      default:
        return Exception('인증 오류: ${e.message}');
    }
  }
}
