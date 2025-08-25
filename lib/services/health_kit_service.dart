import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

/// HealthKit 연동을 위한 서비스 클래스
class HealthKitService {
  static final HealthKitService _instance = HealthKitService._internal();
  factory HealthKitService() => _instance;
  HealthKitService._internal();

  final HealthFactory _health = HealthFactory();
  bool _isInitialized = false;

  /// HealthKit 초기화 및 권한 요청
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // HealthKit 사용 가능 여부 확인 (iOS에서만 사용 가능)
      bool isAvailable = false;
      try {
        // requestAuthorization으로 사용 가능 여부 확인
        final testTypes = [HealthDataType.STEPS];
        isAvailable = await _health.requestAuthorization(testTypes);
      } catch (e) {
        isAvailable = false;
      }

      if (!isAvailable) {
        print('❌ HealthKit is not available on this device');
        return false;
      }

      // 필요한 건강 데이터 타입들
      final types = [
        HealthDataType.WORKOUT, // 운동 세션 데이터 (우선순위 1)
        HealthDataType.HEART_RATE, // 심박수
        HealthDataType.STEPS, // 걸음 수
        HealthDataType.DISTANCE_WALKING_RUNNING, // 걷기/달리기 거리
        HealthDataType.ACTIVE_ENERGY_BURNED, // 활동 소모 칼로리
        HealthDataType.BASAL_ENERGY_BURNED, // 기초 대사 칼로리
        HealthDataType.EXERCISE_TIME, // 운동 시간
        HealthDataType.FLIGHTS_CLIMBED, // 계단 오르기
      ];

      final granted = await _health.requestAuthorization(types);

      if (granted) {
        _isInitialized = true;
        print('✅ HealthKit 권한이 승인되었습니다');
        return true;
      } else {
        print('❌ HealthKit 권한이 거부되었습니다');
        return false;
      }
    } catch (e) {
      print('❌ HealthKit 초기화 오류: $e');
      return false;
    }
  }

  /// 최근 운동 데이터 가져오기 (WORKOUT 데이터 우선, 없으면 걸음 수 기반으로 추정)
  Future<List<WorkoutData>> getRecentWorkouts({int days = 7}) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return [];
      }

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      print('🔍 운동 데이터 조회 시작: ${startDate.toLocal()} ~ ${now.toLocal()}');

      // 1. WORKOUT 데이터 우선 조회 (가장 정확한 운동 정보)
      try {
        print('🏃‍♂️ WORKOUT 데이터 조회 시도 중...');

        // WORKOUT 권한 확인
        final hasWorkoutPermission =
            await _health.hasPermissions([HealthDataType.WORKOUT]);
        print('🏃‍♂️ WORKOUT 권한 상태: $hasWorkoutPermission');

        if (hasWorkoutPermission == true) {
          final workoutData = await _health.getHealthDataFromTypes(
            startDate,
            now,
            [HealthDataType.WORKOUT],
          );

          print('🏃‍♂️ WORKOUT 데이터 ${workoutData.length}개 발견');

          if (workoutData.isNotEmpty) {
            // WORKOUT 데이터 상세 정보 출력
            print('🎯 WORKOUT 데이터 상세:');
            for (final workout in workoutData.take(5)) {
              print(
                  '  - 타입: ${workout.type}, 시작: ${workout.dateFrom}, 종료: ${workout.dateTo}');
              print('    값: ${workout.value}, 소스: ${workout.sourceName}');
            }

            return _parseWorkoutData(workoutData);
          } else {
            print('⚠️ WORKOUT 데이터가 비어있습니다. 다른 방법으로 시도합니다.');
          }
        } else {
          print('❌ WORKOUT 권한이 없습니다. 권한을 다시 요청합니다.');
          // WORKOUT 권한 재요청
          final granted =
              await _health.requestAuthorization([HealthDataType.WORKOUT]);
          print('🏃‍♂️ WORKOUT 권한 재요청 결과: $granted');

          if (granted) {
            // 권한이 승인되면 다시 시도
            final workoutData = await _health.getHealthDataFromTypes(
              startDate,
              now,
              [HealthDataType.WORKOUT],
            );

            if (workoutData.isNotEmpty) {
              print('✅ WORKOUT 권한 재요청 후 데이터 ${workoutData.length}개 발견');
              return _parseWorkoutData(workoutData);
            }
          }
        }
      } catch (e) {
        print('⚠️ WORKOUT 데이터 조회 실패: $e');
      }

      // 2. WORKOUT 데이터가 없으면 걸음 수 기반으로 운동 추정
      print('📊 걸음 수 기반으로 운동 데이터 추정 중...');

      // 걸음 수 데이터 조회
      final stepsData = await _health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.STEPS],
      );

      // 거리 데이터 조회
      final distanceData = await _health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.DISTANCE_WALKING_RUNNING],
      );

      // 심박수 데이터 조회
      final heartRateData = await _health.getHealthDataFromTypes(
        startDate,
        now,
        [HealthDataType.HEART_RATE],
      );

      // 일별 운동 데이터 생성
      final workoutList = <WorkoutData>[];
      final dailyData = <DateTime, Map<String, dynamic>>{};

      // 걸음 수 데이터 처리
      for (final step in stepsData) {
        final date = DateTime(
            step.dateFrom.year, step.dateFrom.month, step.dateFrom.day);
        if (!dailyData.containsKey(date)) {
          dailyData[date] = {
            'steps': 0,
            'distance': 0.0,
            'heartRate': <double>[]
          };
        }
        dailyData[date]!['steps'] += _getIntValue(step.value);
      }

      // 거리 데이터 처리
      for (final distance in distanceData) {
        final date = DateTime(distance.dateFrom.year, distance.dateFrom.month,
            distance.dateFrom.day);
        if (dailyData.containsKey(date)) {
          dailyData[date]!['distance'] += _getDoubleValue(distance.value);
        }
      }

      // 심박수 데이터 처리
      for (final hr in heartRateData) {
        final date =
            DateTime(hr.dateFrom.year, hr.dateFrom.month, hr.dateFrom.day);
        if (dailyData.containsKey(date)) {
          dailyData[date]!['heartRate'].add(_getDoubleValue(hr.value));
        }
      }

      // 운동 데이터 생성
      for (final entry in dailyData.entries) {
        final date = entry.key;
        final data = entry.value;

        if (data['steps'] > 0) {
          final workout = WorkoutData(
            id: date.millisecondsSinceEpoch.toString(),
            type: _determineWorkoutType(data['steps'], data['distance']),
            startTime: date,
            endTime: date.add(Duration(days: 1)),
            duration: Duration(hours: 24),
            distance: data['distance'],
            calories: _estimateCalories(data['steps'], data['distance']),
            source: 'HealthKit (추정)',
          );
          workoutList.add(workout);
        }
      }

      // 날짜순으로 정렬 (최신순)
      workoutList.sort((a, b) => b.startTime.compareTo(a.startTime));

      print('✅ ${workoutList.length}개의 운동 데이터를 가져왔습니다 (걸음 수 기반 추정)');
      return workoutList;
    } catch (e) {
      print('❌ 운동 데이터 조회 오류: $e');
      return [];
    }
  }

  /// 특정 운동의 상세 데이터 가져오기
  Future<DetailedWorkoutData?> getWorkoutDetails(WorkoutData workout) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }

      final startDate = workout.startTime;
      final endDate =
          workout.endTime ?? workout.startTime.add(Duration(days: 1));

      // 심박수 데이터 조회
      final heartRateData = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.HEART_RATE],
      );

      // 걸음 수 데이터 조회
      final stepsData = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.STEPS],
      );

      // 거리 데이터 조회
      final distanceData = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.DISTANCE_WALKING_RUNNING],
      );

      return DetailedWorkoutData(
        workout: workout,
        heartRateData: _parseHeartRateData(heartRateData),
        stepsData: _parseStepsData(stepsData),
        distanceData: _parseDistanceData(distanceData),
      );
    } catch (e) {
      print('❌ 운동 상세 데이터 조회 오류: $e');
      return null;
    }
  }

  /// HealthValue를 int로 변환
  int _getIntValue(HealthValue value) {
    try {
      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// HealthValue를 double로 변환
  double _getDoubleValue(HealthValue value) {
    try {
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// 심박수 데이터 파싱
  List<HeartRateData> _parseHeartRateData(List<HealthDataPoint> data) {
    final heartRateList = <HeartRateData>[];

    for (final point in data) {
      if (point.type == HealthDataType.HEART_RATE) {
        heartRateList.add(HeartRateData(
          timestamp: point.dateFrom,
          value: _getDoubleValue(point.value),
        ));
      }
    }

    // 시간순으로 정렬
    heartRateList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return heartRateList;
  }

  /// 걸음 수 데이터 파싱
  List<StepsData> _parseStepsData(List<HealthDataPoint> data) {
    final stepsList = <StepsData>[];

    for (final point in data) {
      if (point.type == HealthDataType.STEPS) {
        stepsList.add(StepsData(
          timestamp: point.dateFrom,
          value: _getIntValue(point.value),
        ));
      }
    }

    stepsList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return stepsList;
  }

  /// 거리 데이터 파싱
  List<DistanceData> _parseDistanceData(List<HealthDataPoint> data) {
    final distanceList = <DistanceData>[];

    for (final point in data) {
      if (point.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
        distanceList.add(DistanceData(
          timestamp: point.dateFrom,
          value: _getDoubleValue(point.value),
        ));
      }
    }

    distanceList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return distanceList;
  }

  /// 운동 타입 결정 (걸음 수와 거리 기반)
  String _determineWorkoutType(int steps, double distance) {
    if (steps >= 10000) {
      return '걷기';
    } else if (steps >= 5000) {
      return '가벼운 운동';
    } else if (steps >= 1000) {
      return '일상 활동';
    } else {
      return '휴식';
    }
  }

  /// 칼로리 추정 (걸음 수와 거리 기반)
  double? _estimateCalories(int steps, double distance) {
    // 간단한 칼로리 계산 공식 (체중 70kg 기준)
    if (steps > 0) {
      return (steps * 0.04) + (distance * 50); // 걸음당 0.04kcal + 거리당 50kcal
    }
    return null;
  }

  /// 권한 상태 확인
  Future<bool> checkPermissions() async {
    try {
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];

      for (final type in types) {
        final hasPermission = await _health.hasPermissions([type]);
        if (hasPermission != true) {
          print('❌ 권한이 없습니다: $type');
          return false;
        }
      }

      print('✅ 모든 HealthKit 권한이 승인되었습니다');
      return true;
    } catch (e) {
      print('❌ 권한 확인 오류: $e');
      return false;
    }
  }

  /// WORKOUT 데이터 파싱
  List<WorkoutData> _parseWorkoutData(List<HealthDataPoint> workoutPoints) {
    final workoutList = <WorkoutData>[];

    print('🔧 WORKOUT 데이터 파싱 시작: ${workoutPoints.length}개 포인트');

    for (final point in workoutPoints) {
      if (point.type == HealthDataType.WORKOUT) {
        try {
          print('  📍 WORKOUT 포인트 처리: ${point.dateFrom} ~ ${point.dateTo}');
          print(
              '    타입: ${point.type}, 값: ${point.value}, 소스: ${point.sourceName}');

          // dateTo가 null일 수 있으므로 안전하게 처리
          final endTime =
              point.dateTo ?? point.dateFrom.add(Duration(minutes: 30));
          final duration = endTime.difference(point.dateFrom);

          // WORKOUT 데이터에서 운동 정보 추출
          final workoutType = _getWorkoutTypeFromValue(point.value);
          final distance = _extractDistanceFromWorkout(point);
          final calories = _extractCaloriesFromWorkout(point);

          final workout = WorkoutData(
            id: point.dateFrom.millisecondsSinceEpoch.toString(),
            type: workoutType,
            startTime: point.dateFrom,
            endTime: endTime,
            duration: duration,
            distance: distance,
            calories: calories,
            source: 'HealthKit (WORKOUT) - ${point.sourceName ?? '알 수 없음'}',
          );

          print('    ✅ 파싱 완료: $workout');
          workoutList.add(workout);
        } catch (e) {
          print('⚠️ WORKOUT 데이터 파싱 오류: $e');
        }
      }
    }

    // 날짜순으로 정렬 (최신순)
    workoutList.sort((a, b) => b.startTime.compareTo(a.startTime));

    print('🏃‍♂️ WORKOUT 데이터 ${workoutList.length}개 파싱 완료');
    return workoutList;
  }

  /// WORKOUT 데이터에서 거리 추출
  double? _extractDistanceFromWorkout(HealthDataPoint point) {
    try {
      if (point.value is WorkoutHealthValue) {
        // value.toString()에서 거리 정보 파싱
        final valueStr = point.value.toString();
        print('🔍 거리 파싱 시도: $valueStr');

        if (valueStr.contains('totalDistance:')) {
          final regex = RegExp(r'totalDistance:\s*(\d+)');
          final match = regex.firstMatch(valueStr);
          if (match != null) {
            final distanceMeters = int.parse(match.group(1)!);
            final distanceKm = distanceMeters / 1000.0;
            print('✅ 거리 파싱 성공: ${distanceMeters}m -> ${distanceKm}km');
            return distanceKm;
          }
        }

        // 다른 패턴 시도
        if (valueStr.contains('distance:')) {
          final regex = RegExp(r'distance:\s*(\d+)');
          final match = regex.firstMatch(valueStr);
          if (match != null) {
            final distanceMeters = int.parse(match.group(1)!);
            final distanceKm = distanceMeters / 1000.0;
            print('✅ 거리 파싱 성공 (대체 패턴): ${distanceMeters}m -> ${distanceKm}km');
            return distanceKm;
          }
        }
      }

      print('❌ 거리 파싱 실패: 지원되지 않는 데이터 타입');
      return null;
    } catch (e) {
      print('❌ 거리 추출 오류: $e');
      return null;
    }
  }

  /// WORKOUT 데이터에서 칼로리 추출
  double? _extractCaloriesFromWorkout(HealthDataPoint point) {
    try {
      if (point.value is WorkoutHealthValue) {
        // value.toString()에서 칼로리 정보 파싱
        final valueStr = point.value.toString();
        print('🔍 칼로리 파싱 시도: $valueStr');

        if (valueStr.contains('totalEnergyBurned:')) {
          final regex = RegExp(r'totalEnergyBurned:\s*(\d+)');
          final match = regex.firstMatch(valueStr);
          if (match != null) {
            final calories = double.parse(match.group(1)!);
            print('✅ 칼로리 파싱 성공: ${calories}kcal');
            return calories;
          }
        }

        // 다른 패턴 시도
        if (valueStr.contains('energyBurned:')) {
          final regex = RegExp(r'energyBurned:\s*(\d+)');
          final match = regex.firstMatch(valueStr);
          if (match != null) {
            final calories = double.parse(match.group(1)!);
            print('✅ 칼로리 파싱 성공 (대체 패턴): ${calories}kcal');
            return calories;
          }
        }
      }

      print('❌ 칼로리 파싱 실패: 지원되지 않는 데이터 타입');
      return null;
    } catch (e) {
      print('❌ 칼로리 추출 오류: $e');
      return null;
    }
  }

  /// WORKOUT 값에서 운동 타입 추출
  String _getWorkoutTypeFromValue(HealthValue value) {
    try {
      print('🔍 WORKOUT 값에서 운동 타입 추출 시도: $value');

      // WORKOUT 데이터의 경우 value에서 운동 타입을 추출할 수 있음
      if (value is NumericHealthValue) {
        final numericValue = value.numericValue;
        print('  📊 숫자 값: $numericValue');

        // Apple Watch의 운동 타입 매핑 (실제로는 더 복잡할 수 있음)
        // 이 부분은 Apple Watch의 운동 타입과 매핑이 필요
        return '운동'; // 기본값
      }

      // 문자열 값인 경우
      if (value.toString().toLowerCase().contains('running')) {
        return '달리기';
      } else if (value.toString().toLowerCase().contains('walking')) {
        return '걷기';
      } else if (value.toString().toLowerCase().contains('cycling')) {
        return '자전거';
      } else if (value.toString().toLowerCase().contains('swimming')) {
        return '수영';
      }

      print('  🏷️ 추출된 운동 타입: 운동 (기본값)');
      return '운동';
    } catch (e) {
      print('⚠️ 운동 타입 추출 오류: $e');
      return '운동';
    }
  }
}

/// 운동 데이터 모델
class WorkoutData {
  final String id;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double? distance; // km
  final double? calories;
  final String? source;

  WorkoutData({
    required this.id,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.distance,
    this.calories,
    this.source,
  });

  @override
  String toString() {
    return 'WorkoutData(id: $id, type: $type, duration: ${duration.inMinutes}분, distance: ${distance?.toStringAsFixed(2)}km)';
  }
}

/// 상세 운동 데이터 모델
class DetailedWorkoutData {
  final WorkoutData workout;
  final List<HeartRateData> heartRateData;
  final List<StepsData> stepsData;
  final List<DistanceData> distanceData;

  DetailedWorkoutData({
    required this.workout,
    required this.heartRateData,
    required this.stepsData,
    required this.distanceData,
  });

  /// 평균 심박수 계산
  double get averageHeartRate {
    if (heartRateData.isEmpty) return 0.0;
    final sum = heartRateData.fold(0.0, (acc, data) => acc + data.value);
    return sum / heartRateData.length;
  }

  /// 최대 심박수
  double get maxHeartRate {
    if (heartRateData.isEmpty) return 0.0;
    return heartRateData
        .map((data) => data.value)
        .reduce((a, b) => a > b ? a : b);
  }

  /// 총 걸음 수
  int get totalSteps {
    return stepsData.fold(0, (acc, data) => acc + data.value);
  }

  /// 총 거리 (km)
  double get totalDistance {
    return distanceData.fold(0.0, (acc, data) => acc + data.value);
  }
}

/// 심박수 데이터 모델
class HeartRateData {
  final DateTime timestamp;
  final double value; // BPM

  HeartRateData({
    required this.timestamp,
    required this.value,
  });
}

/// 걸음 수 데이터 모델
class StepsData {
  final DateTime timestamp;
  final int value;

  StepsData({
    required this.timestamp,
    required this.value,
  });
}

/// 거리 데이터 모델
class DistanceData {
  final DateTime timestamp;
  final double value; // km

  DistanceData({
    required this.timestamp,
    required this.value,
  });
}
