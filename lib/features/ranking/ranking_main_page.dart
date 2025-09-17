import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/profile_menu.dart';
import '../../providers/auth_provider.dart';
import 'ranking_page.dart';
import 'friends_page.dart';
import 'club_list_page.dart';
import 'club_create_page.dart';
import 'achievements_page.dart';
import '../notifications/notifications_page.dart';

class RankingMainPage extends ConsumerStatefulWidget {
  const RankingMainPage({super.key});

  @override
  ConsumerState<RankingMainPage> createState() => _RankingMainPageState();
}

class _RankingMainPageState extends ConsumerState<RankingMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '랭킹',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
              ),
              // Red dot for unread notifications
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _showProfileMenu(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: ref.read(authProviderProvider).user?.photoURL != null
                    ? NetworkImage(ref.read(authProviderProvider).user!.photoURL!)
                    : null,
                child: ref.read(authProviderProvider).user?.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 랭킹 메인 섹션
            _buildRankingSection(),
            const SizedBox(height: 24),
            
            // 친구 관리 섹션
            _buildFriendsSection(),
            const SizedBox(height: 24),
            
            // 클럽 기능 섹션
            _buildClubSection(),
            const SizedBox(height: 24),
            
            // 업적 시스템 섹션
            _buildAchievementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingSection() {
    return SectionCard(
      title: '랭킹',
      child: Column(
        children: [
          const Text(
            '주간, 월간, 전체 랭킹을 확인하고 친구들과 경쟁해보세요!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RankingPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('전체 랭킹'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RankingPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('친구 랭킹'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection() {
    return SectionCard(
      title: '친구 관리',
      child: Column(
        children: [
          const Text(
            '친구를 추가하고 함께 운동 목표를 달성해보세요!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsPage(),
                ),
              );
            },
            icon: const Icon(Icons.people),
            label: const Text('친구 관리'),
          ),
        ],
      ),
    );
  }

  Widget _buildClubSection() {
    return SectionCard(
      title: '클럽 기능',
      child: Column(
        children: [
          const Text(
            '클럽을 만들거나 참여하여 더 큰 목표를 함께 달성해보세요!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClubCreatePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('클럽 생성'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClubListPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('클럽 목록'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementSection() {
    return SectionCard(
      title: '업적 시스템',
      child: Column(
        children: [
          const Text(
            '운동 목표를 달성하고 다양한 업적을 획득해보세요!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsPage(),
                ),
              );
            },
            icon: const Icon(Icons.military_tech),
            label: const Text('업적 보기'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileMenu(),
    );
  }
}
