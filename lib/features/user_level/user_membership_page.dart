import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_level.dart';
import '../../services/user_level_service.dart';
import '../../widgets/app_bar_with_notifications.dart';

/// 멤버십 페이지
class UserMembershipPage extends ConsumerStatefulWidget {
  const UserMembershipPage({super.key});

  @override
  ConsumerState<UserMembershipPage> createState() => _UserMembershipPageState();
}

class _UserMembershipPageState extends ConsumerState<UserMembershipPage> {
  final UserLevelService _userLevelService = UserLevelService();

  UserLevel? _userLevel;
  List<UpgradeOption> _upgradeOptions = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserLevel();
  }

  Future<void> _loadUserLevel() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userLevel = await _userLevelService.getCurrentUserLevel();
      final stats = await _userLevelService.getUserLevelStats();

      if (userLevel != null) {
        final upgradeOptions =
            _userLevelService.getUpgradeOptions(userLevel.level);

        setState(() {
          _userLevel = userLevel;
          _upgradeOptions = upgradeOptions;
          _stats = stats;
        });
      }
    } catch (e) {
      print('❌ 멤버십 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('멤버십 정보를 불러오는데 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradeToPremium(UpgradeOption option) async {
    try {
      // 실제 결제 로직은 여기에 구현
      // 현재는 시뮬레이션으로 처리

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('결제 확인'),
          content: Text(
            '${option.title}\n'
            '가격: ${option.price.toStringAsFixed(0)}원\n'
            '기간: ${option.duration.inDays}일\n\n'
            '결제하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _processPayment(option);
              },
              child: const Text('결제'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ 업그레이드 오류: $e');
    }
  }

  Future<void> _processPayment(UpgradeOption option) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _userLevelService.startPremiumSubscription(
        duration: option.duration,
        price: option.price,
        paymentMethod: 'credit_card',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 프리미엄 구독이 시작되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserLevel();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 결제 처리에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBarWithNotifications(
          title: '👑 멤버십',
          showProfile: false,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userLevel == null) {
      return const Scaffold(
        appBar: AppBarWithNotifications(
          title: '👑 멤버십',
          showProfile: false,
        ),
        body: Center(
          child: Text('멤버십 정보를 불러올 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '👑 멤버십',
        showProfile: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserLevel,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 레벨 카드
              _buildCurrentLevelCard(),

              const SizedBox(height: 16),

              // 혜택 및 제한사항
              _buildBenefitsAndLimitationsCard(),

              const SizedBox(height: 16),

              // 업그레이드 옵션
              if (_upgradeOptions.isNotEmpty) ...[
                _buildUpgradeOptionsSection(),
                const SizedBox(height: 16),
              ],

              // 레벨 통계
              _buildStatsCard(),

              const SizedBox(height: 16),

              // 레벨 정보 안내
              _buildLevelInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLevelCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Color(_userLevel!.level.colorValue),
            Color(_userLevel!.level.colorValue).withOpacity(0.8),
            Color(_userLevel!.level.colorValue).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(_userLevel!.level.colorValue).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // 메인 컨텐츠
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 아이콘을 더 돋보이게
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _userLevel!.level.iconName,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userLevel!.level.displayName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_userLevel!.isPremiumActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '만료일: ${_userLevel!.premiumExpiryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              '기본 멤버십',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 상태 배지를 더 예쁘게
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _userLevel!.level.canUpgrade()
                                  ? Icons.arrow_upward
                                  : Icons.star,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _userLevel!.level.canUpgrade()
                                  ? '업그레이드 가능'
                                  : '최고 레벨',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsAndLimitationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '혜택 및 제한사항',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 혜택
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '혜택',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...(_userLevel!.benefits.map((benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('• $benefit',
                                style: const TextStyle(fontSize: 14)),
                          ))),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 제한사항
            if (_userLevel!.limitations.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '제한사항',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(_userLevel!.limitations.map((limitation) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text('• $limitation',
                                  style: const TextStyle(fontSize: 14)),
                            ))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '업그레이드 옵션',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_upgradeOptions.map((option) => _buildUpgradeOptionCard(option))),
      ],
    );
  }

  Widget _buildUpgradeOptionCard(UpgradeOption option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _upgradeToPremium(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: option.isPopular
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                option.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (option.isPopular) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '인기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${option.price.toStringAsFixed(0)}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '${option.duration.inDays}일',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '주요 혜택:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: option.benefits
                      .take(3)
                      .map((benefit) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              benefit,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                if (option.benefits.length > 3) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${option.benefits.length - 3}개 더',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '멤버십 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_stats.isNotEmpty) ...[
              _buildStatRow('현재 레벨', _stats['currentLevel'] ?? 'N/A'),
              _buildStatRow(
                  '프리미엄 활성', _stats['isPremiumActive'] == true ? '활성' : '비활성'),
              if (_stats['premiumExpiryDate'] != null)
                _buildStatRow('만료일',
                    _stats['premiumExpiryDate'].toString().split('T')[0]),
              _buildStatRow('총 구독 횟수', '${_stats['totalSubscriptions'] ?? 0}회'),
              _buildStatRow(
                  '업그레이드 가능', _stats['canUpgrade'] == true ? '가능' : '불가능'),
              if (_stats['nextLevel'] != null)
                _buildStatRow('다음 레벨', _stats['nextLevel']),
            ] else ...[
              const Text('통계 정보를 불러올 수 없습니다.'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfoCard() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '멤버십 안내',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• 무료: 기본 기능 이용 가능\n'
              '• 프리미엄: 고급 기능 및 무제한 이용\n'
              '• 코치: 개인 코칭 서비스 제공\n'
              '• 관리자: 모든 기능 및 관리 권한',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
