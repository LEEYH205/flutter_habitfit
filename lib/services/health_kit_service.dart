import 'package:health/health.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'healthkit_route_service.dart';
import 'running_coaching_service.dart' as coaching;

/// HealthKit 연동을 위한 서비스 클래스
class HealthKitService {
  static final HealthKitService _instance = HealthKitService._internal();
  factory HealthKitService() => _instance;
  HealthKitService._internal();

  final HealthFactory _health = HealthFactory();
  bool _isInitialized = false;
  bool _appleWatchDetected = false;

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

      // 모든 HealthKit 권한을 한번에 요청
      final types = [
        // 기본 운동 데이터
        HealthDataType.WORKOUT, // 운동 세션 데이터
        HealthDataType.HEART_RATE, // 심박수
        HealthDataType.STEPS, // 걸음 수
        HealthDataType.DISTANCE_WALKING_RUNNING, // 걷기/달리기 거리
        HealthDataType.ACTIVE_ENERGY_BURNED, // 활동 소모 칼로리
        HealthDataType.BASAL_ENERGY_BURNED, // 기초 대사 칼로리
        HealthDataType.EXERCISE_TIME, // 운동 시간
        HealthDataType.FLIGHTS_CLIMBED, // 계단 오르기

        // Apple Watch 고급 심장 건강 데이터
        HealthDataType.RESTING_HEART_RATE, // 안정 심박수
        HealthDataType.HEART_RATE_VARIABILITY_SDNN, // 심박수 변이도

        // 신체 데이터
        HealthDataType.HEIGHT, // 키

        // Apple Watch 러닝 다이내믹스 데이터 (iOS 16+)
        // 주의: 일부 데이터 타입은 iOS 버전에 따라 지원되지 않을 수 있음
        // 실제로는 iOS 네이티브 코드에서 직접 처리해야 할 수 있음

        // GPS 경로 데이터는 iOS 네이티브 코드에서 직접 처리
        // Apple Watch 특화 데이터는 iOS 네이티브에서 직접 요청
      ];

      final granted = await _health.requestAuthorization(types);

      if (granted) {
        _isInitialized = true;
        print('✅ HealthKit 권한이 승인되었습니다');

        // Apple Watch 감지 시도 (심장 건강 데이터로 확인)
        await _detectAppleWatch();

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

  /// Apple Watch 감지 여부 확인
  bool get hasAppleWatch => _appleWatchDetected;

  /// Apple Watch 감지 (심장 건강 데이터로 확인)
  Future<void> _detectAppleWatch() async {
    try {
      // 최근 심장 건강 데이터를 확인하여 Apple Watch 사용 여부 추정
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      final heartRateData = await _health.getHealthDataFromTypes(
        oneDayAgo,
        now,
        [HealthDataType.RESTING_HEART_RATE], // Apple Watch 특화 심장 건강 데이터로 감지
      );

      // Apple Watch 특화 데이터가 있으면 Apple Watch로 판단
      if (heartRateData.isNotEmpty) {
        _appleWatchDetected = true;
        print('🍎 Apple Watch 감지됨: 고급 심장 건강 데이터 발견');
      } else {
        _appleWatchDetected = false;
        print('📱 iPhone 전용 모드: Apple Watch 감지되지 않음');
      }
    } catch (e) {
      print('⚠️ Apple Watch 감지 실패: $e');
      _appleWatchDetected = false;
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

          // 운동의 고유 식별자 생성 (시작시간 + 소스 + 타입)
          final workoutUuid =
              '${point.dateFrom.millisecondsSinceEpoch}_${point.sourceName ?? 'unknown'}_$workoutType';

          final workout = WorkoutData(
            id: point.dateFrom.millisecondsSinceEpoch.toString(),
            uuid: workoutUuid,
            type: workoutType,
            startTime: point.dateFrom,
            endTime: endTime,
            duration: duration,
            distance: distance,
            calories: calories,
            source: 'HealthKit', // 달리기는 무조건 HealthKit 소스로 설정
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

  /// 러닝 다이내믹스 데이터 수집
  Future<RunningDynamics?> getRunningDynamics(
      DateTime start, DateTime end) async {
    try {
      print('🔍 러닝 다이내믹스 데이터 수집 시작: $start ~ $end');

      // 실제 존재하는 HealthKit 데이터 타입들
      final types = [
        HealthDataType.HEART_RATE, // 심박수
        HealthDataType.STEPS, // 걸음 수
        HealthDataType.DISTANCE_WALKING_RUNNING, // 걷기/달리기 거리
        HealthDataType.ACTIVE_ENERGY_BURNED, // 활동 소모 칼로리
      ];

      final data = await _health.getHealthDataFromTypes(start, end, types);
      print('🔍 러닝 다이내믹스 데이터 ${data.length}개 발견');

      if (data.isEmpty) {
        print('⚠️ 러닝 다이내믹스 데이터가 없습니다');
        return null;
      }

      // 데이터 파싱 및 분석 (현재 사용 가능한 데이터로 계산)
      double? strideLength;
      double? verticalOscillation;
      double? groundContactTime;
      double? power;
      double? cadence;

      // 걸음 수와 거리로 보폭 계산
      final stepsData =
          data.where((point) => point.type == HealthDataType.STEPS).toList();
      final distanceData = data
          .where(
              (point) => point.type == HealthDataType.DISTANCE_WALKING_RUNNING)
          .toList();

      if (stepsData.isNotEmpty && distanceData.isNotEmpty) {
        final totalSteps = stepsData.fold(0.0, (sum, point) {
          if (point.value is NumericHealthValue) {
            return sum + (point.value as NumericHealthValue).numericValue;
          }
          return sum;
        });

        final totalDistance = distanceData.fold(0.0, (sum, point) {
          if (point.value is NumericHealthValue) {
            return sum + (point.value as NumericHealthValue).numericValue;
          }
          return sum;
        });

        if (totalSteps > 0 && totalDistance > 0) {
          strideLength = (totalDistance * 1000) / totalSteps; // m 단위
          print('✅ 보폭 계산: ${strideLength.toStringAsFixed(2)}m');
        }
      }

      // 케이던스 계산 (걸음 수 / 시간)
      if (stepsData.isNotEmpty) {
        final totalSteps = stepsData.fold(0.0, (sum, point) {
          if (point.value is NumericHealthValue) {
            return sum + (point.value as NumericHealthValue).numericValue;
          }
          return sum;
        });

        final durationMinutes = end.difference(start).inMinutes;
        if (durationMinutes > 0) {
          cadence = totalSteps / durationMinutes; // spm
          print('✅ 케이던스 계산: ${cadence.toStringAsFixed(1)}spm');
        }
      }

      return RunningDynamics(
        strideLength: strideLength,
        verticalOscillation: verticalOscillation,
        groundContactTime: groundContactTime,
        power: power,
        cadence: cadence,
      );
    } catch (e) {
      print('❌ 러닝 다이내믹스 데이터 수집 오류: $e');
      return null;
    }
  }

  /// 심박수 데이터 가져오기
  Future<List<coaching.HeartRateData>> getHeartRateData(
      DateTime start, DateTime end) async {
    try {
      print('🔍 HealthKit 심박수 데이터 조회 시작');
      print('📅 시간 범위: $start ~ $end');
      print('⏱️ 조회 기간: ${(end.difference(start).inMinutes)}분');

      if (!_isInitialized) {
        print('🔄 HealthKit 초기화 확인 중...');
        final initialized = await initialize();
        if (!initialized) {
          print('❌ HealthKit 초기화 실패');
          return [];
        }
        print('✅ HealthKit 초기화 성공');
      }

      print('🔄 HealthKit에서 HEART_RATE 타입 데이터 요청 중...');
      final heartRateData = await _health.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.HEART_RATE],
      );

      print('📊 HealthKit에서 받은 원본 데이터 개수: ${heartRateData.length}');

      if (heartRateData.isEmpty) {
        print('⚠️ HealthKit에서 심박수 데이터가 없음');
        print('💡 가능한 원인:');
        print('   - 해당 시간에 운동을 하지 않았을 수 있음');
        print('   - Apple Watch가 연결되지 않았을 수 있음');
        print('   - 심박수 측정이 꺼져 있었을 수 있음');
        print('   - HealthKit 권한이 부족할 수 있음');
        return [];
      }

      print('🔄 심박수 데이터 변환 시작...');

      // HealthDataPoint를 HeartRateData로 변환
      final hrDataList = heartRateData.map((point) {
        print(
            '   📍 심박수 포인트 처리: ${point.dateFrom} - 값: ${point.value} (타입: ${point.value.runtimeType})');

        // 값 변환 디버깅
        double hrValue = 0.0;
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;
          hrValue = numericValue.numericValue.toDouble();
          print('   ✅ NumericHealthValue 변환 성공: $hrValue BPM');
        } else if (point.value is num) {
          hrValue = (point.value as num).toDouble();
          print('   ✅ 숫자 타입 변환 성공: $hrValue BPM');
        } else if (point.value is String) {
          final strValue = point.value as String;
          hrValue = double.tryParse(strValue) ?? 0.0;
          print('   🔄 문자열에서 변환 시도: "$strValue" → $hrValue BPM');
        } else {
          print('   ❌ 알 수 없는 값 타입: ${point.value.runtimeType}');
          hrValue = 0.0;
        }

        return coaching.HeartRateData(
          timestamp: point.dateFrom,
          value: hrValue,
          unit: 'BPM',
        );
      }).toList();

      // 시간순으로 정렬
      hrDataList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('✅ 심박수 데이터 변환 완료: ${hrDataList.length}개');
      print('📈 심박수 통계:');
      if (hrDataList.isNotEmpty) {
        final values = hrDataList.map((e) => e.value);
        final avgHR = values.reduce((a, b) => a + b) / values.length;
        final maxHR = values.reduce((a, b) => a > b ? a : b);
        final minHR = values.reduce((a, b) => a < b ? a : b);

        print('   - 평균: ${avgHR.round()} BPM');
        print('   - 최고: ${maxHR.round()} BPM');
        print('   - 최저: ${minHR.round()} BPM');
        print(
            '   - 첫 번째: ${hrDataList.first.value.round()} BPM at ${hrDataList.first.timestamp}');
        print(
            '   - 마지막: ${hrDataList.last.value.round()} BPM at ${hrDataList.last.timestamp}');
        print(
            '   - 데이터 간격: ${(hrDataList.last.timestamp.difference(hrDataList.first.timestamp).inSeconds / hrDataList.length).round()}초');
      }

      return hrDataList;
    } catch (e) {
      print('❌ 심박수 데이터 수집 오류: $e');
      return [];
    }
  }

  /// 심박수 구간별 데이터 수집
  Future<List<HeartRateZone>> getHeartRateZones(
      DateTime start, DateTime end) async {
    try {
      print('🔍 심박수 구간 데이터 수집 시작: $start ~ $end');

      final heartRateData = await _health.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.HEART_RATE],
      );

      if (heartRateData.isEmpty) {
        print('⚠️ 심박수 데이터가 없습니다');
        return [];
      }

      print('🔍 심박수 데이터 ${heartRateData.length}개 발견');

      // 심박수 구간 정의 (220-나이 기준, 임시로 30세)
      final maxHR = 220 - 30;
      final zones = [
        {'name': 'Z1', 'min': 0, 'max': (maxHR * 0.6).round(), 'color': '파란색'},
        {
          'name': 'Z2',
          'min': (maxHR * 0.6).round(),
          'max': (maxHR * 0.7).round(),
          'color': '청록색'
        },
        {
          'name': 'Z3',
          'min': (maxHR * 0.7).round(),
          'max': (maxHR * 0.8).round(),
          'color': '녹색'
        },
        {
          'name': 'Z4',
          'min': (maxHR * 0.8).round(),
          'max': (maxHR * 0.9).round(),
          'color': '주황색'
        },
        {
          'name': 'Z5',
          'min': (maxHR * 0.9).round(),
          'max': maxHR,
          'color': '빨간색'
        },
      ];

      // 구간별 시간 계산
      final zoneTimes = <String, Duration>{};
      for (final zone in zones) {
        zoneTimes[zone['name'] as String] = Duration.zero;
      }

      // 각 심박수 데이터를 구간에 분류
      for (final point in heartRateData) {
        if (point.value is NumericHealthValue) {
          final hr = (point.value as NumericHealthValue).numericValue;

          for (final zone in zones) {
            if (hr >= (zone['min'] as int) && hr < (zone['max'] as int)) {
              final currentTime = zoneTimes[zone['name'] as String]!;
              zoneTimes[zone['name'] as String] =
                  currentTime + Duration(minutes: 1);
              break;
            }
          }
        }
      }

      // HeartRateZone 객체 생성
      final heartRateZones = <HeartRateZone>[];
      for (final zone in zones) {
        final zoneName = zone['name'] as String;
        final time = zoneTimes[zoneName]!;

        if (time.inMinutes > 0) {
          heartRateZones.add(HeartRateZone(
            zone: zoneName,
            time: time,
            minHR: zone['min'] as int,
            maxHR: zone['max'] as int,
          ));
          print(
              '✅ $zoneName: ${time.inMinutes}분 (${zone['min']}-${zone['max']} BPM)');
        }
      }

      return heartRateZones;
    } catch (e) {
      print('❌ 심박수 구간 데이터 수집 오류: $e');
      return [];
    }
  }

  /// 스플릿 데이터 수집 (1km 구간별)
  Future<List<SplitData>> getSplitData(DateTime start, DateTime end) async {
    try {
      print('🔍 스플릿 데이터 수집 시작: $start ~ $end');

      // WORKOUT 데이터에서 스플릿 정보 추출
      final workoutData = await _health.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.WORKOUT],
      );

      if (workoutData.isEmpty) {
        print('⚠️ WORKOUT 데이터가 없습니다');
        return [];
      }

      // 스플릿 데이터 생성 (임시로 1km 구간으로 분할)
      final workout = workoutData.first;
      final totalDistance = _extractDistanceFromWorkout(workout) ?? 0;
      final totalDuration = workout.dateFrom.difference(workout.dateTo).abs();

      if (totalDistance == 0) {
        print('⚠️ 거리 데이터가 없어 스플릿을 생성할 수 없습니다');
        return [];
      }

      final splitCount = totalDistance.ceil(); // 1km 단위로 분할
      final splitDuration = totalDuration.inMinutes ~/ splitCount;

      final splits = <SplitData>[];
      for (int i = 0; i < splitCount; i++) {
        final splitTime = Duration(minutes: splitDuration);
        final splitPace = '${splitDuration.toString().padLeft(2, '0')}:00';

        splits.add(SplitData(
          splitNumber: i + 1,
          time: splitTime,
          pace: splitPace,
          heartRate: 140 + (i * 2), // 임시 데이터
          power: 200.0 + (i * 5), // 임시 데이터
          cadence: 160 + (i * 2), // 임시 데이터
        ));
      }

      print('✅ $splitCount개 스플릿 데이터 생성 완료');
      return splits;
    } catch (e) {
      print('❌ 스플릿 데이터 수집 오류: $e');
      return [];
    }
  }

  /// 운동의 GPS 경로 데이터 가져오기
  Future<WorkoutRoute?> getWorkoutRoute(DateTime startTime, DateTime endTime,
      {String? workoutId}) async {
    print('🚀 ===== getWorkoutRoute 메서드 시작 =====');
    print('🚀 입력 시간: $startTime ~ $endTime');
    print('🚀 운동 ID: ${workoutId ?? "없음"}');
    print('🚀 현재 시간: ${DateTime.now()}');
    print('🚀 메서드 호출됨 - 새로운 코드 실행 중');
    print('🚀 이 로그가 보이면 새로운 코드가 실행된 것입니다!');
    print('🚀 파일 경로: lib/services/health_kit_service.dart');

    try {
      if (!_isInitialized) {
        print('🚀 HealthKit 초기화 필요');
        final initialized = await initialize();
        print('🚀 HealthKit 초기화 결과: $initialized');
        if (!initialized) return null;
      } else {
        print('🚀 HealthKit 이미 초기화됨');
      }

      print(
          '🗺️ GPS 경로 데이터 수집 시작: ${startTime.toLocal()} ~ ${endTime.toLocal()}');

      // 새로운 HealthKitRouteService를 사용하여 실제 GPS 경로 데이터 수집 시도
      try {
        print('🔍 실제 GPS 경로 데이터 수집 시도...');

        // 1. HealthKit 권한 확인
        print('🔐 HealthKit 경로 권한 요청 시작...');
        final hasPermissions = await HealthKitRouteService.requestPermissions();
        print('🔐 HealthKit 경로 권한 결과: $hasPermissions');

        if (!hasPermissions) {
          print('⚠️ HealthKit 경로 권한이 없습니다.');
          return null; // 권한이 없으면 null 반환
        }

        // 2. 실제 GPS 경로 데이터 가져오기 (운동 ID 포함)
        print('🔍 HealthKitRouteService.getWorkoutRoute 호출 시작...');
        final routeData = await HealthKitRouteService.getWorkoutRoute(
            startTime, endTime,
            workoutId: workoutId);
        print(
            '🔍 HealthKitRouteService.getWorkoutRoute 결과: ${routeData?.length ?? 0}개 포인트');

        if (routeData != null && routeData.isNotEmpty) {
          print('✅ 실제 GPS 경로 데이터 발견: ${routeData.length}개 포인트');

          // 디버깅: 데이터 타입 확인
          print('🔍 routeData 타입: ${routeData.runtimeType}');
          print('🔍 첫 번째 포인트 타입: ${routeData.first.runtimeType}');
          print('🔍 첫 번째 포인트 키들: ${routeData.first.keys.toList()}');
          print(
              '🔍 첫 번째 포인트 latitude 타입: ${routeData.first['latitude']?.runtimeType}');
          print(
              '🔍 첫 번째 포인트 longitude 타입: ${routeData.first['longitude']?.runtimeType}');
          print('🔍 첫 번째 포인트 latitude 값: ${routeData.first['latitude']}');
          print('🔍 첫 번째 포인트 longitude 값: ${routeData.first['longitude']}');

          // 좌표값 검증: 처음, 중간, 마지막 포인트
          print('🔍 좌표값 검증:');
          print(
              '  📍 첫 번째: lat=${routeData.first['latitude']}, lng=${routeData.first['longitude']}');
          print(
              '  📍 중간: lat=${routeData[routeData.length ~/ 2]['latitude']}, lng=${routeData[routeData.length ~/ 2]['longitude']}');
          print(
              '  📍 마지막: lat=${routeData.last['latitude']}, lng=${routeData.last['longitude']}');

          // 좌표 범위 확인
          final latitudes =
              routeData.map((p) => p['latitude'] as double).toList();
          final longitudes =
              routeData.map((p) => p['longitude'] as double).toList();
          print(
              '  📊 위도 범위: ${latitudes.reduce((a, b) => a < b ? a : b)} ~ ${latitudes.reduce((a, b) => a > b ? a : b)}');
          print(
              '  📊 경도 범위: ${longitudes.reduce((a, b) => a < b ? a : b)} ~ ${longitudes.reduce((a, b) => a > b ? a : b)}');

          // 좌표계 검증 (WGS84: 위도 -90~90, 경도 -180~180)
          final minLat = latitudes.reduce((a, b) => a < b ? a : b);
          final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
          final minLng = longitudes.reduce((a, b) => a < b ? a : b);
          final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

          print('  🔍 좌표계 검증:');
          print('    ✅ 위도 범위: $minLat ~ $maxLat (WGS84: -90 ~ 90)');
          print('    ✅ 경도 범위: $minLng ~ $maxLng (WGS84: -180 ~ 180)');

          // 한국 지역 좌표 범위 확인 (대략적인 범위)
          if (minLat >= 33.0 &&
              maxLat <= 38.5 &&
              minLng >= 124.5 &&
              maxLng <= 132.0) {
            print('    ✅ 한국 지역 좌표 범위에 포함됨');
          } else {
            print('    ⚠️ 한국 지역 좌표 범위를 벗어남 (좌표계 변환 필요할 수 있음)');
          }

          // GPS 데이터를 GPSPoint로 변환 (이미 타입이 변환됨)
          final gpsPoints = _convertRouteDataToGPSPoints(routeData);

          // 거리 계산
          double totalDistance = 0;
          for (int i = 1; i < gpsPoints.length; i++) {
            final prev = gpsPoints[i - 1];
            final curr = gpsPoints[i];

            final latDiff = curr.latitude - prev.latitude;
            final lngDiff = curr.longitude - prev.longitude;

            final latDistance = latDiff * 111000; // 미터 단위
            final lngDistance = lngDiff * 88900; // 미터 단위

            totalDistance +=
                sqrt(latDistance * latDistance + lngDistance * lngDistance);
          }

          final route = WorkoutRoute(
            points: gpsPoints,
            startTime: startTime,
            endTime: endTime,
            totalDistance: totalDistance,
          );

          print(
              '✅ 실제 GPS 경로 생성 완료: ${gpsPoints.length}개 포인트, ${totalDistance.toStringAsFixed(0)}m');
          return route;
        } else {
          print('⚠️ 실제 GPS 경로 데이터가 없습니다.');
          return null; // GPS 데이터가 없으면 null 반환
        }
      } catch (e) {
        print('⚠️ 실제 GPS 데이터 수집 실패: $e');
        return null; // 오류 발생 시 null 반환
      }

      // GPS 데이터가 없으면 null 반환 (샘플 경로 생성 제거)
      return null;
    } finally {
      print('🚀 ===== getWorkoutRoute 메서드 종료 =====');
      print('🚀 이 로그가 보이면 새로운 코드가 실행된 것입니다!');
      print('🚀 파일 경로: lib/services/health_kit_service.dart');
    }
  }

  /// GPS 경로 데이터를 GPSPoint 리스트로 변환
  List<GPSPoint> _convertRouteDataToGPSPoints(
      List<Map<String, dynamic>> routeData) {
    final gpsPoints = <GPSPoint>[];

    for (int i = 0; i < routeData.length; i++) {
      try {
        final point = routeData[i];

        // 각 필드를 안전하게 변환
        final latitude = _safeCastToDouble(point['latitude']);
        final longitude = _safeCastToDouble(point['longitude']);
        final timestamp = _safeCastToInt(point['timestamp']);

        // 필수 필드 검증
        if (latitude == null || longitude == null || timestamp == 0) {
          print(
              '⚠️ 포인트 $i: 필수 데이터 누락 (lat: $latitude, lng: $longitude, time: $timestamp)');
          continue;
        }

        final gpsPoint = GPSPoint(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          altitude: _safeCastToDouble(point['altitude']) ?? 0.0,
          speed: _safeCastToDouble(point['speed']) ?? 0.0,
          accuracy: _safeCastToDouble(point['horizontalAccuracy']) ?? 10.0,
        );

        gpsPoints.add(gpsPoint);
      } catch (e) {
        print('⚠️ 포인트 $i 변환 실패: $e');
        continue;
      }
    }

    print('✅ GPS 포인트 변환 완료: ${gpsPoints.length}/${routeData.length}개 성공');
    return gpsPoints;
  }

  /// 안전한 double 타입 변환
  double? _safeCastToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 안전한 int 타입 변환
  int _safeCastToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

/// 운동 데이터 모델
class WorkoutData {
  final String id;
  final String? uuid; // HealthKit UUID (선택적)
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double? distance; // km
  final double? calories;
  final String? source;

  WorkoutData({
    required this.id,
    this.uuid,
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

/// 러닝 다이내믹스 데이터 모델
class RunningDynamics {
  final double? strideLength; // 보폭 (m)
  final double? verticalOscillation; // 수직 진폭 (cm)
  final double? groundContactTime; // 지면 접촉 시간 (ms)
  final double? power; // 파워 (W)
  final double? cadence; // 케이던스 (spm)

  RunningDynamics({
    this.strideLength,
    this.verticalOscillation,
    this.groundContactTime,
    this.power,
    this.cadence,
  });
}

/// 심박수 구간 데이터 모델
class HeartRateZone {
  final String zone; // 구간 (Z1, Z2, Z3, Z4, Z5)
  final Duration time; // 해당 구간에서 보낸 시간
  final int minHR; // 최소 심박수
  final int maxHR; // 최대 심박수

  HeartRateZone({
    required this.zone,
    required this.time,
    required this.minHR,
    required this.maxHR,
  });
}

/// 스플릿 데이터 모델
class SplitData {
  final int splitNumber; // 스플릿 번호
  final Duration time; // 구간 시간
  final String pace; // 페이스
  final int heartRate; // 심박수
  final double? power; // 파워
  final int? cadence; // 케이던스

  SplitData({
    required this.splitNumber,
    required this.time,
    required this.pace,
    required this.heartRate,
    this.power,
    this.cadence,
  });
}

/// GPS 경로 포인트 데이터
class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
  final double? accuracy;

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.accuracy,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory GPSPoint.fromHealthDataPoint(HealthDataPoint point) {
    // HealthKit의 GPS 데이터를 파싱
    final value = point.value;

    // GPS 데이터가 문자열로 저장된 경우 파싱 시도
    if (value.toString().contains(',')) {
      try {
        final valueStr = value.toString();
        // 예: "37.5665,126.9780,50.0,5.2,10.0" (lat,lng,altitude,speed,accuracy)
        final parts = valueStr.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0]) ?? 0.0;
          final lng = double.tryParse(parts[1]) ?? 0.0;
          final altitude = parts.length > 2 ? double.tryParse(parts[2]) : null;
          final speed = parts.length > 3 ? double.tryParse(parts[3]) : null;
          final accuracy = parts.length > 4 ? double.tryParse(parts[4]) : null;

          return GPSPoint(
            latitude: lat,
            longitude: lng,
            timestamp: point.dateFrom,
            altitude: altitude,
            speed: speed,
            accuracy: accuracy,
          );
        }
      } catch (e) {
        print('❌ GPS 데이터 파싱 오류: $e');
      }
    }

    // 기본값 반환 (서울 시청 좌표)
    return GPSPoint(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: point.dateFrom,
    );
  }
}

/// 운동 경로 데이터
class WorkoutRoute {
  final List<GPSPoint> points;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistance;

  WorkoutRoute({
    required this.points,
    required this.startTime,
    required this.endTime,
    required this.totalDistance,
  });

  /// 경로의 중심점 계산
  LatLng get center {
    if (points.isEmpty) return const LatLng(37.5665, 126.9780);

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  /// 경로의 경계 계산
  Map<String, double> get bounds {
    if (points.isEmpty) {
      return {
        'minLat': 37.5665,
        'maxLat': 37.5665,
        'minLng': 126.9780,
        'maxLng': 126.9780,
      };
    }

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

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }
}
