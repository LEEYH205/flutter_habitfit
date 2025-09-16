import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ranking.dart';
import '../../services/ranking_service.dart';
import '../../widgets/app_bar_with_notifications.dart';

/// 친구 관리 페이지
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  final RankingService _rankingService = RankingService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<Friendship> _friendsList = [];
  List<Friendship> _pendingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriendsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 현재 사용자 ID 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final friends = await _rankingService.getFriendsList(user.uid);
      final requests = await _rankingService.getPendingFriendRequests(user.uid);

      setState(() {
        _friendsList = friends;
        _pendingRequests = requests;
      });
    } catch (e) {
      print('❌ 친구 데이터 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친구 데이터를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
      });

      final results = await _rankingService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('❌ 사용자 검색 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용자 검색에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String friendId) async {
    try {
      final success = await _rankingService.sendFriendRequest(friendId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 친구 요청을 보냈습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        // 검색 결과 업데이트
        _searchUsers(_searchController.text);
      } else {
        throw Exception('친구 요청 전송 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 친구 요청 전송에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(String friendId) async {
    try {
      final success = await _rankingService.acceptFriendRequest(friendId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 친구 요청을 수락했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadFriendsData();
      } else {
        throw Exception('친구 요청 수락 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 친구 요청 수락에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrRemoveFriend(String friendId,
      {bool isRemove = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRemove ? '친구 삭제' : '친구 요청 거절'),
        content: Text(isRemove ? '정말로 이 친구를 삭제하시겠습니까?' : '이 친구 요청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isRemove ? '삭제' : '거절'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _rankingService.rejectOrRemoveFriend(friendId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRemove ? '✅ 친구를 삭제했습니다.' : '✅ 친구 요청을 거절했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadFriendsData();
      } else {
        throw Exception(isRemove ? '친구 삭제 실패' : '친구 요청 거절 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 작업에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '👥 친구',
        showProfile: false,
      ),
      body: Column(
        children: [
          // 탭바
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: '친구 (${_friendsList.length})'),
              Tab(text: '요청 (${_pendingRequests.length})'),
              const Tab(text: '검색'),
            ],
          ),

          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsListView(),
                _buildPendingRequestsView(),
                _buildSearchView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsList.isEmpty) {
      return _buildEmptyFriends();
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _friendsList.length,
        itemBuilder: (context, index) {
          final friendship = _friendsList[index];
          return _buildFriendCard(friendship);
        },
      ),
    );
  }

  Widget _buildPendingRequestsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingRequests.isEmpty) {
      return _buildEmptyPendingRequests();
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildPendingRequestCard(request);
        },
      ),
    );
  }

  Widget _buildSearchView() {
    return Column(
      children: [
        // 검색바
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '이메일로 친구 검색...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchUsers,
          ),
        ),

        // 검색 결과
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '친구 검색',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '이메일로 친구를 검색해보세요!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '다른 이메일로 검색해보세요.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildSearchResultCard(user);
      },
    );
  }

  Widget _buildFriendCard(Friendship friendship) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: friendship.friendProfileImageUrl != null
                ? NetworkImage(friendship.friendProfileImageUrl!)
                : null,
            child: friendship.friendProfileImageUrl == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendship.friendDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '친구 된 날: ${friendship.updatedAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _rejectOrRemoveFriend(friendship.friendId, isRemove: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('친구 삭제'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(Friendship request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: request.friendProfileImageUrl != null
                ? NetworkImage(request.friendProfileImageUrl!)
                : null,
            child: request.friendProfileImageUrl == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.friendDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '요청일: ${request.createdAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _acceptFriendRequest(request.friendId),
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: '수락',
              ),
              IconButton(
                onPressed: () => _rejectOrRemoveFriend(request.friendId),
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: '거절',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> user) {
    final friendshipStatus = user['friendshipStatus'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: user['photoURL'] != null
                ? NetworkImage(user['photoURL']!)
                : null,
            child: user['photoURL'] == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(user['userId'], friendshipStatus),
        ],
      ),
    );
  }

  Widget _buildActionButton(String userId, String? friendshipStatus) {
    switch (friendshipStatus) {
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '친구',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '요청 중',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return ElevatedButton.icon(
          onPressed: () => _sendFriendRequest(userId),
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('친구 추가'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
        );
    }
  }

  Widget _buildEmptyFriends() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '아직 친구가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '검색 탭에서 친구를 찾아보세요!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(2),
            icon: const Icon(Icons.search),
            label: const Text('친구 검색하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPendingRequests() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '받은 친구 요청이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '새로운 친구 요청이 오면 여기에 표시됩니다.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
