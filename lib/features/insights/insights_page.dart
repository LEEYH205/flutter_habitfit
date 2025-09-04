import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/stat_chip.dart';
import '../../providers/trend_provider.dart';
import '../../models/trend_data.dart';
import '../../usecases/trend_usecase.dart';
import '../../usecases/coach_usecase.dart';
import 'package:fl_chart/fl_chart.dart';

/// Insights 페이지 - 분석 중심: "어떤 패턴이 있지?"
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  TrendRange _selectedRange = TrendRange.week7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWithNotifications(title: 'Insights'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기간 선택
                _buildRangeSelector(),
                const SizedBox(height: 24),

                // 트렌드 개요
                _buildTrendOverview(),
                const SizedBox(height: 24),

                // 성과 차트
                _buildPerformanceCharts(),
                const SizedBox(height: 24),

                // 상세 통계
                _buildDetailedStats(),
                const SizedBox(height: 24),

                // AI 인사이트
                _buildAIInsights(),
                const SizedBox(height: 24),

                // 개선 제안
                _buildImprovementSuggestions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 기간 선택기
  Widget _buildRangeSelector() {
    return SectionCard(
      title: '분석 기간',
      icon: Icons.date_range,
      color: Colors.blue.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TrendRange.values.map((range) {
            final isSelected = _selectedRange == range;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(getTrendRangeName(range)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedRange = range;
                    });
                  }
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade700,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 트렌드 개요
  Widget _buildTrendOverview() {
    return Consumer(
      builder: (context, ref, child) {
        final trendDataAsync = ref.watch(trendProvider(_selectedRange));
        
        return trendDataAsync.when(
          data: (trendData) {
            final analysis = TrendUseCase.analyzeTrend(trendData);
            
            return SectionCard(
              title: '${getTrendRangeName(_selectedRange)} 개요',
              icon: Icons.analytics,
              color: Colors.green.shade50,
              child: Column(
                children: [
                  // 주요 지표
                  Row(
                    children: [
                      Expanded(
                        child: StatChip(
                          label: '습관 완료율',
                          value: '${trendData.habitCompletionRate.toStringAsFixed(1)}%',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatChip(
                          label: '운동 완료율',
                          value: '${trendData.workoutCompletionRate.toStringAsFixed(1)}%',
                          color: Colors.blue,
                          icon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatChip(
                          label: '일관성 점수',
                          value: '${trendData.consistencyScore.toStringAsFixed(1)}%',
                          color: Colors.purple,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatChip(
                          label: '최고 연속일',
                          value: '${trendData.maxConsecutiveHabitDays}일',
                          color: Colors.orange,
                          icon: Icons.local_fire_department,
                        ),
                      ),
                    ],
                  ),
                  
                  // 트렌드 방향
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTrendColor(analysis.direction).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTrendColor(analysis.direction).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getTrendIcon(analysis.direction),
                          color: _getTrendColor(analysis.direction),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getTrendText(analysis.direction),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _getTrendColor(analysis.direction),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildOverviewLoading(),
          error: (error, stack) => _buildOverviewError(),
        );
      },
    );
  }

  /// 성과 차트
  Widget _buildPerformanceCharts() {
    return Consumer(
      builder: (context, ref, child) {
        final trendDataAsync = ref.watch(trendProvider(_selectedRange));
        
        return trendDataAsync.when(
          data: (trendData) => SectionCard(
            title: '성과 차트',
            icon: Icons.bar_chart,
            color: Colors.orange.shade50,
            child: Column(
              children: [
                // 습관 완료율 차트
                _buildHabitCompletionChart(trendData),
                const SizedBox(height: 24),
                
                // 운동 완료율 차트
                _buildWorkoutCompletionChart(trendData),
              ],
            ),
          ),
          loading: () => _buildChartsLoading(),
          error: (error, stack) => _buildChartsError(),
        );
      },
    );
  }

  /// 상세 통계
  Widget _buildDetailedStats() {
    return Consumer(
      builder: (context, ref, child) {
        final trendDataAsync = ref.watch(trendProvider(_selectedRange));
        
        return trendDataAsync.when(
          data: (trendData) => SectionCard(
            title: '상세 통계',
            icon: Icons.assessment,
            color: Colors.purple.shade50,
            child: Column(
              children: [
                _buildStatRow('평균 일일 습관', '${trendData.averageDailyHabits.toStringAsFixed(1)}개', Colors.green),
                _buildStatRow('평균 일일 운동', '${trendData.averageDailyWorkouts.toStringAsFixed(1)}개', Colors.blue),
                _buildStatRow('총 완료 습관', '${trendData.completedHabits}개', Colors.green),
                _buildStatRow('총 완료 운동', '${trendData.completedWorkouts}개', Colors.blue),
                _buildStatRow('분석 기간', '${trendData.periodLength}일', Colors.grey),
              ],
            ),
          ),
          loading: () => _buildStatsLoading(),
          error: (error, stack) => _buildStatsError(),
        );
      },
    );
  }

  /// AI 인사이트
  Widget _buildAIInsights() {
    return Consumer(
      builder: (context, ref, child) {
        final trendDataAsync = ref.watch(trendProvider(_selectedRange));
        
        return trendDataAsync.when(
          data: (trendData) {
            final summary = TrendUseCase.generateTrendSummary(trendData);
            final weeklyCoaching = CoachUseCase.generateWeeklyCoaching(trendData);
            
            return SectionCard(
              title: 'AI 인사이트',
              icon: Icons.psychology,
              color: Colors.indigo.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.indigo.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            summary,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            weeklyCoaching,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildInsightsLoading(),
          error: (error, stack) => _buildInsightsError(),
        );
      },
    );
  }

  /// 개선 제안
  Widget _buildImprovementSuggestions() {
    return Consumer(
      builder: (context, ref, child) {
        final trendDataAsync = ref.watch(trendProvider(_selectedRange));
        
        return trendDataAsync.when(
          data: (trendData) {
            final suggestions = TrendUseCase.generateImprovementSuggestions(trendData);
            final nextWeekPlan = TrendUseCase.generateNextWeekPlan(trendData);
            
            return SectionCard(
              title: '개선 제안',
              icon: Icons.lightbulb,
              color: Colors.yellow.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 개선점:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.yellow.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.yellow.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.yellow.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  Text(
                    '다음 주 계획:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.yellow.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...nextWeekPlan.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 12,
                          color: Colors.yellow.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.yellow.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            );
          },
          loading: () => _buildSuggestionsLoading(),
          error: (error, stack) => _buildSuggestionsError(),
        );
      },
    );
  }

  /// 습관 완료율 차트
  Widget _buildHabitCompletionChart(TrendData trendData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '습관 완료율',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, trendData.habitCompletionRate),
                    FlSpot(1, trendData.habitCompletionRate),
                  ],
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 운동 완료율 차트
  Widget _buildWorkoutCompletionChart(TrendData trendData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 완료율',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, trendData.workoutCompletionRate),
                    FlSpot(1, trendData.workoutCompletionRate),
                  ],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 통계 행
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 트렌드 색상
  Color _getTrendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.blue;
    }
  }

  /// 트렌드 아이콘
  IconData _getTrendIcon(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return Icons.trending_up;
      case TrendDirection.declining:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  /// 트렌드 텍스트
  String _getTrendText(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return '개선되고 있습니다!';
      case TrendDirection.declining:
        return '조금 더 노력이 필요합니다.';
      case TrendDirection.stable:
        return '안정적인 패턴을 보이고 있습니다.';
    }
  }

  /// 로딩 상태들
  Widget _buildOverviewLoading() => _buildLoadingCard('개요');
  Widget _buildChartsLoading() => _buildLoadingCard('차트');
  Widget _buildStatsLoading() => _buildLoadingCard('통계');
  Widget _buildInsightsLoading() => _buildLoadingCard('인사이트');
  Widget _buildSuggestionsLoading() => _buildLoadingCard('제안');

  /// 에러 상태들
  Widget _buildOverviewError() => _buildErrorCard('개요');
  Widget _buildChartsError() => _buildErrorCard('차트');
  Widget _buildStatsError() => _buildErrorCard('통계');
  Widget _buildInsightsError() => _buildErrorCard('인사이트');
  Widget _buildSuggestionsError() => _buildErrorCard('제안');

  /// 로딩 카드
  Widget _buildLoadingCard(String title) {
    return SectionCard(
      title: title,
      icon: Icons.analytics,
      color: Colors.grey.shade50,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 에러 카드
  Widget _buildErrorCard(String title) {
    return SectionCard(
      title: title,
      icon: Icons.error,
      color: Colors.red.shade50,
      child: const Center(
        child: Text('데이터를 불러올 수 없습니다'),
      ),
    );
  }
}
