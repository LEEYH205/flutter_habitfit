import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';

/// 로그인 화면
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // 로고/아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 타이틀
                    Text(
                      'HabitFit',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '건강한 습관, 더 나은 삶',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),

                    const SizedBox(height: 48),

                    // 이메일 입력 필드
                    CustomTextField(
                      controller: _emailController,
                      labelText: '이메일',
                      hintText: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return '유효한 이메일 주소를 입력해주세요';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 비밀번호 입력 필드
                    CustomTextField(
                      controller: _passwordController,
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력하세요',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 최소 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 로그인/회원가입 버튼
                    CustomButton(
                      text: _isSignUp ? '회원가입' : '로그인',
                      isLoading: authProvider.isLoading,
                      onPressed: authProvider.isLoading ? null : _handleAuth,
                    ),

                    const SizedBox(height: 16),

                    // 로그인 ↔ 회원가입 전환 버튼
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          authProvider.clearError();
                        });
                      },
                      child: Text(
                        _isSignUp ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 또는 구분선
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '또는',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 구글 로그인 버튼
                    CustomButton(
                      text: '구글로 계속하기',
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      borderColor: Colors.grey[300],
                      prefixIcon: Image.asset(
                        'assets/google_logo.png', // 구글 로고 이미지 필요
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.g_mobiledata, color: Colors.blue);
                        },
                      ),
                      isLoading: authProvider.isLoading,
                      onPressed:
                          authProvider.isLoading ? null : _handleGoogleSignIn,
                    ),

                    const SizedBox(height: 12),

                    // 익명 로그인 버튼
                    CustomButton(
                      text: '게스트로 계속하기',
                      backgroundColor: Colors.grey[100],
                      textColor: Colors.black87,
                      prefixIcon:
                          Icon(Icons.person_outline, color: Colors.grey[600]),
                      isLoading: authProvider.isLoading,
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleAnonymousSignIn,
                    ),

                    const SizedBox(height: 16),

                    // 비밀번호 재설정 버튼 (로그인 모드에서만)
                    if (!_isSignUp)
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // 에러 메시지
                    if (authProvider.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red[400], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 이메일/비밀번호 인증 처리
  void _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isSignUp) {
      success = await authProvider.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      success = await authProvider.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }

    if (success && mounted) {
      // 로그인 성공 시 메인 화면으로 이동
      context.go('/today');
    }
  }

  /// 구글 로그인 처리
  void _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      context.go('/today');
    }
  }

  /// 익명 로그인 처리
  void _handleAnonymousSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInAnonymously();

    if (success && mounted) {
      context.go('/today');
    }
  }

  /// 비밀번호 재설정 다이얼로그 표시
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 재설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('비밀번호 재설정 링크를 받을 이메일을 입력해주세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.sendPasswordResetEmail(email);

              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('비밀번호 재설정 이메일을 보냈습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }
}
