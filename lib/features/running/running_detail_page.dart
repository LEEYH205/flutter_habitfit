import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/health_kit_service.dart';

/// 달리기 운동 상세 페이지
class RunningDetailPage extends ConsumerStatefulWidget {
  final WorkoutData workout;

  const RunningDetailPage({
    super.key,
    required this.workout,
  });

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
      print(
          '🔍 운동 정보: ${widget.workout.type}, ${widget.workout.startTime} ~ ${widget.workout.startTime.add(widget.workout.duration)}');

      final healthKitService = HealthKitService();

      // 러닝 다이내믹스 데이터 수집
      print('🔍 러닝 다이내믹스 데이터 수집 시도...');
      _runningDynamics = await healthKitService.getRunningDynamics(
        widget.workout.startTime,
        widget.workout.startTime.add(widget.workout.duration),
      );
      print('✅ 러닝 다이내믹스: ${_runningDynamics != null ? "성공" : "실패"}');

      // 심박수 구간별 데이터
      print('🔍 심박수 구간 데이터 수집 시도...');
      _heartRateZones = await healthKitService.getHeartRateZones(
        widget.workout.startTime,
        widget.workout.startTime.add(widget.workout.duration),
      );
      print('✅ 심박수 구간: ${_heartRateZones?.length ?? 0}개 구간');

      // 스플릿 데이터
      print('🔍 스플릿 데이터 수집 시도...');
      _splitData = await healthKitService.getSplitData(
        widget.workout.startTime,
        widget.workout.startTime.add(widget.workout.duration),
      );
      print('✅ 스플릿 데이터: ${_splitData?.length ?? 0}개 구간');

      // GPS 경로 데이터
      print('🔍 GPS 경로 데이터 수집 시도...');

      // GPS 데이터 수집을 위한 시간 범위 확장 (운동 전후 1시간)
      final gpsStartTime =
          widget.workout.startTime.subtract(Duration(hours: 1));
      final gpsEndTime = widget.workout.startTime
          .add(widget.workout.duration)
          .add(Duration(hours: 1));

      print(
          '🗺️ GPS 데이터 수집 시간 범위: ${gpsStartTime.toLocal()} ~ ${gpsEndTime.toLocal()}');
      print(
          '🗺️ 원본 운동 시간: ${widget.workout.startTime.toLocal()} ~ ${widget.workout.startTime.add(widget.workout.duration).toLocal()}');

      _workoutRoute = await healthKitService.getWorkoutRoute(
        gpsStartTime,
        gpsEndTime,
        workoutId:
            widget.workout.uuid ?? widget.workout.id, // UUID 우선, 없으면 ID 사용
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
        title: Text('${widget.workout.type} 상세 분석'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                _buildWorkoutSummaryCard(),

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
  Widget _buildWorkoutSummaryCard() {
    final workout = widget.workout;
    final distance = workout.distance ?? 0;
    final duration = workout.duration.inMinutes;
    final pace = distance > 0 ? duration / distance : 0;
    final speed = distance > 0 ? distance / (duration / 60) : 0;

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
            '${workout.startTime.month}월 ${workout.startTime.day}일 ${workout.startTime.hour}:${workout.startTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                child: _buildSummaryItem('시간', '$duration분', Icons.timer),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '칼로리',
                    '${workout.calories?.toInt() ?? 0}kcal',
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
                child: _buildSummaryItem(
                    '페이스', '${pace.toStringAsFixed(1)}분/km', Icons.speed),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '속도', '${speed.toStringAsFixed(1)}km/h', Icons.trending_up),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '소스', workout.source ?? 'Apple Watch', Icons.watch),
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
                  _buildInfoRow('운동 유형', widget.workout.type),
                  _buildInfoRow('시작 시간',
                      widget.workout.startTime.toString().substring(0, 19)),
                  _buildInfoRow(
                      '지속 시간', '${widget.workout.duration.inMinutes}분'),
                  _buildInfoRow('총 거리',
                      '${widget.workout.distance?.toStringAsFixed(2) ?? "N/A"}km'),
                  _buildInfoRow(
                      '총 칼로리', '${widget.workout.calories?.toInt() ?? 0}kcal'),
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
                    _buildInfoRow('평균 페이스', '${_calculateAveragePace()}분/km'),
                    _buildInfoRow('평균 속도', '${_calculateAverageSpeed()}km/h'),
                    if (_runningDynamics!.strideLength != null)
                      _buildInfoRow('평균 보폭',
                          '${_runningDynamics!.strideLength!.toStringAsFixed(2)}m'),
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
                        '${_runningDynamics!.strideLength!.toStringAsFixed(2)}m',
                        Icons.directions_run),
                  if (_runningDynamics!.cadence != null)
                    _buildMetricRow(
                        '평균 케이던스',
                        '${_runningDynamics!.cadence!.toStringAsFixed(1)}spm',
                        Icons.speed),
                  if (_runningDynamics!.power != null)
                    _buildMetricRow('평균 파워',
                        '${_runningDynamics!.power!.toInt()}W', Icons.flash_on),
                  if (_runningDynamics!.verticalOscillation != null)
                    _buildMetricRow(
                        '수직 진폭',
                        '${_runningDynamics!.verticalOscillation!.toStringAsFixed(1)}cm',
                        Icons.trending_up),
                  if (_runningDynamics!.groundContactTime != null)
                    _buildMetricRow(
                        '지면 접촉 시간',
                        '${_runningDynamics!.groundContactTime!.toInt()}ms',
                        Icons.timer),
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
                      '평균 페이스', '${_calculateAveragePace()}분/km', Icons.speed),
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
    // GPS 경로 데이터가 없는 경우 메시지 표시
    if (_workoutRoute == null || _workoutRoute!.points.isEmpty) {
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
                        // 바운드의 중심점 계산
                        final centerLat = (bounds.northEast.latitude +
                                bounds.southWest.latitude) /
                            2;
                        final centerLng = (bounds.northEast.longitude +
                                bounds.southWest.longitude) /
                            2;
                        final center = LatLng(centerLat, centerLng);

                        _mapController.move(center, _calculateOptimalZoom());
                        print('✅ 지도 바운드 이동 완료: $center');
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.habitfit_mvp',
                      maxZoom: 19,
                      tileProvider: NetworkTileProvider(),
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
                          '${widget.workout.distance?.toStringAsFixed(2) ?? "N/A"}km',
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
    final distance = widget.workout.distance ?? 0;
    final duration = widget.workout.duration.inMinutes;
    if (distance > 0) {
      return (duration / distance).toStringAsFixed(1);
    }
    return 'N/A';
  }

  /// 평균 속도 계산
  String _calculateAverageSpeed() {
    final distance = widget.workout.distance ?? 0;
    final duration = widget.workout.duration.inMinutes;
    if (distance > 0) {
      return (distance / (duration / 60)).toStringAsFixed(1);
    }
    return 'N/A';
  }

  /// 운동 효율성 계산 (예시)
  String _calculateEfficiency() {
    final distance = widget.workout.distance ?? 0;
    final duration = widget.workout.duration.inMinutes;
    final pace = distance > 0 ? duration / distance : 0;
    final speed = distance > 0 ? distance / (duration / 60) : 0;

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
            '${zone.time.inMinutes}분',
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
    final maxHeartRate = _calculateMaxHeartRate();

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

  /// 경로 마커 생성
  List<Marker> _createRouteMarkers() {
    final markers = <Marker>[];

    if (_workoutRoute != null && _workoutRoute!.points.isNotEmpty) {
      // 실제 GPS 데이터가 있는 경우
      final points = _workoutRoute!.points;

      print('🗺️ 마커 생성: ${points.length}개 GPS 포인트');

      // 시작점 마커
      final startPoint = points.first.toLatLng();
      print('  📍 시작점 마커: $startPoint');

      markers.add(
        Marker(
          point: startPoint,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '시작',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
        ),
      );

      // 중간 구간별 마커 (실제 GPS 데이터 기반)
      for (int i = 1; i < points.length - 1; i++) {
        final point = points[i];
        final latLng = point.toLatLng();
        print('  📍 중간 마커 $i: $latLng');

        markers.add(
          Marker(
            point: latLng,
            width: 60,
            height: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$i',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.circle,
                  color: Colors.blue,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      }

      // 종료점 마커
      if (points.length > 1) {
        final endPoint = points.last.toLatLng();
        print('  📍 종료점 마커: $endPoint');

        markers.add(
          Marker(
            point: endPoint,
            width: 80,
            height: 80,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '종료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 24,
                ),
              ],
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
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '시작',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  /// 경로 폴리라인 생성
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

      // 폴리라인 생성
      final polyline = Polyline(
        points: latLngPoints,
        color: Colors.blue,
        strokeWidth: 3,
      );

      polylines.add(polyline);

      print('✅ 폴리라인 생성 완료: ${polylines.length}개');
      print('  📍 폴리라인 포인트 수: ${polyline.points.length}');
      print('  📍 폴리라인 색상: ${polyline.color}');
      print('  📍 폴리라인 두께: ${polyline.strokeWidth}');
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
          strokeWidth: 3,
        ),
      );
    }

    return polylines;
  }
}
