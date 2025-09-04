import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWithNotifications(title: 'Home'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and title
                _buildHeader(),
                const SizedBox(height: 24),

                // Activity Rings Section
                _buildActivityRingsSection(),
                const SizedBox(height: 24),

                // Step Count Cards
                _buildStepCountSection(),
                const SizedBox(height: 24),

                // Recommendation Card
                _buildRecommendationCard(),
                const SizedBox(height: 24),

                // Premium Feature Card
                _buildPremiumCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekday = _getWeekdayName(now.weekday);
    final day = now.day;
    final month = _getMonthName(now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$weekday, $day $month',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '오늘의 요약',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '활동 링',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                icon: Icons.directions_walk,
                title: '일일 걸음',
                value: '660/750 CAL',
                color: Colors.white,
                progress: 0.88,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityCard(
                icon: Icons.water_drop,
                title: '물 섭취',
                value: '8L/DAY',
                color: const Color(0xFFE8F5E8),
                progress: 0.75,
                isWater: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityCard(
                icon: Icons.directions_run,
                title: '활동',
                value: '20',
                color: const Color(0xFFFFE8F0),
                progress: 0.67,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double progress,
    bool isWater = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: color == Colors.white
            ? Border.all(color: Colors.grey.shade200)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isWater ? Colors.blue : Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (isWater) ...[
            Row(
              children: List.generate(
                  4,
                  (index) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index < 3 ? Colors.blue : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      )),
            ),
          ] else ...[
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isWater ? Colors.blue : Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCountSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStepCountCard(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStepCountCard(),
        ),
      ],
    );
  }

  Widget _buildStepCountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '걸음 수',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '13,818',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Simple bar chart representation
          Row(
            children: List.generate(
                7,
                (index) => Container(
                      margin: const EdgeInsets.only(right: 2),
                      width: 8,
                      height: 20 + (index * 3).toDouble(),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.format_quote,
              color: Colors.orange.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '더 나은 결과를 위한 루틴 변화 방법',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Michael Joah (Fitness+)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            'FITNESS+',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                const Text(
                  '모든 기능 잠금 해제',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }
}
