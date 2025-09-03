import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/health_kit_service.dart';
import '../../services/running_coaching_service.dart' as coaching;
import '../../services/healthkit_route_service.dart';

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
  WorkoutData? _currentWorkout;
  bool _isLoading = true;
  coaching.RunningCoaching? _currentCoaching;
  List<Map<String, dynamic>>? _routePoints;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

      if (widget.runningData != null) {
        // 전달받은 특정 러닝 데이터 사용
        await _processRunningData(widget.runningData!);
      } else {
        // 기존 방식으로 최근 데이터 로드 (fallback)
        final healthKitService = HealthKitService();
        final allWorkouts = await healthKitService.getRecentWorkouts(days: 30);

        // 달리기 운동만 필터링
        final runningWorkouts = allWorkouts
            .where((workout) =>
                workout.type.toLowerCase().contains('달리기') ||
                workout.type.toLowerCase().contains('running') ||
                workout.source?.toLowerCase().contains('workout') == true)
            .toList();

        if (runningWorkouts.isNotEmpty) {
          _currentWorkout = runningWorkouts.first;
          await _loadWorkoutDetails(_currentWorkout!);
        }
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

  /// 전달받은 러닝 데이터 처리
  Future<void> _processRunningData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('id') || data.containsKey('uuid')) {
        // HealthKit 데이터인 경우
        final workoutId = data['id'] ?? data['uuid'];
        if (workoutId != null) {
          final healthKitService = HealthKitService();
          final workouts = await healthKitService.getRecentWorkouts(days: 30);

          // ID 또는 UUID로 특정 워크아웃 찾기
          _currentWorkout = workouts.firstWhere(
            (w) => w.id == workoutId || w.uuid == workoutId,
            orElse: () => WorkoutData(
              id: data['id'] ?? '',
              uuid: data['uuid'] ?? '',
              type: 'Running',
              startTime: data['startTime'] ?? DateTime.now(),
              endTime: data['endTime'] ?? DateTime.now(),
              duration: Duration(seconds: data['duration'] ?? 0),
              distance: data['distance'] ?? 0.0,
              calories: data['calories'] ?? 0.0,
              source: 'HealthKit',
            ),
          );

          await _loadWorkoutDetails(_currentWorkout!);
        }
      } else {
        // Firebase 데이터인 경우
        _currentWorkout = WorkoutData(
          id: data['id'] ?? '',
          uuid: data['uuid'] ?? '',
          type: data['type'] ?? 'Running',
          startTime: data['date'] ?? DateTime.now(),
          endTime: (data['date'] as DateTime?)
                  ?.add(Duration(seconds: data['duration'] ?? 0)) ??
              DateTime.now(),
          duration: Duration(seconds: data['duration'] ?? 0),
          distance: data['distance'] ?? 0.0,
          calories: data['calories'] ?? 0.0,
          source: 'Firebase',
        );

        await _loadWorkoutDetails(_currentWorkout!);
      }
    } catch (e) {
      print('러닝 데이터 처리 오류: $e');
    }
  }

  /// 워크아웃 상세 정보 로드
  Future<void> _loadWorkoutDetails(WorkoutData workout) async {
    try {
      // 심박수 데이터 로드 (HealthKit인 경우)
      List<coaching.HeartRateData>? heartRateData;
      if (workout.source == 'HealthKit') {
        try {
          final healthKitService = HealthKitService();
          final endTime =
              workout.endTime ?? workout.startTime.add(workout.duration);
          print('🔍 심박수 데이터 요청: ${workout.startTime} ~ $endTime');
          heartRateData = await healthKitService.getHeartRateData(
            workout.startTime,
            endTime,
          );
          print('✅ 심박수 데이터 ${heartRateData.length}개 로드 완료');
          if (heartRateData.isNotEmpty) {
            print(
                '📊 첫 번째 심박수: ${heartRateData.first.value} BPM at ${heartRateData.first.timestamp}');
            print(
                '📊 마지막 심박수: ${heartRateData.last.value} BPM at ${heartRateData.last.timestamp}');
          }
        } catch (e) {
          print('⚠️ 심박수 데이터 로드 실패: $e');
        }
      } else {
        print('⚠️ HealthKit이 아닌 워크아웃: ${workout.source}');
      }

      // 심박수 데이터가 없으면 모의 데이터 생성
      if (heartRateData == null || heartRateData.isEmpty) {
        print('📝 심박수 데이터가 없어서 모의 데이터 생성');
        heartRateData = _generateMockHeartRateDataForCoaching(workout);
      }

      // AI 코칭 생성
      final coachingService = coaching.RunningCoachingService();
      _currentCoaching = coachingService.generateCoaching(
        workout,
        recentWorkouts: [workout],
        heartRateData: heartRateData,
      );
      print('✅ AI 코칭 생성 완료');

      // GPS 루트 데이터 로드 (HealthKit인 경우)
      if (workout.source == 'HealthKit') {
        try {
          print('🔍 HealthKit에서 실제 GPS 루트 데이터 로드 시작');
          await HealthKitRouteService.requestPermissions();

          // 운동 ID가 있으면 사용, 없으면 시간 범위로 검색
          _routePoints = await HealthKitRouteService.getWorkoutRoute(
              workout.startTime,
              workout.endTime ?? workout.startTime.add(workout.duration),
              workoutId: workout.id.isNotEmpty ? workout.id : null);

          if (_routePoints != null && _routePoints!.isNotEmpty) {
            print('✅ 실제 GPS 루트 데이터 ${_routePoints!.length}개 로드 완료');
            print('📍 첫 번째 포인트: ${_routePoints!.first}');
            print('📍 마지막 포인트: ${_routePoints!.last}');
          } else {
            print('⚠️ HealthKit에서 GPS 루트 데이터를 찾을 수 없습니다');
            print('🔍 다른 방법으로 시도해보겠습니다...');

            // 특정 기간의 모든 운동 경로 데이터 시도
            final allRoutes = await HealthKitRouteService.getWorkoutRoutes(
                workout.startTime,
                workout.endTime ?? workout.startTime.add(workout.duration));

            if (allRoutes != null && allRoutes.isNotEmpty) {
              _routePoints = allRoutes;
              print('✅ 대체 방법으로 GPS 루트 데이터 ${_routePoints!.length}개 로드 완료');
            } else {
              print('❌ 모든 방법으로 GPS 루트 데이터를 찾을 수 없습니다');
            }
          }
        } catch (e) {
          print('❌ GPS 루트 데이터 로드 실패: $e');
        }
      } else {
        print('⚠️ HealthKit이 아닌 워크아웃: ${workout.source}');
      }
    } catch (e) {
      print('워크아웃 상세 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🏃‍♂️ 달리기 분석'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentWorkout == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🏃‍♂️ 달리기 분석'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('러닝 데이터를 찾을 수 없습니다')),
      );
    }

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
      body: Column(
        children: [
          // 세션 요약 카드
          _buildSessionSummaryCard(),

          // 탭 컨트롤러
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: '📊 상세'),
                Tab(text: '❤️ 심박수'),
                Tab(text: '⚡ 페이스'),
                Tab(text: '🗺️ 지도'),
              ],
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildHeartRateTab(),
                _buildPaceTab(),
                _buildMapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 세션 요약 카드
  Widget _buildSessionSummaryCard() {
    final workout = _currentWorkout!;
    final startTime = DateFormat('a h:mm', 'ko_KR').format(workout.startTime);
    final endTime = DateFormat('a h:mm', 'ko_KR')
        .format(workout.endTime ?? workout.startTime);

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
          Text(
            '$startTime - $endTime',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(workout.startTime),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '거리',
                workout.distance != null && workout.distance! > 0
                    ? '${workout.distance!.toStringAsFixed(2)}km'
                    : '데이터 없음',
                Icons.route,
              ),
              _buildSummaryItem(
                '시간',
                '${workout.duration.inHours.toString().padLeft(2, '0')}:${(workout.duration.inMinutes % 60).toString().padLeft(2, '0')}:${(workout.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                Icons.timer,
              ),
              _buildSummaryItem(
                '칼로리',
                workout.calories != null && workout.calories! > 0
                    ? '${workout.calories!.toInt()}kcal'
                    : '데이터 없음',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '평균 페이스',
                workout.distance != null && workout.distance! > 0
                    ? '${(workout.duration.inMinutes / workout.distance!).toStringAsFixed(1)}분/km'
                    : '데이터 없음',
                Icons.speed,
              ),
              _buildSummaryItem(
                '평균 속도',
                workout.distance != null && workout.distance! > 0
                    ? '${(workout.distance! / (workout.duration.inHours + workout.duration.inMinutes / 60)).toStringAsFixed(1)}km/h'
                    : '데이터 없음',
                Icons.trending_up,
              ),
              _buildSummaryItem(
                '위치',
                '서울시', // TODO: GPS 데이터에서 추출
                Icons.location_on,
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

  /// 상세 탭
  Widget _buildDetailsTab() {
    final workout = _currentWorkout!;
    final splits = _calculateSplits(workout);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기본 정보 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏃‍♂️ 운동 상세 정보',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('운동 유형', workout.type),
                  _buildDetailRow(
                      '시작 시간',
                      DateFormat('yyyy-MM-dd HH:mm:ss', 'ko_KR')
                          .format(workout.startTime)),
                  _buildDetailRow(
                      '종료 시간',
                      DateFormat('yyyy-MM-dd HH:mm:ss', 'ko_KR')
                          .format(workout.endTime ?? workout.startTime)),
                  _buildDetailRow('총 시간',
                      '${workout.duration.inHours}:${(workout.duration.inMinutes % 60).toString().padLeft(2, '0')}:${(workout.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
                  _buildDetailRow('총 거리',
                      '${workout.distance?.toStringAsFixed(2) ?? 0} km'),
                  _buildDetailRow(
                      '활동 칼로리', '${workout.calories?.toInt() ?? 0} kcal'),
                  _buildDetailRow('총 칼로리',
                      '${(workout.calories ?? 0) + 50} kcal'), // 대략적인 계산
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 스플릿 정보
          if (splits.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏃‍♂️ 스플릿',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...splits.map((split) => _buildSplitRow(split)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI 코칭
          if (_currentCoaching != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 AI 코칭',
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

  /// 스플릿 계산
  List<Map<String, dynamic>> _calculateSplits(WorkoutData workout) {
    if (workout.distance == null || workout.distance! <= 0) return [];

    final splits = <Map<String, dynamic>>[];
    final totalKm = workout.distance!;
    final totalTime = workout.duration.inSeconds;

    // 1km당 시간 계산
    final timePerKm = totalTime / totalKm;

    for (int i = 1; i <= totalKm.floor(); i++) {
      final splitTime = Duration(seconds: (timePerKm * i).round());
      final pace = timePerKm / 60; // 분/km

      splits.add({
        'km': i,
        'time':
            '${splitTime.inMinutes}:${(splitTime.inSeconds % 60).toString().padLeft(2, '0')}',
        'pace': '${pace.toStringAsFixed(1)}분/km',
      });
    }

    return splits;
  }

  /// 상세 행
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }

  /// 스플릿 행
  Widget _buildSplitRow(Map<String, dynamic> split) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${split['km']}km',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(split['time']),
          Text(split['pace'], style: const TextStyle(color: Colors.blue)),
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

          const SizedBox(height: 16),

          // 심박수 그래프 (모의 데이터)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '심박수 변화 그래프',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}분');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateMockHeartRateData(),
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                        ],
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

  /// 페이스 탭
  Widget _buildPaceTab() {
    if (_currentCoaching == null) {
      return const Center(
        child: Text('페이스 데이터가 없습니다'),
      );
    }

    final workout = _currentWorkout!;
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
                    '⚡ 페이스 & 속도 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPaceMetric(
                          '평균 페이스',
                          '${paceAnalysis.pace.toStringAsFixed(1)}분/km',
                          Icons.speed),
                      _buildPaceMetric(
                          '평균 속도',
                          '${paceAnalysis.speed.toStringAsFixed(1)}km/h',
                          Icons.trending_up),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPaceMetric(
                          '케이던스',
                          '180 spm', // 모의 데이터
                          Icons.repeat),
                      _buildPaceMetric(
                          '파워',
                          '250 W', // 모의 데이터
                          Icons.flash_on),
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

          // 페이스 그래프
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '페이스 변화 그래프',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toStringAsFixed(1));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}km');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateMockPaceData(workout.distance ?? 0),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
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

  /// 지도 탭
  Widget _buildMapTab() {
    if (_routePoints == null || _routePoints!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '실제 GPS 루트 데이터가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apple Watch나 iPhone으로 기록된\n운동의 GPS 데이터를 불러오지 못했습니다.\n\nHealthKit 권한을 확인하고\n실제 운동 데이터가 있는지 확인해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                '💡 팁: Apple Watch에서 운동을 시작할 때\n"위치 서비스"가 활성화되어 있는지 확인하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗺️ 달리기 루트',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[100]!,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMapWidget(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // GPS 루트 정보
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'GPS 루트 정보',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_routePoints!.length}개 포인트',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.play_circle_filled,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '시작: ${_formatTimestamp(_routePoints!.first['timestamp'])}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.stop_circle,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '종료: ${_formatTimestamp(_routePoints!.last['timestamp'])}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '위치: 한강공원 (여의도)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
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

  /// 모의 심박수 데이터 생성 (그래프용)
  List<FlSpot> _generateMockHeartRateData() {
    final spots = <FlSpot>[];
    final workout = _currentWorkout!;
    final durationMinutes = workout.duration.inMinutes;

    for (int i = 0; i <= durationMinutes; i++) {
      // 심박수 변화를 시뮬레이션 (시작: 120, 최고: 170, 끝: 140)
      double hr;
      if (i < durationMinutes * 0.2) {
        hr = 120 + (i / (durationMinutes * 0.2)) * 30; // 워밍업
      } else if (i < durationMinutes * 0.8) {
        hr = 150 +
            (i - durationMinutes * 0.2) / (durationMinutes * 0.6) * 20; // 메인 운동
      } else {
        hr = 170 -
            ((i - durationMinutes * 0.8) / (durationMinutes * 0.2)) * 30; // 쿨다운
      }

      spots.add(FlSpot(i.toDouble(), hr));
    }

    return spots;
  }

  /// 모의 심박수 데이터 생성 (AI 코칭용)
  List<coaching.HeartRateData> _generateMockHeartRateDataForCoaching(
      WorkoutData workout) {
    final duration = workout.duration.inMinutes;
    final data = <coaching.HeartRateData>[];

    // 운동 시간 동안 1분마다 심박수 데이터 생성
    for (int i = 0; i < duration; i++) {
      final timestamp = workout.startTime.add(Duration(minutes: i));
      // 운동 시작 시 낮은 심박수에서 점진적으로 증가
      final baseHR = 120 + (i * 2); // 120에서 시작해서 분당 2씩 증가
      final variation = (i % 3 == 0) ? 10 : -5; // 약간의 변동
      final heartRate = (baseHR + variation).clamp(110, 180);

      data.add(coaching.HeartRateData(
        timestamp: timestamp,
        value: heartRate.toDouble(),
        unit: 'BPM',
      ));
    }

    print('📝 모의 심박수 데이터 ${data.length}개 생성 완료');
    return data;
  }

  /// 모의 페이스 데이터 생성
  List<FlSpot> _generateMockPaceData(double totalDistance) {
    final spots = <FlSpot>[];
    final workout = _currentWorkout!;

    if (totalDistance <= 0) return spots;

    for (int i = 1; i <= totalDistance.floor(); i++) {
      // 페이스 변화를 시뮬레이션
      final basePace = workout.duration.inMinutes / totalDistance;
      final variation = (i % 2 == 0) ? 0.5 : -0.5; // 약간의 변동
      final pace = basePace + variation;

      spots.add(FlSpot(i.toDouble(), pace));
    }

    return spots;
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
            fontSize: 16,
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
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
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
  Widget _buildAdviceCard(coaching.CoachingAdvice advice) {
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

  /// 지도 위젯 생성
  Widget _buildMapWidget() {
    if (_routePoints == null || _routePoints!.isEmpty) {
      return const Center(
        child: Text('GPS 데이터가 없습니다'),
      );
    }

    // GPS 포인트들을 LatLng 리스트로 변환
    final routePoints = _routePoints!.map((point) {
      return LatLng(
        point['latitude'] as double,
        point['longitude'] as double,
      );
    }).toList();

    // 경로의 중심점 계산
    final centerLat =
        routePoints.map((p) => p.latitude).reduce((a, b) => a + b) /
            routePoints.length;
    final centerLng =
        routePoints.map((p) => p.longitude).reduce((a, b) => a + b) /
            routePoints.length;
    final center = LatLng(centerLat, centerLng);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        // OpenStreetMap 타일 레이어
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lyh205.habitfit',
        ),
        // GPS 루트 폴리라인
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: 4.0,
              color: Colors.blue,
            ),
          ],
        ),
        // 시작점 마커
        MarkerLayer(
          markers: [
            Marker(
              point: routePoints.first,
              width: 20,
              height: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
            // 종료점 마커
            Marker(
              point: routePoints.last,
              width: 20,
              height: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 타임스탬프 포맷팅
  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is num) {
        // iOS에서 밀리초 단위로 전달되는 경우
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      } else {
        return '알 수 없음';
      }
      return DateFormat('HH:mm:ss', 'ko_KR').format(dateTime);
    } catch (e) {
      print('⚠️ 타임스탬프 포맷팅 오류: $e, 값: $timestamp');
      return '알 수 없음';
    }
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
