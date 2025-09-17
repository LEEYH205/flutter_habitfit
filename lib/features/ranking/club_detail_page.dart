import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../widgets/common/section_card.dart';
import '../../services/club_service.dart';
import '../../models/ranking.dart';

class ClubDetailPage extends ConsumerStatefulWidget {
  final Club club;

  const ClubDetailPage({super.key, required this.club});

  @override
  ConsumerState<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends ConsumerState<ClubDetailPage> {
  final ClubService _clubService = ClubService();
  bool _isJoining = false;
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(title: '클럽 상세'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 클럽 헤더
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        widget.club.name.isNotEmpty
                            ? widget.club.name[0].toUpperCase()
                            : 'C',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.club.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.club.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          icon: Icons.people,
                          label: '멤버',
                          value: '${widget.club.memberCount}명',
                        ),
                        _buildStatItem(
                          icon: Icons.flag,
                          label: '카테고리',
                          value: widget.club.settings['category'] ?? '운동',
                        ),
                        _buildStatItem(
                          icon: Icons.lock,
                          label: '공개',
                          value: widget.club.isPublic ? '공개' : '비공개',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isJoining ? null : _joinClub,
                    icon: _isJoining
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(_isJoining ? '참여 중...' : '클럽 참여'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLeaving ? null : _leaveClub,
                    icon: _isLeaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.exit_to_app),
                    label: Text(_isLeaving ? '탈퇴 중...' : '클럽 탈퇴'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 클럽 활동
            SectionCard(
              title: '최근 활동',
              child: Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.person_add,
                    title: '새 멤버 가입',
                    subtitle: '김철수님이 클럽에 참여했습니다',
                    time: '2시간 전',
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.emoji_events,
                    title: '목표 달성',
                    subtitle: '이번 주 목표를 달성했습니다!',
                    time: '1일 전',
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.chat,
                    title: '새 게시글',
                    subtitle: '오늘의 러닝 후기를 공유했습니다',
                    time: '2일 전',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 멤버 목록
            SectionCard(
              title: '멤버 목록',
              child: Column(
                children: [
                  _buildMemberItem(
                    name: '클럽장',
                    email: 'leader@example.com',
                    isLeader: true,
                  ),
                  const Divider(),
                  _buildMemberItem(
                    name: '김철수',
                    email: 'kim@example.com',
                    isLeader: false,
                  ),
                  const Divider(),
                  _buildMemberItem(
                    name: '이영희',
                    email: 'lee@example.com',
                    isLeader: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade600,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(
          icon,
          color: Colors.blue.shade600,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMemberItem({
    required String name,
    required String email,
    required bool isLeader,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isLeader ? Colors.amber.shade100 : Colors.grey.shade300,
        child: Text(
          name[0],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isLeader ? Colors.amber.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(name),
          if (isLeader) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '클럽장',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(email),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _joinClub() async {
    setState(() {
      _isJoining = true;
    });

    try {
      // TODO: 클럽 참여 로직 구현
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('클럽에 성공적으로 참여했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('클럽 참여에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leaveClub() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('클럽 탈퇴'),
        content: const Text('정말로 이 클럽을 탈퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '탈퇴',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      // TODO: 클럽 탈퇴 로직 구현
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('클럽에서 탈퇴했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('클럽 탈퇴에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }
  }
}
