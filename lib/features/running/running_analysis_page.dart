import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/health_kit_service.dart';
import '../../services/running_coaching_service.dart';
import 'running_detail_page.dart'; // Added import for RunningDetailPage

/// 달리기 전용 분석 페이지
class RunningAnalysisPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? runningData;

  const RunningAnalysisPage({
    super.key,
    this.runningData,
  });

  @override
  ConsumerState<RunningAnalysisPage> createState() =>
      _RunningAnalysisPageState();
}

class _RunningAnalysisPageState extends ConsumerState<RunningAnalysisPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<WorkoutData> _runningWorkouts = [];
  bool _isLoading = true;
  RunningCoaching? _currentCoaching;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadRunningData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 달리기 데이터 로드
  Future<void> _loadRunningData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final healthKitService = HealthKitService();
      final allWorkouts = await healthKitService.getRecentWorkouts(days: 30);

      // 달리기 운동만 필터링
      _runningWorkouts = allWorkouts
          .where((workout) =>
              workout.type.toLowerCase().contains('달리기') ||
              workout.type.toLowerCase().contains('running') ||
              workout.source?.toLowerCase().contains('workout') == true)
          .toList();

      // AI 코칭 생성
      if (_runningWorkouts.isNotEmpty) {
        final coachingService = RunningCoachingService();
        _currentCoaching = coachingService.generateCoaching(
          _runningWorkouts.first,
          recentWorkouts: _runningWorkouts,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 달리기 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏃‍♂️ 달리기 분석'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRunningData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 요약 카드
                _buildSummaryCard(),

                // 탭 컨트롤러
                Container(
                  color: Colors.grey[100],
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: '📊 요약'),
                      Tab(text: '📈 트렌딩'),
                      Tab(text: '❤️ 심박수'),
                      Tab(text: '⚡ 페이스'),
                      Tab(text: '📅 패턴'),
                    ],
                  ),
                ),

                // 탭 내용
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildTrendingTab(),
                      _buildHeartRateTab(),
                      _buildPaceTab(),
                      _buildPatternTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 요약 카드
  Widget _buildSummaryCard() {
    if (_runningWorkouts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: const Column(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 32),
            SizedBox(height: 8),
            Text(
              '달리기 데이터가 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Apple Watch로 달리기를 기록하거나 iPhone 건강앱에서 수동으로 추가해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final totalDistance = _runningWorkouts.fold(
        0.0, (sum, workout) => sum + (workout.distance ?? 0));
    final totalDuration = _runningWorkouts.fold(
        Duration.zero, (sum, workout) => sum + workout.duration);
    final totalCalories = _runningWorkouts.fold(
        0.0, (sum, workout) => sum + (workout.calories ?? 0));

    // 0으로 나누기 방지
    final averageDistance =
        totalDistance > 0 ? totalDistance / _runningWorkouts.length : 0.0;
    final averagePace =
        totalDistance > 0 ? totalDuration.inMinutes / totalDistance : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '이번 달 달리기 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '총 거리',
                totalDistance > 0
                    ? '${totalDistance.toStringAsFixed(1)}km'
                    : '데이터 없음',
                Icons.route,
              ),
              _buildSummaryItem(
                '총 시간',
                '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m',
                Icons.timer,
              ),
              _buildSummaryItem(
                '총 칼로리',
                totalCalories > 0 ? '${totalCalories.toInt()}kcal' : '데이터 없음',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '운동 횟수',
                '${_runningWorkouts.length}회',
                Icons.fitness_center,
              ),
              _buildSummaryItem(
                '평균 거리',
                averageDistance > 0
                    ? '${averageDistance.toStringAsFixed(1)}km'
                    : '데이터 없음',
                Icons.trending_up,
              ),
              _buildSummaryItem(
                '평균 페이스',
                averagePace > 0
                    ? '${averagePace.toStringAsFixed(1)}분/km'
                    : '데이터 없음',
                Icons.speed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요약 아이템
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
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

  /// 요약 탭
  Widget _buildSummaryTab() {
    if (_runningWorkouts.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _runningWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _runningWorkouts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              // 상세 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunningDetailPage(workout: workout),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.directions_run, color: Colors.blue[600]),
              ),
              title: Text('${workout.type} - ${workout.startTime.day}일'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '거리: ${workout.distance != null ? "${workout.distance!.toStringAsFixed(2)}km" : "데이터 없음"}'),
                  Text('시간: ${workout.duration.inMinutes}분'),
                  if (workout.calories != null)
                    Text('칼로리: ${workout.calories!.toInt()}kcal')
                  else
                    const Text('칼로리: 데이터 없음'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    workout.startTime.toString().substring(11, 16),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 트렌딩 탭
  Widget _buildTrendingTab() {
    if (_runningWorkouts.length < 2) {
      return const Center(
        child: Text('트렌딩 분석을 위해서는 2회 이상의 운동 데이터가 필요합니다'),
      );
    }

    // 거리 데이터가 모두 0인지 확인
    final hasDistanceData =
        _runningWorkouts.any((w) => w.distance != null && w.distance! > 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasDistanceData) ...[
            _buildTrendingChart('거리 트렌딩 (km)', [
              for (int i = 0; i < _runningWorkouts.length; i++)
                FlSpot(i.toDouble(), _runningWorkouts[i].distance ?? 0),
            ]),
            const SizedBox(height: 20),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      '거리 데이터가 없습니다',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '거리 트렌딩을 위해서는 운동 거리 데이터가 필요합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildTrendingChart('시간 트렌딩 (분)', [
            for (int i = 0; i < _runningWorkouts.length; i++)
              FlSpot(i.toDouble(),
                  _runningWorkouts[i].duration.inMinutes.toDouble()),
          ]),
        ],
      ),
    );
  }

  /// 심박수 탭
  Widget _buildHeartRateTab() {
    if (_currentCoaching == null) {
      return const Center(
        child: Text('심박수 데이터가 없습니다'),
      );
    }

    final hrAnalysis = _currentCoaching!.analysis.heartRateAnalysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 심박수 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '❤️ 심박수 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHRMetric(
                          '평균 심박수',
                          '${hrAnalysis.averageHR.toInt()} BPM',
                          Icons.favorite),
                      _buildHRMetric('최대 심박수',
                          '${hrAnalysis.maxHR.toInt()} BPM', Icons.trending_up),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(hrAnalysis.intensity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '운동 강도: ${hrAnalysis.intensity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 심박수 구간 차트
          if (hrAnalysis.zoneDistribution.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '심박수 구간 분포',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections:
                              hrAnalysis.zoneDistribution.entries.map((entry) {
                            final color = _getZoneColor(entry.key);
                            final percentage = (entry.value /
                                    hrAnalysis.zoneDistribution.values
                                        .reduce((a, b) => a + b)) *
                                100;
                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title:
                                  '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                              color: color,
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 페이스 탭
  Widget _buildPaceTab() {
    if (_currentCoaching == null) {
      return const Center(
        child: Text('페이스 데이터가 없습니다'),
      );
    }

    final paceAnalysis = _currentCoaching!.analysis.paceAnalysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이스 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ 페이스 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPaceMetric(
                          '페이스',
                          '${paceAnalysis.pace.toStringAsFixed(1)}분/km',
                          Icons.speed),
                      _buildPaceMetric(
                          '속도',
                          '${paceAnalysis.speed.toStringAsFixed(1)}km/h',
                          Icons.trending_up),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPaceQualityColor(paceAnalysis.quality),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.speed, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '페이스 품질: ${paceAnalysis.quality}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '거리 유형: ${paceAnalysis.distanceType}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AI 코칭 조언
          if (_currentCoaching!.advice.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 AI 코칭 조언',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._currentCoaching!.advice
                        .map((advice) => _buildAdviceCard(advice)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 패턴 탭
  Widget _buildPatternTab() {
    if (_runningWorkouts.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    // 요일별 운동 패턴 분석
    final weekdayPattern = <int, int>{};
    for (final workout in _runningWorkouts) {
      final weekday = workout.startTime.weekday;
      weekdayPattern[weekday] = (weekdayPattern[weekday] ?? 0) + 1;
    }

    // 시간대별 운동 패턴 분석
    final hourPattern = <int, int>{};
    for (final workout in _runningWorkouts) {
      final hour = workout.startTime.hour;
      hourPattern[hour] = (hourPattern[hour] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요일별 패턴
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 요일별 운동 패턴',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: weekdayPattern.values
                            .fold(0, (a, b) => a > b ? a : b)
                            .toDouble(),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const weekdays = [
                                  '월',
                                  '화',
                                  '수',
                                  '목',
                                  '금',
                                  '토',
                                  '일'
                                ];
                                return Text(weekdays[value.toInt()]);
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: weekdayPattern.entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key - 1, // 1-7을 0-6으로 변환
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 시간대별 패턴
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🕐 시간대별 운동 패턴',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: hourPattern.values
                            .fold(0, (a, b) => a > b ? a : b)
                            .toDouble(),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}시');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: hourPattern.entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: Colors.green,
                                width: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 트렌딩 차트
  Widget _buildTrendingChart(String title, List<FlSpot> spots) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 심박수 메트릭
  Widget _buildHRMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 페이스 메트릭
  Widget _buildPaceMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 조언 카드
  Widget _buildAdviceCard(CoachingAdvice advice) {
    Color cardColor;
    switch (advice.category) {
      case 'success':
        cardColor = Colors.green;
        break;
      case 'warning':
        cardColor = Colors.orange;
        break;
      case 'info':
        cardColor = Colors.blue;
        break;
      case 'tip':
        cardColor = Colors.purple;
        break;
      default:
        cardColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor),
      ),
      child: Row(
        children: [
          Text(advice.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 강도별 색상
  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case '매우 높음':
        return Colors.red;
      case '높음':
        return Colors.orange;
      case '보통':
        return Colors.blue;
      case '낮음':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 페이스 품질별 색상
  Color _getPaceQualityColor(String quality) {
    switch (quality) {
      case '매우 빠름':
        return Colors.red;
      case '빠름':
        return Colors.green;
      case '보통':
        return Colors.blue;
      case '느림':
        return Colors.orange;
      case '매우 느림':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 구간별 색상
  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'Z1':
        return Colors.grey;
      case 'Z2':
        return Colors.blue;
      case 'Z3':
        return Colors.green;
      case 'Z4':
        return Colors.orange;
      case 'Z5':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
