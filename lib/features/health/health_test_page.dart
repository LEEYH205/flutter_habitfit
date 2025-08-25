import 'package:flutter/material.dart';
import 'package:health/health.dart';

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

      // 더 포괄적인 건강 데이터 타입 요청
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME,
        HealthDataType.FLIGHTS_CLIMBED,
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
      body: Padding(
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

            const SizedBox(height: 8),

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

            // 데이터 표시
            Expanded(
              child: Card(
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
                      Expanded(
                        child: ListView.builder(
                          itemCount: _healthData.length,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
