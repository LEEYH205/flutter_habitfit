import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

const _hkCh = MethodChannel('hk_running');

/// HealthKit 연동 테스트 페이지
class HealthTestPage extends StatefulWidget {
  const HealthTestPage({super.key});

  @override
  State<HealthTestPage> createState() => _HealthTestPageState();
}

class _HealthTestPageState extends State<HealthTestPage> {
  final HealthFactory _health = HealthFactory();
  bool _isAvailable = false;
  bool _hasPermissions = false;
  List<HealthDataPoint> _healthData = [];
  String _status = '초기화 중...';

  // 고급 러닝 메트릭 데이터 저장용
  List<Map<String, dynamic>> _runningSpeedData = [];
  List<Map<String, dynamic>> _runningStrideLengthData = [];
  List<Map<String, dynamic>> _runningPowerData = [];
  List<Map<String, dynamic>> _runningVerticalOscillationData = [];
  List<Map<String, dynamic>> _runningGroundContactTimeData = [];
  List<Map<String, dynamic>> _workoutRoutesData = [];

  @override
  void initState() {
    super.initState();
    _initializeHealth();
  }

  /// HealthKit 초기화
  Future<void> _initializeHealth() async {
    try {
      setState(() {
        _status = 'HealthKit 사용 가능 여부 확인 중...';
      });

      // HealthKit 사용 가능 여부 확인
      bool isAvailable = false;
      try {
        // 권한 요청으로 사용 가능 여부 확인
        final types = [HealthDataType.STEPS];
        isAvailable = await _health.requestAuthorization(types);
      } catch (e) {
        print('권한 요청으로도 확인 실패: $e');
        isAvailable = false;
      }

      setState(() {
        _isAvailable = isAvailable;
        _status = isAvailable ? 'HealthKit 사용 가능' : 'HealthKit 사용 불가';
      });

      if (isAvailable) {
        await _requestPermissions();
      }
    } catch (e) {
      setState(() {
        _status = '초기화 오류: $e';
      });
      print('HealthKit 초기화 오류: $e');
    }
  }

  /// 권한 요청
  Future<void> _requestPermissions() async {
    try {
      setState(() {
        _status = '권한 요청 중...';
      });

      // 포괄적인 건강 데이터 타입 요청 (기본 + 고급 운동 데이터)
      final types = [
        // 기본 건강 데이터
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME,
        HealthDataType.FLIGHTS_CLIMBED,

        // 고급 운동 데이터 (사용 가능한 타입들)
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,

        // 추가 운동 데이터 (사용 가능한 타입들)
        HealthDataType.EXERCISE_TIME,
        HealthDataType.FLIGHTS_CLIMBED,

        // 고급 달리기 메트릭 (iOS native에서 지원)
        // HealthDataType.RUNNING_STRIDE_LENGTH, // 달리기 보폭 길이
        // HealthDataType.RUNNING_SPEED, // 달리기 속도
        // HealthDataType.RUNNING_POWER, // 달리기 파워
        // HealthDataType.VERTICAL_OSCILLATION, // 수직 진폭
        // HealthDataType.GROUND_CONTACT_TIME, // 지면 접촉 시간
      ];

      print('🏥 HealthKit 권한 요청 시작: ${types.length}개 타입');

      final granted = await _health.requestAuthorization(types);

      print('🏥 HealthKit 권한 요청 결과: $granted');

      setState(() {
        _hasPermissions = granted;
        _status = granted ? '권한 승인됨' : '권한 거부됨';
      });

      if (granted) {
        await _fetchHealthData();
      } else {
        // 권한이 거부된 경우 사용자에게 안내
        setState(() {
          _status = '권한이 거부되었습니다. 설정에서 수동으로 허용해주세요.';
        });
      }
    } catch (e) {
      print('🏥 HealthKit 권한 요청 오류: $e');
      setState(() {
        _status = '권한 요청 오류: $e';
      });

      // 오류 발생 시 재시도 옵션 제공
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _status = '권한 요청에 실패했습니다. 다시 시도해주세요.';
      });
    }
  }

  /// iOS 고급 러닝 메트릭 권한 요청
  Future<void> _requestIOSRunningPermissions() async {
    setState(() => _status = 'iOS 러닝 고급 지표 권한 요청...');
    try {
      final ok = await _hkCh.invokeMethod<bool>('requestPermissions');
      setState(() {
        _status = (ok ?? false) ? '권한 승인됨(iOS 고급 지표)' : '권한 거부됨';
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 권한 요청 오류: $e';
      });
      print('iOS 권한 요청 오류: $e');
    }
  }

  /// iOS 러닝 속도 데이터 가져오기
  Future<void> _fetchIOSRunningSpeed() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final rows = await _hkCh.invokeMethod<List<dynamic>>('getRunningSpeed', {
        'from': start.millisecondsSinceEpoch,
        'to': now.millisecondsSinceEpoch,
      });

      setState(() {
        _runningSpeedData = [];
        if (rows != null && rows.isNotEmpty) {
          for (final row in rows) {
            final map = row as Map;
            try {
              final startTime = map['start'];
              final endTime = map['end'];
              final value = map['value'];

              if (startTime != null && endTime != null && value != null) {
                _runningSpeedData.add({
                  'start': DateTime.fromMillisecondsSinceEpoch(
                      startTime is int ? startTime : startTime.toInt()),
                  'end': DateTime.fromMillisecondsSinceEpoch(
                      endTime is int ? endTime : endTime.toInt()),
                  'value': value is double ? value : value.toDouble(),
                  'unit': 'm/s',
                });
              }
            } catch (e) {
              print('데이터 변환 오류: $e, row: $row');
            }
          }
        }
        _status = 'iOS runningSpeed ${_runningSpeedData.length}개';
        print('iOS 러닝 속도 데이터: ${_runningSpeedData.length}개');
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 속도 데이터 조회 오류: $e';
      });
      print('iOS 속도 데이터 조회 오류: $e');
    }
  }

  /// iOS 러닝 보폭 데이터 가져오기
  Future<void> _fetchIOSRunningStrideLength() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final rows =
          await _hkCh.invokeMethod<List<dynamic>>('getRunningStrideLength', {
        'from': start.millisecondsSinceEpoch,
        'to': now.millisecondsSinceEpoch,
      });

      setState(() {
        _runningStrideLengthData = [];
        if (rows != null && rows.isNotEmpty) {
          for (final row in rows) {
            final map = row as Map;
            try {
              final startTime = map['start'];
              final endTime = map['end'];
              final value = map['value'];

              if (startTime != null && endTime != null && value != null) {
                _runningStrideLengthData.add({
                  'start': DateTime.fromMillisecondsSinceEpoch(
                      startTime is int ? startTime : startTime.toInt()),
                  'end': DateTime.fromMillisecondsSinceEpoch(
                      endTime is int ? endTime : endTime.toInt()),
                  'value': value is double ? value : value.toDouble(),
                  'unit': 'm',
                });
              }
            } catch (e) {
              print('데이터 변환 오류: $e, row: $row');
            }
          }
        }
        _status = 'iOS runningStrideLength ${_runningStrideLengthData.length}개';
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 보폭 데이터 조회 오류: $e';
      });
      print('iOS 보폭 데이터 조회 오류: $e');
    }
  }

  /// iOS 러닝 파워 데이터 가져오기
  Future<void> _fetchIOSRunningPower() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final rows = await _hkCh.invokeMethod<List<dynamic>>('getRunningPower', {
        'from': start.millisecondsSinceEpoch,
        'to': now.millisecondsSinceEpoch,
      });

      setState(() {
        _runningPowerData = [];
        if (rows != null && rows.isNotEmpty) {
          for (final row in rows) {
            final map = row as Map;
            try {
              final startTime = map['start'];
              final endTime = map['end'];
              final value = map['value'];

              if (startTime != null && endTime != null && value != null) {
                _runningPowerData.add({
                  'start': DateTime.fromMillisecondsSinceEpoch(
                      startTime is int ? startTime : startTime.toInt()),
                  'end': DateTime.fromMillisecondsSinceEpoch(
                      endTime is int ? endTime : endTime.toInt()),
                  'value': value is double ? value : value.toDouble(),
                  'unit': 'W',
                });
              }
            } catch (e) {
              print('데이터 변환 오류: $e, row: $row');
            }
          }
        }
        _status = 'iOS runningPower ${_runningPowerData.length}개';
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 파워 데이터 조회 오류: $e';
      });
      print('iOS 파워 데이터 조회 오류: $e');
    }
  }

  /// iOS 러닝 수직 진폭 데이터 가져오기
  Future<void> _fetchIOSRunningVerticalOscillation() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final rows = await _hkCh
          .invokeMethod<List<dynamic>>('getRunningVerticalOscillation', {
        'from': start.millisecondsSinceEpoch,
        'to': now.millisecondsSinceEpoch,
      });

      setState(() {
        _runningVerticalOscillationData = [];
        if (rows != null && rows.isNotEmpty) {
          for (final row in rows) {
            final map = row as Map;
            try {
              final startTime = map['start'];
              final endTime = map['end'];
              final value = map['value'];

              if (startTime != null && endTime != null && value != null) {
                _runningVerticalOscillationData.add({
                  'start': DateTime.fromMillisecondsSinceEpoch(
                      startTime is int ? startTime : startTime.toInt()),
                  'end': DateTime.fromMillisecondsSinceEpoch(
                      endTime is int ? endTime : endTime.toInt()),
                  'value': value is double ? value : value.toDouble(),
                  'unit': 'cm',
                });
              }
            } catch (e) {
              print('데이터 변환 오류: $e, row: $row');
            }
          }
        }
        _status =
            'iOS runningVerticalOscillation ${_runningVerticalOscillationData.length}개';
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 수직 진폭 데이터 조회 오류: $e';
      });
      print('iOS 수직 진폭 데이터 조회 오류: $e');
    }
  }

  /// iOS 러닝 지면 접촉 시간 데이터 가져오기
  Future<void> _fetchIOSRunningGroundContactTime() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final rows = await _hkCh
          .invokeMethod<List<dynamic>>('getRunningGroundContactTime', {
        'from': start.millisecondsSinceEpoch,
        'to': now.millisecondsSinceEpoch,
      });

      setState(() {
        _runningGroundContactTimeData = [];
        if (rows != null && rows.isNotEmpty) {
          for (final row in rows) {
            final map = row as Map;
            try {
              final startTime = map['start'];
              final endTime = map['end'];
              final value = map['value'];

              if (startTime != null && endTime != null && value != null) {
                _runningGroundContactTimeData.add({
                  'start': DateTime.fromMillisecondsSinceEpoch(
                      startTime is int ? startTime : startTime.toInt()),
                  'end': DateTime.fromMillisecondsSinceEpoch(
                      endTime is int ? endTime : endTime.toInt()),
                  'value': value is double ? value : value.toDouble(),
                  'unit': 'ms',
                });
              }
            } catch (e) {
              print('데이터 변환 오류: $e, row: $row');
            }
          }
        }
        _status =
            'iOS runningGroundContactTime ${_runningGroundContactTimeData.length}개';
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 지면 접촉 시간 데이터 조회 오류: $e';
      });
      print('iOS 지면 접촉 시간 데이터 조회 오류: $e');
    }
  }

  /// iOS 운동 경로 데이터 가져오기
  Future<void> _fetchIOSWorkoutRoutes() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final rows = await _hkCh.invokeMethod<List<dynamic>>('getWorkoutRoutes', {
        'from': start.millisecondsSinceEpoch,
        'to': now.millisecondsSinceEpoch,
      });

      setState(() {
        _workoutRoutesData = [];
        if (rows != null && rows.isNotEmpty) {
          for (final row in rows) {
            final map = row as Map;
            try {
              final startTime = map['start'];
              final endTime = map['end'];
              final route = map['route'];
              final distance = map['distance'];
              final duration = map['duration'];

              if (startTime != null && endTime != null) {
                _workoutRoutesData.add({
                  'start': DateTime.fromMillisecondsSinceEpoch(
                      startTime is int ? startTime : startTime.toInt()),
                  'end': DateTime.fromMillisecondsSinceEpoch(
                      endTime is int ? endTime : endTime.toInt()),
                  'route': route,
                  'distance': distance is double
                      ? distance
                      : (distance is int ? distance.toDouble() : 0.0),
                  'duration': duration is double
                      ? duration
                      : (duration is int ? duration.toDouble() : 0.0),
                });
              }
            } catch (e) {
              print('데이터 변환 오류: $e, row: $row');
            }
          }
        }
        _status = 'iOS workoutRoutes ${_workoutRoutesData.length}개';
      });
    } catch (e) {
      setState(() {
        _status = 'iOS 운동 경로 데이터 조회 오류: $e';
      });
      print('iOS 운동 경로 데이터 조회 오류: $e');
    }
  }

  /// 모든 iOS 러닝 메트릭 데이터 한번에 가져오기
  Future<void> _fetchAllIOSRunningMetrics() async {
    setState(() => _status = '모든 고급 러닝 메트릭 데이터 가져오는 중...');

    try {
      await Future.wait([
        _fetchIOSRunningSpeed(),
        _fetchIOSRunningStrideLength(),
        _fetchIOSRunningPower(),
        _fetchIOSRunningVerticalOscillation(),
        _fetchIOSRunningGroundContactTime(),
        _fetchIOSWorkoutRoutes(),
      ]);

      setState(() {
        final totalData = _runningSpeedData.length +
            _runningStrideLengthData.length +
            _runningPowerData.length +
            _runningVerticalOscillationData.length +
            _runningGroundContactTimeData.length +
            _workoutRoutesData.length;
        _status = '모든 고급 러닝 메트릭 데이터 완료: 총 $totalData개';
      });
    } catch (e) {
      setState(() {
        _status = '전체 데이터 가져오기 오류: $e';
      });
      print('전체 데이터 가져오기 오류: $e');
    }
  }

  /// 고급 러닝 메트릭 데이터 표시 위젯
  Widget _buildRunningMetricsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요약 통계 카드
        _buildSummaryCard(),
        const SizedBox(height: 16),

        // 개별 메트릭 섹션들 (컴팩트하게)
        if (_runningSpeedData.isNotEmpty)
          _buildCompactMetricSection(
              '🚀 러닝 속도', _runningSpeedData, 'm/s', Colors.blue),

        if (_runningStrideLengthData.isNotEmpty)
          _buildCompactMetricSection(
              '👟 러닝 보폭', _runningStrideLengthData, 'm', Colors.green),

        if (_runningPowerData.isNotEmpty)
          _buildCompactMetricSection(
              '⚡ 러닝 파워', _runningPowerData, 'W', Colors.orange),

        if (_runningVerticalOscillationData.isNotEmpty)
          _buildCompactMetricSection(
              '📈 수직 진폭', _runningVerticalOscillationData, 'cm', Colors.purple),

        if (_runningGroundContactTimeData.isNotEmpty)
          _buildCompactMetricSection(
              '⏱️ 지면 접촉 시간', _runningGroundContactTimeData, 'ms', Colors.red),

        if (_workoutRoutesData.isNotEmpty) _buildCompactWorkoutRoutesSection(),
      ],
    );
  }

  /// 요약 통계 카드
  Widget _buildSummaryCard() {
    final totalData = _runningSpeedData.length +
        _runningStrideLengthData.length +
        _runningPowerData.length +
        _runningVerticalOscillationData.length +
        _runningGroundContactTimeData.length +
        _workoutRoutesData.length;

    if (totalData == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                '📊 러닝 메트릭 요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _buildSummaryItem('총 데이터', '$totalData개', Icons.data_usage),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '속도', '${_runningSpeedData.length}개', Icons.speed),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '보폭',
                    '${_runningStrideLengthData.length}개',
                    Icons.directions_walk),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                    '파워', '${_runningPowerData.length}개', Icons.flash_on),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '진폭',
                    '${_runningVerticalOscillationData.length}개',
                    Icons.trending_up),
              ),
              Expanded(
                child: _buildSummaryItem(
                    '경로', '${_workoutRoutesData.length}개', Icons.map),
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
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  /// 개별 메트릭 섹션 표시
  Widget _buildMetricSection(
      String title, List<Map<String, dynamic>> data, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '$title (${data.length}개)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length > 10 ? 10 : data.length, // 최대 10개만 표시
              itemBuilder: (context, index) {
                final item = data[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['value'].toStringAsFixed(2)} $unit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item['start'].hour.toString().padLeft(2, '0')}:${item['start'].minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '${item['start'].month}/${item['start'].day}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (data.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... 외 ${data.length - 10}개 더',
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 운동 경로 섹션 표시
  Widget _buildWorkoutRoutesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  '🗺️ 운동 경로 (${_workoutRoutesData.length}개)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _workoutRoutesData.length > 5
                  ? 5
                  : _workoutRoutesData.length, // 최대 5개만 표시
              itemBuilder: (context, index) {
                final item = _workoutRoutesData[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${item['distance']?.toStringAsFixed(2) ?? 'N/A'} km',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${item['duration']?.toStringAsFixed(0) ?? 'N/A'} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['start'].month}/${item['start'].day}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_workoutRoutesData.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... 외 ${_workoutRoutesData.length - 5}개 더',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 컴팩트한 메트릭 섹션 표시
  Widget _buildCompactMetricSection(
      String title, List<Map<String, dynamic>> data, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '$title (${data.length}개)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80, // 높이 줄임
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length > 8 ? 8 : data.length, // 최대 8개만 표시
              itemBuilder: (context, index) {
                final item = data[index];
                return Container(
                  width: 100, // 너비 줄임
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['value'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['start'].hour.toString().padLeft(2, '0')}:${item['start'].minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${item['start'].month}/${item['start'].day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: color.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (data.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... 외 ${data.length - 8}개 더',
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 컴팩트한 운동 경로 섹션 표시
  Widget _buildCompactWorkoutRoutesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  '🗺️ 운동 경로 (${_workoutRoutesData.length}개)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80, // 높이 줄임
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _workoutRoutesData.length > 4
                  ? 4
                  : _workoutRoutesData.length, // 최대 4개만 표시
              itemBuilder: (context, index) {
                final item = _workoutRoutesData[index];
                return Container(
                  width: 120, // 너비 줄임
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.green, size: 14),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${item['distance']?.toStringAsFixed(2) ?? 'N/A'} km',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.green, size: 14),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${item['duration']?.toStringAsFixed(0) ?? 'N/A'} min',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['start'].month}/${item['start'].day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_workoutRoutesData.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... 외 ${_workoutRoutesData.length - 4}개 더',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 건강 데이터 가져오기
  Future<void> _fetchHealthData() async {
    try {
      setState(() {
        _status = '데이터 가져오는 중...';
      });

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: 7));

      print('🔍 건강 데이터 조회 시작: ${startDate.toLocal()} ~ ${now.toLocal()}');

      // 1. WORKOUT 데이터 우선 확인 (가장 정확한 운동 정보)
      print('🏃‍♂️ WORKOUT 데이터 조회 시도...');

      // WORKOUT 권한 확인
      final hasWorkoutPermission =
          await _health.hasPermissions([HealthDataType.WORKOUT]);
      print('🏃‍♂️ WORKOUT 권한 상태: $hasWorkoutPermission');

      List<HealthDataPoint> workoutData = [];

      if (hasWorkoutPermission == true) {
        try {
          workoutData = await _health.getHealthDataFromTypes(
            startDate,
            now,
            [HealthDataType.WORKOUT],
          );

          print('🏃‍♂️ WORKOUT 데이터 ${workoutData.length}개 발견');

          if (workoutData.isNotEmpty) {
            print('🎯 WORKOUT 데이터 상세:');
            for (final workout in workoutData.take(5)) {
              print(
                  '  - 타입: ${workout.type}, 시작: ${workout.dateFrom}, 종료: ${workout.dateTo}');
              print('    값: ${workout.value}, 소스: ${workout.sourceName}');
            }
          }
        } catch (e) {
          print('⚠️ WORKOUT 데이터 조회 실패: $e');
        }
      } else {
        print('❌ WORKOUT 권한이 없습니다. 권한을 다시 요청합니다.');
        final granted =
            await _health.requestAuthorization([HealthDataType.WORKOUT]);
        print('🏃‍♂️ WORKOUT 권한 재요청 결과: $granted');

        if (granted) {
          try {
            workoutData = await _health.getHealthDataFromTypes(
              startDate,
              now,
              [HealthDataType.WORKOUT],
            );
            print('✅ WORKOUT 권한 재요청 후 데이터 ${workoutData.length}개 발견');
          } catch (e) {
            print('⚠️ WORKOUT 권한 재요청 후에도 조회 실패: $e');
          }
        }
      }

      // 2. 다른 데이터 타입들 조회
      print('📊 다른 건강 데이터 조회 중...');

      final stepsData = await _health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.STEPS],
      );

      final distanceData = await _health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.DISTANCE_WALKING_RUNNING],
      );

      final heartRateData = await _health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.HEART_RATE],
      );

      // 모든 데이터 합치기
      final allData = <HealthDataPoint>[];
      allData.addAll(workoutData); // WORKOUT 데이터를 맨 앞에 추가
      allData.addAll(stepsData);
      allData.addAll(distanceData);
      allData.addAll(heartRateData);

      setState(() {
        _healthData = allData;
        _status =
            '${allData.length}개의 데이터 포인트를 가져왔습니다 (WORKOUT: ${workoutData.length}개)';
      });

      // 콘솔에 요약 출력
      print('📊 총 데이터: ${allData.length}개');
      print('🏃‍♂️ WORKOUT: ${workoutData.length}개');
      print('👟 STEPS: ${stepsData.length}개');
      print('📏 DISTANCE: ${distanceData.length}개');
      print('❤️ HEART_RATE: ${heartRateData.length}개');

      // WORKOUT 데이터가 있다면 상세 정보 출력
      if (workoutData.isNotEmpty) {
        print('🎯 WORKOUT 데이터 상세:');
        for (final workout in workoutData.take(5)) {
          // 처음 5개만 출력
          print('  - ${workout.type}: ${workout.dateFrom} ~ ${workout.dateTo}');
          print('    값: ${workout.value}, 소스: ${workout.sourceName}');
        }
      }
    } catch (e) {
      setState(() {
        _status = '데이터 가져오기 오류: $e';
      });
      print('❌ 건강 데이터 가져오기 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 HealthKit 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 표시
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '상태: $_status',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('HealthKit 사용 가능: $_isAvailable'),
                    Text('권한 승인: $_hasPermissions'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAvailable ? _requestPermissions : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('🏥 HealthKit 권한 요청'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasPermissions ? _fetchHealthData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _hasPermissions ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('📊 데이터 가져오기'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // iOS 고급 러닝 메트릭 버튼들
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🍎 iOS 고급 러닝 메트릭',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _requestIOSRunningPermissions,
                            child: const Text('🍎 러닝 고급 권한'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchIOSRunningSpeed,
                            child: const Text('🚀 속도(m/s)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchIOSRunningStrideLength,
                            child: const Text('👟 보폭(m)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchIOSRunningPower,
                            child: const Text('⚡ 파워(W)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchIOSRunningVerticalOscillation,
                            child: const Text('📈 수직 진폭(cm)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchIOSRunningGroundContactTime,
                            child: const Text('⏱️ 지면 접촉(ms)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchIOSWorkoutRoutes,
                            child: const Text('🗺️ 운동 경로'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // 모든 고급 메트릭 데이터 한번에 가져오기
                              _fetchAllIOSRunningMetrics();
                            },
                            child: const Text('🔄 전체 데이터'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 권한 안내 텍스트
            if (!_hasPermissions)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 권한 요청 안내',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• 걸음 수, 심박수, 운동 거리 등 건강 데이터 접근 권한이 필요합니다\n• 권한 요청 버튼을 누르면 iOS 시스템 권한 다이얼로그가 표시됩니다\n• 권한을 허용해야 데이터를 가져올 수 있습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 고급 러닝 메트릭 데이터 표시
            if (_runningSpeedData.isNotEmpty ||
                _runningStrideLengthData.isNotEmpty ||
                _runningPowerData.isNotEmpty ||
                _runningVerticalOscillationData.isNotEmpty ||
                _runningGroundContactTimeData.isNotEmpty ||
                _workoutRoutesData.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🍎 고급 러닝 메트릭 데이터',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildRunningMetricsDisplay(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 건강 데이터 표시 (간소화)
            if (_healthData.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '건강 데이터 (${_healthData.length}개)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200, // 고정 높이로 제한
                        child: ListView.builder(
                          itemCount: _healthData.length > 20
                              ? 20
                              : _healthData.length, // 최대 20개만 표시
                          itemBuilder: (context, index) {
                            final data = _healthData[index];
                            return ListTile(
                              title: Text('${data.type}'),
                              subtitle:
                                  Text('${data.value} - ${data.dateFrom}'),
                              trailing: Text(data.sourceName ?? '알 수 없음'),
                            );
                          },
                        ),
                      ),
                      if (_healthData.length > 20)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... 외 ${_healthData.length - 20}개 더',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32), // 하단 여백 추가
          ],
        ),
      ),
    );
  }
}
