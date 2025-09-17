import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/section_card.dart';
import 'ranking_page.dart';
import 'friends_page.dart';

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
        title: const Text('랭킹'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // 프로필 메뉴 열기
              _showProfileMenu(context);
            },
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
                    // 클럽 생성 페이지로 이동
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('클럽 생성'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 클럽 목록 페이지로 이동
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
              // 업적 페이지로 이동
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('사용자 정보'),
              onTap: () {
                Navigator.pop(context);
                // 사용자 정보 페이지로 이동
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('앱 설정'),
              onTap: () {
                Navigator.pop(context);
                // 앱 설정 페이지로 이동
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                Navigator.pop(context);
                // 로그아웃 처리
              },
            ),
          ],
        ),
      ),
    );
  }
}
