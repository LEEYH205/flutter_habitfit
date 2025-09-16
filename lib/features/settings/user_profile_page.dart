import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../services/cache_service.dart';
import '../../router/app_router.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../user_level/user_membership_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text(
          '정말로 로그아웃하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // AuthProvider를 통해 로그아웃
        final authProvider =
            Provider.of<auth.AuthProvider>(context, listen: false);
        await authProvider.signOut();

        // 모든 캐시 데이터 정리
        await CacheService.clearAllCache();

        // Google Sign-In도 정리
        await _googleSignIn.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그아웃되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          // 잠시 대기 후 전역 라우터를 사용하여 로그인 페이지로 이동
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              AppRouter.router.go('/login');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그아웃 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '정말로 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // AuthProvider를 통해 계정 삭제 (Firestore 데이터도 함께 삭제)
        final authProvider =
            Provider.of<auth.AuthProvider>(context, listen: false);
        final success = await authProvider.deleteAccount();

        if (!success) {
          throw Exception('계정 삭제 실패');
        }

        // 모든 캐시 데이터 정리
        await CacheService.clearAllCache();

        // Google Sign-In도 정리
        await _googleSignIn.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('계정이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          // 잠시 대기 후 전역 라우터를 사용하여 로그인 페이지로 이동
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              AppRouter.router.go('/login');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('계정 삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '👤 사용자 프로필',
        showProfile: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // 멤버십 섹션
            _buildSectionHeader('👑 멤버십'),
            _buildSettingTile(
              icon: Icons.account_circle,
              title: '멤버십',
              subtitle: '멤버십 가입',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserMembershipPage(),
                  ),
                );
              },
              textColor: Colors.purple,
            ),

            const SizedBox(height: 24),

            // 계정 설정 섹션
            _buildSectionHeader('⚙️ 계정 설정'),
            _buildSettingTile(
              icon: Icons.email,
              title: '이메일',
              subtitle: _currentUser?.email ?? '이메일 없음',
              onTap: () {
                // TODO: 이메일 변경 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이메일 변경 기능은 준비 중입니다')),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.lock,
              title: '비밀번호 변경',
              subtitle: '계정 보안을 위해 정기적으로 변경하세요',
              onTap: () {
                // TODO: 비밀번호 변경 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호 변경 기능은 준비 중입니다')),
                );
              },
            ),

            const SizedBox(height: 24),

            // 개인정보 관리 섹션
            _buildSectionHeader('🔒 개인정보 관리'),
            _buildSettingTile(
              icon: Icons.download,
              title: '데이터 내보내기',
              subtitle: '내 운동 데이터를 백업합니다',
              onTap: () {
                // TODO: 데이터 내보내기 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터 내보내기 기능은 준비 중입니다')),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.delete_forever,
              title: '개인정보 삭제',
              subtitle: '모든 개인 데이터를 영구 삭제합니다',
              onTap: () {
                // TODO: 개인정보 삭제 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('개인정보 삭제 기능은 준비 중입니다')),
                );
              },
            ),

            const SizedBox(height: 24),

            // 계정 관리 섹션
            _buildSectionHeader('⚠️ 계정 관리'),
            _buildSettingTile(
              icon: Icons.logout,
              title: '로그아웃',
              subtitle: '현재 계정에서 로그아웃합니다',
              onTap: _signOut,
              textColor: Colors.orange,
            ),
            _buildSettingTile(
              icon: Icons.delete,
              title: '계정 삭제',
              subtitle: '계정과 모든 데이터를 영구 삭제합니다',
              onTap: _deleteAccount,
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? Colors.blue,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
