import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_bar_with_notifications.dart';
import 'settings_page.dart';
import '../user_level/user_membership_page.dart';
import 'notification_settings_page.dart';
import 'goal_settings_page.dart';
import '../test_security_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // 사용자 정보 카드
            _buildUserInfoCard(),

            const SizedBox(height: 24),

            // 액션 버튼들
            _buildActionButtons(),

            const SizedBox(height: 24),

            // 설정 섹션
            _buildSettingsSection(),

          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
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
                  color: Colors.red.withValues(alpha: 0.7),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('설정'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이벤트 기능은 준비 중입니다!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.event),
            label: const Text('이벤트'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '⚙️ 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Card(
          elevation: 4,
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.account_circle,
                title: '멤버십',
                subtitle: '멤버십 관리',
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
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.notifications,
                title: '알림 설정',
                subtitle: '알림 관리',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.flag,
                title: '목표 설정',
                subtitle: '운동 및 건강 목표',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalSettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.security,
                title: '개발자 도구',
                subtitle: '보안 테스트 및 디버깅',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestSecurityPage(),
                    ),
                  );
                },
                textColor: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.blue.shade600),
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
    );
  }

}
