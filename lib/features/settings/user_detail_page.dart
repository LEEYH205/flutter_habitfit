import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/cache_service.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../user_level/user_membership_page.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
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
        await _googleSignIn.signOut();
        await _auth.signOut();

        // 캐시 정리
        await CacheService.clearAllCache();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그아웃되었습니다'),
              backgroundColor: Colors.green,
            ),
          );

          // 로그인 페이지로 이동
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그아웃 중 오류가 발생했습니다: $e'),
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
        await _currentUser?.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('계정이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );

          // 로그인 페이지로 이동
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('계정 삭제 중 오류가 발생했습니다: $e'),
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
        title: '👤 사용자 세부 정보',
        showProfile: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // 사용자 정보 헤더
            _buildUserInfoHeader(),

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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: _currentUser?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        _currentUser!.photoURL!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue.shade600,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentUser?.displayName ?? '사용자',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _currentUser?.email ?? '이메일 없음',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '관리자',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
