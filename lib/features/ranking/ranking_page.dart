import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ranking.dart';
import '../../services/ranking_service.dart';
import 'friends_page.dart';

/// 랭킹 메인 페이지
class RankingPage extends ConsumerStatefulWidget {
  final int initialTabIndex; // 초기 탭 인덱스 (0: 전체, 1: 친구, 2: 클럽)

  const RankingPage({
    super.key,
    this.initialTabIndex = 0, // 기본값은 전체 랭킹
  });

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with SingleTickerProviderStateMixin {
  final RankingService _rankingService = RankingService();

  late TabController _tabController;
  RankingCategory _selectedCategory = RankingCategory.totalPoints;
  RankingType _selectedType = RankingType.weekly;

  final Map<String, RankingStats?> _rankingStatsCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 초기 탭 인덱스로 TabController 생성
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2), // 0~2 범위로 제한
    );
    _loadRankingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankingData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 모든 카테고리와 타입 조합의 랭킹 데이터 로드
      for (final category in RankingCategory.values) {
        for (final type in RankingType.values) {
          final key = '${category.value}_${type.value}';
          final stats = await _rankingService.getRankingStats(
            category: category,
            type: type,
          );
          _rankingStatsCache[key] = stats;
        }
      }
    } catch (e) {
      print('❌ 랭킹 데이터 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('랭킹 데이터를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  RankingStats? get _currentRankingStats {
    final key = '${_selectedCategory.value}_${_selectedType.value}';
    return _rankingStatsCache[key];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '🏆 랭킹',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsPage(),
                ),
              );
            },
            tooltip: '친구',
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 및 기간 선택
          _buildFilterSection(),

          // 탭바 (전체, 친구, 클럽)
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '전체'),
              Tab(text: '친구'),
              Tab(text: '클럽'),
            ],
          ),

          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalRankingView(),
                _buildFriendsRankingView(),
                _buildClubRankingView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 카테고리 선택
          Row(
            children: [
              const Text(
                '카테고리: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RankingCategory.values.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category.icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(category.displayName),
                            ],
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 기간 선택
          Row(
            children: [
              const Text(
                '기간: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ...RankingType.values.map((type) {
                final isSelected = type == _selectedType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(type.displayName),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalRankingView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _currentRankingStats;
    if (stats == null || stats.topRankings.isEmpty) {
      return _buildEmptyRanking();
    }

    return RefreshIndicator(
      onRefresh: _loadRankingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 통계 요약
            _buildStatsOverview(stats),

            const SizedBox(height: 20),

            // 현재 사용자 랭킹
            if (stats.currentUserRanking != null)
              _buildCurrentUserRanking(stats.currentUserRanking!),

            const SizedBox(height: 20),

            // 상위 랭킹
            _buildTopRankings(stats.topRankings),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsRankingView() {
    return FutureBuilder<List<UserRanking>>(
      future: _rankingService.getFriendsRankings(
        category: _selectedCategory,
        type: _selectedType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('오류가 발생했습니다: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final friendsRankings = snapshot.data ?? [];
        if (friendsRankings.isEmpty) {
          return _buildEmptyFriendsRanking();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: friendsRankings.length,
            itemBuilder: (context, index) {
              return _buildRankingCard(friendsRankings[index],
                  showFriendBadge: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildClubRankingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '클럽 랭킹',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '곧 출시될 예정입니다!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(RankingStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _selectedCategory.icon,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCategory.displayName} ${_selectedType.displayName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '참가자 ${stats.totalParticipants}명',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('최고 점수', _formatScore(stats.topScore)),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child:
                    _buildStatItem('평균 점수', _formatScore(stats.averageScore)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserRanking(UserRanking userRanking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내 랭킹',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userRanking.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '#${userRanking.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                userRanking.formattedScore,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (userRanking.rankChange != 0) ...[
            const SizedBox(width: 8),
            _buildRankChangeIndicator(userRanking.rankChange),
          ],
        ],
      ),
    );
  }

  Widget _buildTopRankings(List<UserRanking> rankings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 상위 랭킹',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...rankings.take(10).map((ranking) => _buildRankingCard(ranking)),
      ],
    );
  }

  Widget _buildRankingCard(UserRanking ranking,
      {bool showFriendBadge = false}) {
    final isTop3 = ranking.rank <= 3;
    final medalColor = ranking.rank == 1
        ? Colors.amber
        : ranking.rank == 2
            ? Colors.grey.shade400
            : Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isTop3
            ? Border.all(color: medalColor, width: 2)
            : Border.all(color: Colors.grey.shade200),
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
          // 순위
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop3 ? medalColor : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTop3
                  ? Icon(
                      ranking.rank == 1
                          ? Icons.emoji_events
                          : Icons.military_tech,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '${ranking.rank}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // 프로필 이미지
          CircleAvatar(
            radius: 20,
            backgroundImage: ranking.profileImageUrl != null
                ? NetworkImage(ranking.profileImageUrl!)
                : null,
            child: ranking.profileImageUrl == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),

          const SizedBox(width: 12),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ranking.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showFriendBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '친구',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (ranking.scoreChange != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    ranking.formattedScoreChange,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          ranking.scoreChange > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 점수 및 변화
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ranking.formattedScore,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (ranking.rankChange != 0) ...[
                const SizedBox(height: 2),
                _buildRankChangeIndicator(ranking.rankChange),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankChangeIndicator(int rankChange) {
    if (rankChange == 0) return const SizedBox.shrink();

    final isUp = rankChange > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: isUp ? Colors.green : Colors.red,
        ),
        Text(
          rankChange.abs().toString(),
          style: TextStyle(
            fontSize: 10,
            color: isUp ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRanking() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '아직 랭킹 데이터가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '활동을 시작하고 랭킹에 참여해보세요!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsRanking() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '친구 랭킹이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '친구를 추가하고 함께 경쟁해보세요!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsPage(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('친구 추가하기'),
          ),
        ],
      ),
    );
  }

  String _formatScore(double score) {
    switch (_selectedCategory) {
      case RankingCategory.totalPoints:
        return '${score.toStringAsFixed(0)}점';
      case RankingCategory.habitCompletion:
        return '${(score * 100).toStringAsFixed(1)}%';
      case RankingCategory.runningDistance:
        return '${score.toStringAsFixed(1)}km';
      case RankingCategory.workoutTime:
        return '${(score / 60).toStringAsFixed(0)}분';
      case RankingCategory.streak:
        return '${score.toStringAsFixed(0)}일';
    }
  }
}
