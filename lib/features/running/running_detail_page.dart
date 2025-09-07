import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../services/health_kit_service.dart';

/// 달리기 운동 상세 페이지
class RunningDetailPage extends ConsumerStatefulWidget {
  final WorkoutData? workout;
  final DateTime? selectedDate;
  final Map<String, dynamic>? healthKitData;

  const RunningDetailPage({
    super.key,
    this.workout,
    this.selectedDate,
    this.healthKitData,
  }) : assert(
            workout != null || (selectedDate != null && healthKitData != null),
            'Either workout or (selectedDate and healthKitData) must be provided');

  @override
  ConsumerState<RunningDetailPage> createState() => _RunningDetailPageState();
}

class _RunningDetailPageState extends ConsumerState<RunningDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late MapController _mapController; // 지도 컨트롤러 추가
  bool _isLoading = true;
  RunningDynamics? _runningDynamics;
  List<HeartRateZone>? _heartRateZones;
  List<SplitData>? _splitData;
  WorkoutRoute? _workoutRoute;

  // 마커와 폴리라인 상태 관리
  List<Marker> _routeMarkers = [];
  List<Polyline> _routePolylines = [];

  // 위치 정보 캐시
  static final Map<String, String> _locationCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _mapController = MapController(); // 지도 컨트롤러 초기화
    _loadDetailedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 상세 데이터 로드
  Future<void> _loadDetailedData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('🔍 RunningDetailPage: 상세 데이터 로드 시작');

      // Journal 페이지에서 온 경우 HealthKit 데이터 사용
      if (widget.healthKitData != null && widget.selectedDate != null) {
        final startTime = widget.healthKitData!['date'] as DateTime;
        final duration =
            Duration(seconds: widget.healthKitData!['duration'] as int);
        final endTime = startTime.add(duration);

        print(
            '🔍 HealthKit 데이터 사용: ${widget.healthKitData!['type']}, $startTime ~ $endTime');
      } else if (widget.workout != null) {
        print(
            '🔍 WorkoutData 사용: ${widget.workout!.type}, ${widget.workout!.startTime} ~ ${widget.workout!.startTime.add(widget.workout!.duration)}');
      }

      final healthKitService = HealthKitService();

      // 러닝 다이내믹스 데이터 수집
      print('🔍 러닝 다이내믹스 데이터 수집 시도...');

      DateTime startTime, endTime;
      if (widget.healthKitData != null && widget.selectedDate != null) {
        startTime = widget.healthKitData!['date'] as DateTime;
        endTime = startTime
            .add(Duration(seconds: widget.healthKitData!['duration'] as int));
      } else {
        startTime = widget.workout!.startTime;
        endTime = startTime.add(widget.workout!.duration);
      }

      _runningDynamics = await healthKitService.getRunningDynamics(
        startTime,
        endTime,
      );
      print('✅ 러닝 다이내믹스: ${_runningDynamics != null ? "성공" : "실패"}');

      // 심박수 구간별 데이터
      print('🔍 심박수 구간 데이터 수집 시도...');
      _heartRateZones = await healthKitService.getHeartRateZones(
        startTime,
        endTime,
      );
      print('✅ 심박수 구간: ${_heartRateZones?.length ?? 0}개 구간');

      // 스플릿 데이터
      print('🔍 스플릿 데이터 수집 시도...');
      _splitData = await healthKitService.getSplitData(
        startTime,
        endTime,
      );
      print('✅ 스플릿 데이터: ${_splitData?.length ?? 0}개 구간');

      // GPS 경로 데이터
      print('🔍 GPS 경로 데이터 수집 시도...');

      // GPS 데이터 수집을 위한 시간 범위 확장 (운동 전후 1시간)
      final gpsStartTime = startTime.subtract(Duration(hours: 1));
      final gpsEndTime = endTime.add(Duration(hours: 1));

      print(
          '🗺️ GPS 데이터 수집 시간 범위: ${gpsStartTime.toLocal()} ~ ${gpsEndTime.toLocal()}');
      print('🗺️ 원본 운동 시간: ${startTime.toLocal()} ~ ${endTime.toLocal()}');

      _workoutRoute = await healthKitService.getWorkoutRoute(
        gpsStartTime,
        gpsEndTime,
        workoutId: widget.workout?.uuid ??
            widget.workout?.id ??
            'unknown', // UUID 우선, 없으면 ID 사용
      );
      print('✅ GPS 경로: ${_workoutRoute?.points.length ?? 0}개 포인트');

      // 지도 요소 업데이트
      if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
        _updateMapElements();
        print('✅ GPS 경로 데이터로 지도 업데이트 완료');
      } else {
        print('⚠️ GPS 경로 데이터가 없습니다. 지도를 업데이트하지 않습니다.');
      }

      setState(() {
        _isLoading = false;
      });

      print('✅ RunningDetailPage: 상세 데이터 로드 완료');
    } catch (e) {
      print('❌ RunningDetailPage: 상세 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('달리기 상세 분석'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetailedData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 운동 요약 카드
                FutureBuilder<Widget>(
                  future: _buildWorkoutSummaryCard(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!;
                    } else {
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
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                  },
                ),

                // 탭 컨트롤러
                Container(
                  color: Colors.grey[100],
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: '📊 요약'),
                      Tab(text: '📈 메트릭'),
                      Tab(text: '❤️ 심박수'),
                      Tab(text: '🗺️ 경로'),
                    ],
                  ),
                ),

                // 탭 내용
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildMetricsTab(),
                      _buildHeartRateTab(),
                      _buildRouteTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 운동 요약 카드
  Future<Widget> _buildWorkoutSummaryCard() async {
    final workout = widget.workout;
    final healthKitData = widget.healthKitData;

    // HealthKit 데이터가 있으면 우선 사용, 없으면 workout 데이터 사용
    final distance =
        healthKitData?['distance']?.toDouble() ?? workout?.distance ?? 0;
    final durationSeconds =
        healthKitData?['duration']?.toInt() ?? workout?.duration.inSeconds ?? 0;
    final calories =
        healthKitData?['calories']?.toDouble() ?? workout?.calories ?? 0;

    // 시간을 시:분:초 형식으로 변환
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    final timeString =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // 페이스 계산 (분/km)
    final paceMinutes = distance > 0 ? (durationSeconds / 60) / distance : 0;
    final paceMinutesInt = paceMinutes.floor();
    final paceSeconds = ((paceMinutes - paceMinutesInt) * 60).round();
    final paceString = distance > 0
        ? '$paceMinutesInt\'${paceSeconds.toString().padLeft(2, '0')}"/KM'
        : 'N/A';

    // 속도 계산 (km/h)
    final speed = distance > 0 ? distance / (durationSeconds / 3600) : 0;

    // 케이던스 (SPM) - 러닝 다이내믹스에서 가져오거나 기본값 사용
    final cadence = _runningDynamics?.cadence?.round() ?? 0;

    // 날짜 정보 (HealthKit 데이터 또는 workout 데이터에서)
    final startTime = healthKitData?['date'] as DateTime? ??
        workout?.startTime ??
        widget.selectedDate ??
        DateTime.now();

    // 종료 시간 계산
    final endTime = startTime.add(Duration(seconds: durationSeconds));

    // 요일 배열
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[startTime.weekday - 1];

    // 날짜 형식: 9월 4일 (목) 시작시간 ~ 끝시간
    final dateString =
        '${startTime.month}월 ${startTime.day}일 ($weekday) ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    // 위치 정보 (시 단위) - 실제 위치 데이터에서 가져오기
    String locationString = '알수없음';

    // HealthKit 데이터에서 위치 정보 확인
    if (healthKitData != null && healthKitData['location'] != null) {
      locationString = healthKitData['location'] as String;
    } else if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      // GPS 데이터가 있으면 실제 역지오코딩으로 위치 정보 가져오기
      final firstPoint = _workoutRoute!.points.first;
      locationString =
          await _getShortAreaName(firstPoint.latitude, firstPoint.longitude);
    }

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
            dateString,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getLocationIcon(size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                locationString,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 첫 번째 행: 거리, 시간, 칼로리
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildSummaryItem(
                    '거리', '${distance.toStringAsFixed(2)}km', Icons.route),
              ),
              Expanded(
                child: _buildSummaryItem('시간', timeString, Icons.timer),
              ),
              Expanded(
                child: _buildSummaryItem('칼로리', '${calories.toInt()}kcal',
                    Icons.local_fire_department),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 두 번째 행: 페이스, 속도, 소스
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildSummaryItem('페이스', paceString, Icons.speed),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '속도', '${speed.toStringAsFixed(1)}km/h', Icons.trending_up),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '케이던스', cadence > 0 ? '${cadence}SPM' : 'N/A', Icons.speed),
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
            fontSize: 16,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기본 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 기본 정보',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      '운동 유형',
                      widget.workout?.type ??
                          widget.healthKitData?['type'] ??
                          '달리기'),
                  _buildInfoRow(
                      '시작 시간',
                      (widget.workout?.startTime ??
                              widget.healthKitData?['date'] as DateTime)
                          .toString()
                          .substring(0, 19)),
                  _buildInfoRow(
                      '지속 시간',
                      _formatDuration(widget.workout?.duration.inSeconds ??
                          (widget.healthKitData?['duration'] as int? ?? 0))),
                  _buildInfoRow('총 거리',
                      '${(widget.workout?.distance ?? widget.healthKitData?['distance'] ?? 0.0).toStringAsFixed(2)}km'),
                  _buildInfoRow('총 칼로리',
                      '${(widget.workout?.calories?.toInt() ?? widget.healthKitData?['calories']?.toInt() ?? 0)}kcal'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 계산된 메트릭
          if (_runningDynamics != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ 계산된 메트릭',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('평균 페이스', _calculateAveragePace()),
                    _buildInfoRow('평균 속도', '${_calculateAverageSpeed()}km/h'),
                    if (_runningDynamics!.cadence != null)
                      _buildInfoRow('평균 케이던스',
                          '${_runningDynamics!.cadence!.round()}SPM'),
                    if (_runningDynamics!.power != null)
                      _buildInfoRow(
                          '평균 파워', '${_runningDynamics!.power!.toInt()}W'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 메트릭 탭
  Widget _buildMetricsTab() {
    if (_runningDynamics == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              '상세 메트릭',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'HealthKit에서 추가 데이터를 수집하여\n상세한 메트릭을 제공합니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
          // 러닝 다이내믹스 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ 러닝 다이내믹스',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_runningDynamics!.strideLength != null)
                    _buildMetricRow(
                        '평균 보폭',
                        '${_runningDynamics!.strideLength!.toStringAsFixed(1)}m',
                        Icons.directions_run),
                  if (_runningDynamics!.groundContactTime != null)
                    _buildMetricRow(
                        '평균 지면 접촉 시간',
                        '${_runningDynamics!.groundContactTime!.toInt()}ms',
                        Icons.timer),
                  if (_runningDynamics!.verticalOscillation != null)
                    _buildMetricRow(
                        '수직 진폭',
                        '${_runningDynamics!.verticalOscillation!.toStringAsFixed(1)}cm',
                        Icons.trending_up),
                  if (_runningDynamics!.power != null)
                    _buildMetricRow('평균 파워',
                        '${_runningDynamics!.power!.toInt()}W', Icons.flash_on),
                  if (_runningDynamics!.cadence != null)
                    _buildMetricRow(
                        '평균 케이던스',
                        '${_runningDynamics!.cadence!.toStringAsFixed(1)}spm',
                        Icons.speed),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 계산된 메트릭 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 계산된 메트릭',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow(
                      '평균 페이스', _calculateAveragePace(), Icons.speed),
                  _buildMetricRow('평균 속도', '${_calculateAverageSpeed()}km/h',
                      Icons.trending_up),
                  _buildMetricRow(
                      '운동 효율성', _calculateEfficiency(), Icons.analytics),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 심박수 탭
  Widget _buildHeartRateTab() {
    if (_heartRateZones == null || _heartRateZones!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              '심박수 분석',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Apple Watch 심박수 데이터를 활용한\n상세한 심박수 분석을 제공합니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
          // 심박수 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '❤️ 심박수 요약',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeartRateMetric(
                          '평균 심박수',
                          '${_calculateAverageHeartRate()} BPM',
                          Icons.favorite,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildHeartRateMetric(
                          '최대 심박수',
                          '${_calculateMaxHeartRate()} BPM',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 심박수 구간별 분석 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 심박수 구간별 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._heartRateZones!.map((zone) => _buildZoneRow(zone)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 운동 강도 분석 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 운동 강도 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildIntensityAnalysis(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 경로 탭
  Widget _buildRouteTab() {
    print('🗺️ _buildRouteTab 호출됨');
    print('🗺️ _workoutRoute: $_workoutRoute');
    print(
        '🗺️ _workoutRoute?.points.length: ${_workoutRoute?.points.length ?? 0}');

    // GPS 경로 데이터가 없는 경우 메시지 표시
    if (_workoutRoute == null || _workoutRoute!.points.isEmpty) {
      print('🗺️ GPS 경로 데이터 없음 - 메시지 표시');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.orange),
            SizedBox(height: 8),
            Text(
              'GPS 경로 데이터 없음',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '이 운동에 대한 GPS 경로 데이터가\nHealthKit에서 제공되지 않았습니다.\n\n실제 운동 경로를 보려면\nApple Watch나 iPhone에서\n운동을 기록할 때\n위치 권한을 허용해야 합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              '💡 팁: 다음 운동부터는\n위치 권한을 허용해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_splitData == null || _splitData!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.green),
            SizedBox(height: 8),
            Text(
              '운동 경로',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'GPS 데이터를 활용한\n운동 경로 시각화를 제공합니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
          // 지도 표시
          Card(
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController, // 지도 컨트롤러 연결
                  options: MapOptions(
                    initialCenter: _getMapCenter(),
                    initialZoom: _calculateOptimalZoom(),
                    minZoom: 10.0,
                    maxZoom: 18.0,
                    keepAlive: true,
                    onMapReady: () {
                      print('🗺️ 지도가 준비되었습니다');
                      print('🗺️ 지도 중심점: ${_getMapCenter()}');
                      print('🗺️ 지도 줌 레벨: ${_calculateOptimalZoom()}');

                      // 마커와 폴리라인 상태 확인
                      final markers = _createRouteMarkers();
                      final polylines = _createRoutePolylines();

                      print('🗺️ 마커 개수: ${markers.length}');
                      print('🗺️ 폴리라인 개수: ${polylines.length}');

                      if (markers.isNotEmpty) {
                        print('  📍 첫 번째 마커 위치: ${markers.first.point}');
                        print('  📍 마지막 마커 위치: ${markers.last.point}');
                      }

                      if (polylines.isNotEmpty) {
                        print(
                            '  📍 첫 번째 폴리라인 포인트 수: ${polylines.first.points.length}');
                        print('  📍 첫 번째 폴리라인 색상: ${polylines.first.color}');
                      }

                      print('🗺️ 지도 바운드: ${_calculateMapBounds()}');

                      // 지도가 준비되면 실제 GPS 경로 바운드로 이동
                      final bounds = _calculateMapBounds();
                      if (bounds != null) {
                        print('🗺️ 지도 바운드로 이동 시도...');
                        print(
                            '🗺️ 바운드: ${bounds.southWest} ~ ${bounds.northEast}');

                        // 경계의 중심점 계산
                        final centerLat = (bounds.northEast.latitude +
                                bounds.southWest.latitude) /
                            2;
                        final centerLng = (bounds.northEast.longitude +
                                bounds.southWest.longitude) /
                            2;
                        final center = LatLng(centerLat, centerLng);

                        // 경로에 맞는 줌 레벨 계산
                        final latDiff = bounds.northEast.latitude -
                            bounds.southWest.latitude;
                        final lngDiff = bounds.northEast.longitude -
                            bounds.southWest.longitude;
                        final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

                        double zoomLevel = 15.0;
                        if (maxDiff > 0.1)
                          zoomLevel = 10.0;
                        else if (maxDiff > 0.05)
                          zoomLevel = 12.0;
                        else if (maxDiff > 0.02)
                          zoomLevel = 13.0;
                        else if (maxDiff > 0.01) zoomLevel = 14.0;

                        _mapController.move(center, zoomLevel);
                        print('✅ 지도 자동 줌 조정 완료: $center (줌: $zoomLevel)');

                        // 약간의 지연 후 다시 조정 (애니메이션 효과를 위해)
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _mapController.move(center, zoomLevel);
                            print('✅ 최종 지도 조정 완료');

                            // 지도 타일 로딩 강제 트리거
                            Future.delayed(const Duration(milliseconds: 200),
                                () {
                              if (mounted) {
                                // 약간의 줌 레벨 변경으로 타일 로딩 강제
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(
                                    _mapController.camera.center,
                                    currentZoom + 0.01);
                                Future.delayed(
                                    const Duration(milliseconds: 100), () {
                                  if (mounted) {
                                    _mapController.move(
                                        _mapController.camera.center,
                                        currentZoom);
                                    print('✅ 지도 타일 로딩 강제 완료');
                                  }
                                });
                              }
                            });
                          }
                        });
                      } else {
                        print('🗺️ 지도 바운드를 계산할 수 없음');
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.lyh205.habitfit',
                      maxZoom: 19,
                      tileProvider: NetworkTileProvider(),
                      minZoom: 1,
                      keepBuffer: 4, // 주변 타일들을 미리 로딩
                    ),
                    // 실제 GPS 경로 데이터가 있는 경우에만 마커와 폴리라인 표시
                    if (_workoutRoute != null &&
                        _workoutRoute!.points.isNotEmpty) ...[
                      PolylineLayer(
                        polylines: _routePolylines,
                      ),
                      MarkerLayer(
                        markers: _routeMarkers,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 심박수 구간별 색상 범례
          if (_heartRateZones != null && _heartRateZones!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💓 심박수 구간별 경로 색상',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: _heartRateZones!.map((zone) {
                        final zoneNumber = _parseZoneNumber(zone.zone);
                        final color = _getHeartRateZoneColor(zoneNumber);
                        final zoneName = _getHeartRateZoneName(zoneNumber);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$zoneName (${_formatDurationHoursMinutes(zone.time.inSeconds)})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 경로 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗺️ 경로 요약',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRouteMetric(
                          '총 구간',
                          '${_splitData!.length}개',
                          Icons.route,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildRouteMetric(
                          '총 거리',
                          '${widget.workout?.distance?.toStringAsFixed(2) ?? "N/A"}km',
                          Icons.straighten,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 구간별 상세 분석 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 구간별 상세 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._splitData!.map((split) => _buildSplitRow(split)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 메트릭 행
  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 평균 페이스 계산
  String _calculateAveragePace() {
    final distance = widget.healthKitData?['distance']?.toDouble() ??
        widget.workout?.distance ??
        0;
    final durationSeconds = widget.healthKitData?['duration']?.toInt() ??
        widget.workout?.duration.inSeconds ??
        0;
    if (distance > 0) {
      final paceMinutes = (durationSeconds / 60) / distance;
      final paceMinutesInt = paceMinutes.floor();
      final paceSeconds = ((paceMinutes - paceMinutesInt) * 60).round();
      return '$paceMinutesInt\'${paceSeconds.toString().padLeft(2, '0')}"/KM';
    }
    return 'N/A';
  }

  /// 평균 속도 계산
  String _calculateAverageSpeed() {
    final distance = widget.healthKitData?['distance']?.toDouble() ??
        widget.workout?.distance ??
        0;
    final durationSeconds = widget.healthKitData?['duration']?.toInt() ??
        widget.workout?.duration.inSeconds ??
        0;
    if (distance > 0) {
      return (distance / (durationSeconds / 3600)).toStringAsFixed(1);
    }
    return 'N/A';
  }

  /// 운동 효율성 계산 (예시)
  String _calculateEfficiency() {
    final distance = widget.healthKitData?['distance']?.toDouble() ??
        widget.workout?.distance ??
        0;
    final duration = widget.healthKitData?['duration']?.toInt() ??
        widget.workout?.duration.inMinutes ??
        0;
    final pace = distance > 0 ? duration / distance : 0;

    // 간단한 예시: 페이스가 빠르면 효율성이 높음
    if (pace < 5) {
      return '매우 높음';
    } else if (pace < 6) {
      return '높음';
    } else if (pace < 7) {
      return '보통';
    } else {
      return '낮음';
    }
  }

  /// 심박수 구간별 행
  Widget _buildZoneRow(HeartRateZone zone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${zone.zone} (${zone.minHR}-${zone.maxHR} BPM)',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            _formatDurationHoursMinutes(zone.time.inSeconds),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 심박수 메트릭 행
  Widget _buildHeartRateMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
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

  /// 평균 심박수 계산
  double _calculateAverageHeartRate() {
    if (_heartRateZones == null || _heartRateZones!.isEmpty) {
      return 0.0;
    }
    final totalHeartRate = _heartRateZones!.fold(
        0.0,
        (sum, zone) =>
            sum + (zone.minHR + zone.maxHR) / 2 * zone.time.inMinutes);
    final totalMinutes =
        _heartRateZones!.fold(0, (sum, zone) => sum + zone.time.inMinutes);
    return totalMinutes > 0
        ? (totalHeartRate / totalMinutes).roundToDouble()
        : 0.0;
  }

  /// 최대 심박수 계산
  double _calculateMaxHeartRate() {
    if (_heartRateZones == null || _heartRateZones!.isEmpty) {
      return 0.0;
    }
    return _heartRateZones!.fold(
        0.0, (max, zone) => max > zone.maxHR ? max : zone.maxHR.toDouble());
  }

  /// 운동 강도 분석 카드
  Widget _buildIntensityAnalysis() {
    final averageHeartRate = _calculateAverageHeartRate();

    String intensity;
    if (averageHeartRate < 120) {
      intensity = '매우 낮음';
    } else if (averageHeartRate < 140) {
      intensity = '낮음';
    } else if (averageHeartRate < 160) {
      intensity = '보통';
    } else if (averageHeartRate < 180) {
      intensity = '높음';
    } else {
      intensity = '매우 높음';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '평균 심박수: ${averageHeartRate.toStringAsFixed(0)} BPM',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '운동 강도: $intensity',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 경로 메트릭
  Widget _buildRouteMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
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

  /// 스플릿 행
  Widget _buildSplitRow(SplitData split) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${split.splitNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${split.time.inMinutes}분 - ${split.pace}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '심박수: ${split.heartRate} BPM',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (split.power != null)
            Text(
              '${split.power!.toInt()}W',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  /// 마커와 폴리라인 상태 업데이트
  void _updateMapElements() {
    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      setState(() {
        _routeMarkers = _createRouteMarkers();
        _routePolylines = _createRoutePolylines();
      });

      print('🗺️ 지도 요소 업데이트 완료:');
      print('  📍 마커: ${_routeMarkers.length}개');
      print('  📍 폴리라인: ${_routePolylines.length}개');
    }
  }

  /// 지도 중심점 계산
  LatLng _getMapCenter() {
    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      final points = _workoutRoute!.points;

      // 실제 GPS 데이터의 중심점 계산
      double totalLat = 0;
      double totalLng = 0;

      for (final point in points) {
        totalLat += point.latitude;
        totalLng += point.longitude;
      }

      final centerLat = totalLat / points.length;
      final centerLng = totalLng / points.length;

      print(
          '🗺️ 지도 중심점 계산: lat=$centerLat, lng=$centerLng (${points.length}개 포인트)');

      return LatLng(centerLat, centerLng);
    }

    // 기본값: 서울 시청 좌표
    print('🗺️ 기본 중심점 사용: 서울 시청');
    return const LatLng(37.5665, 126.9780);
  }

  /// 최적 줌 레벨 계산
  double _calculateOptimalZoom() {
    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      final points = _workoutRoute!.points;

      // 경로의 범위 계산
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // 위도/경도 차이에 따른 줌 레벨 계산
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      double zoom = 15.0; // 기본값
      if (maxDiff > 0.1)
        zoom = 10.0; // 매우 넓은 범위
      else if (maxDiff > 0.05)
        zoom = 12.0; // 넓은 범위
      else if (maxDiff > 0.02)
        zoom = 13.0; // 중간 범위
      else if (maxDiff > 0.01)
        zoom = 14.0; // 좁은 범위
      else
        zoom = 15.0; // 매우 좁은 범위

      print('🗺️ 최적 줌 레벨 계산: $zoom (범위: $maxDiff)');
      return zoom;
    }

    return 15.0; // 기본값
  }

  /// 지도 바운드 계산 (실제 GPS 경로 전체 범위)
  LatLngBounds? _calculateMapBounds() {
    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      final points = _workoutRoute!.points;

      // 경로의 범위 계산
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // 여백을 위해 약간 확장
      final latMargin = (maxLat - minLat) * 0.1;
      final lngMargin = (maxLng - minLng) * 0.1;

      final bounds = LatLngBounds(
        LatLng(minLat - latMargin, minLng - lngMargin),
        LatLng(maxLat + latMargin, maxLng + lngMargin),
      );

      print('🗺️ 지도 바운드 계산: $bounds');
      return bounds;
    }

    return null;
  }

  /// 경로 마커 생성 (심박수 구간별 색상)
  List<Marker> _createRouteMarkers() {
    final markers = <Marker>[];

    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      // 실제 GPS 데이터가 있는 경우
      final points = _workoutRoute!.points;

      print('🗺️ 마커 생성: ${points.length}개 GPS 포인트');

      // 시작점 마커 (녹색)
      final startPoint = points.first.toLatLng();
      print('  📍 시작점 마커: $startPoint');

      markers.add(
        Marker(
          point: startPoint,
          width: 20,
          height: 20,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

      // 중간 마커는 제거 - 폴리라인만으로 경로 표시

      // 종료점 마커 (빨간색)
      if (points.length > 1) {
        final endPoint = points.last.toLatLng();
        print('  📍 종료점 마커: $endPoint');

        markers.add(
          Marker(
            point: endPoint,
            width: 20,
            height: 20,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }

      print('✅ 마커 생성 완료: ${markers.length}개');
    } else {
      // GPS 데이터가 없으면 기본 마커만 표시
      print('⚠️ GPS 데이터 없음: 기본 마커만 생성');
      markers.add(
        Marker(
          point: const LatLng(37.5665, 126.9780),
          width: 20,
          height: 20,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  /// 경로 폴리라인 생성 (심박수 구간별 색상)
  List<Polyline> _createRoutePolylines() {
    final polylines = <Polyline>[];

    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      // 실제 GPS 데이터가 있는 경우
      final points = _workoutRoute!.points;
      final latLngPoints = points.map((point) => point.toLatLng()).toList();

      print(
          '🗺️ 폴리라인 생성: ${points.length}개 GPS 포인트 -> ${latLngPoints.length}개 LatLng 포인트');
      print('  📍 첫 번째 LatLng: ${latLngPoints.first}');
      print('  📍 마지막 LatLng: ${latLngPoints.last}');

      // 심박수 구간 데이터가 있으면 구간별로 색상 변경
      if (_heartRateZones != null && _heartRateZones!.isNotEmpty) {
        print('💓 심박수 구간별 폴리라인 생성 시작');

        // 전체 운동 시간 계산
        final totalDuration = _heartRateZones!
            .fold<Duration>(Duration.zero, (sum, zone) => sum + zone.time);

        // 각 구간별로 폴리라인 생성
        double currentTimeRatio = 0.0;

        for (int i = 0; i < _heartRateZones!.length; i++) {
          final zone = _heartRateZones![i];
          final zoneTimeRatio =
              zone.time.inMilliseconds / totalDuration.inMilliseconds;
          final nextTimeRatio = currentTimeRatio + zoneTimeRatio;

          // 해당 구간의 포인트 인덱스 계산
          final startIndex = (currentTimeRatio * latLngPoints.length).round();
          final endIndex = (nextTimeRatio * latLngPoints.length).round();

          if (startIndex < latLngPoints.length && endIndex > startIndex) {
            final zonePoints = latLngPoints.sublist(
                startIndex,
                endIndex > latLngPoints.length
                    ? latLngPoints.length
                    : endIndex);

            if (zonePoints.length > 1) {
              final zoneNumber = _parseZoneNumber(zone.zone);
              final zoneColor = _getHeartRateZoneColor(zoneNumber);

              polylines.add(
                Polyline(
                  points: zonePoints,
                  color: zoneColor,
                  strokeWidth: 4.0, // 조금 더 굵게
                  borderColor: Colors.white,
                  borderStrokeWidth: 1.0, // 흰색 테두리
                ),
              );

              print(
                  '  💓 구간 ${zone.zone}: ${zonePoints.length}개 포인트, 색상: $zoneColor');
            }
          }

          currentTimeRatio = nextTimeRatio;
        }

        print('✅ 심박수 구간별 폴리라인 생성 완료: ${polylines.length}개 구간');
      } else {
        // 심박수 구간 데이터가 없으면 기본 파란색 폴리라인
        print('💓 심박수 구간 데이터 없음: 기본 폴리라인 생성');
        polylines.add(
          Polyline(
            points: latLngPoints,
            color: Colors.blue,
            strokeWidth: 4.0,
            borderColor: Colors.white,
            borderStrokeWidth: 1.0,
          ),
        );
      }

      print('✅ 폴리라인 생성 완료: ${polylines.length}개');
    } else {
      // GPS 데이터가 없으면 샘플 경로 생성
      print('⚠️ GPS 데이터 없음: 샘플 경로 생성');
      final samplePoints = <LatLng>[];
      final baseLat = 37.5665;
      final baseLng = 126.9780;

      // 서울 시청에서 시작해서 동쪽으로 이동하는 샘플 경로
      for (int i = 0; i <= 6; i++) {
        final lat = baseLat + (i * 0.001);
        final lng = baseLng + (i * 0.001);
        samplePoints.add(LatLng(lat, lng));
      }

      polylines.add(
        Polyline(
          points: samplePoints,
          color: Colors.blue,
          strokeWidth: 4.0,
          borderColor: Colors.white,
          borderStrokeWidth: 1.0,
        ),
      );
    }

    return polylines;
  }

  /// 심박수 구간별 색상 반환
  Color _getHeartRateZoneColor(int zone) {
    switch (zone) {
      case 1: // Z1: 회복 구간 (파란색)
        return const Color(0xFF4A90E2);
      case 2: // Z2: 유산소 기반 (초록색)
        return const Color(0xFF7ED321);
      case 3: // Z3: 유산소 능력 (노란색)
        return const Color(0xFFF5A623);
      case 4: // Z4: 유산소 역치 (주황색)
        return const Color(0xFFFF6B35);
      case 5: // Z5: 무산소 능력 (빨간색)
        return const Color(0xFFD0021B);
      default:
        return Colors.blue;
    }
  }

  /// 심박수 구간별 이름 반환
  String _getHeartRateZoneName(int zone) {
    switch (zone) {
      case 1:
        return 'Z1 회복';
      case 2:
        return 'Z2 유산소';
      case 3:
        return 'Z3 능력';
      case 4:
        return 'Z4 역치';
      case 5:
        return 'Z5 무산소';
      default:
        return 'Z$zone';
    }
  }

  /// 심박수 구간 문자열에서 숫자 추출
  int _parseZoneNumber(String zoneString) {
    // "Z1", "Z2", "Z3", "Z4", "Z5" 형태에서 숫자 추출
    final match = RegExp(r'Z(\d+)').firstMatch(zoneString);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 1; // 기본값
  }

  /// 지속시간을 시:분:초 형식으로 포맷팅
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 지속시간을 시:분 형식으로 포맷팅
  String _formatDurationHoursMinutes(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 위/경도 -> "서울특별시 강남구" 같은 짧은 지역명
  Future<String> _getShortAreaName(double lat, double lng) async {
    // 캐시 키 생성 (소수점 3자리로 라운딩하여 캐시 효율성 증대)
    final cacheKey = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

    // 캐시에서 먼저 확인
    if (_locationCache.containsKey(cacheKey)) {
      return _locationCache[cacheKey]!;
    }

    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng,
          localeIdentifier: "ko_KR");

      if (placemarks.isEmpty) {
        _locationCache[cacheKey] = "위치 미상";
        return "위치 미상";
      }

      final placemark = placemarks.first;

      // 시 단위만 표시 (시/도 단위)
      final admin = (placemark.administrativeArea ?? "").trim(); // 서울특별시/경기도 등
      final result = admin.isNotEmpty ? admin : (placemark.country ?? "위치 미상");

      // 캐시에 저장
      _locationCache[cacheKey] = result;
      return result;
    } catch (e) {
      print('❌ 역지오코딩 오류: $e');
      _locationCache[cacheKey] = "위치 미상";
      return "위치 미상";
    }
  }

  /// 플랫폼별 위치 아이콘 반환
  Widget _getLocationIcon({double size = 16, Color? color}) {
    final icon = Platform.isIOS
        ? const Icon(CupertinoIcons.location_fill) // iOS 위치 서비스 화살표(삼각형)
        : const Icon(Icons.north_east); // Android 대각선 화살표

    return IconTheme.merge(
      data: IconThemeData(
        size: size,
        color: color ?? Colors.teal,
      ),
      child: icon,
    );
  }
}
