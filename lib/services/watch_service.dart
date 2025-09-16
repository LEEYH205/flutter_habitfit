import 'health_kit_service.dart';

/// Apple Watch 연동을 위한 서비스 클래스
class WatchService {
  static final WatchService _instance = WatchService._internal();
  factory WatchService() => _instance;
  WatchService._internal();

  final HealthKitService _healthKitService = HealthKitService();
  bool _isConnected = false;
  bool _isWorkoutActive = false;
  DateTime? _workoutStartTime;
  String? _currentWorkoutType;

  /// 워치 연결 상태
  bool get isConnected => _isConnected;

  /// 현재 운동 중인지 여부
  bool get isWorkoutActive => _isWorkoutActive;

  /// 워치 초기화 및 연결 확인
  Future<bool> initialize() async {
    try {
      print('⌚ WatchService 초기화 시작');

      // HealthKit 초기화
      final healthKitInitialized = await _healthKitService.initialize();
      if (!healthKitInitialized) {
        print('❌ HealthKit 초기화 실패');
        return false;
      }

      // 워치 연결 상태 확인
      _isConnected = await _healthKitService.checkWatchConnection();

      if (_isConnected) {
        print('✅ Apple Watch 연결됨');
        return true;
      } else {
        print('❌ Apple Watch 연결되지 않음');
        return false;
      }
    } catch (e) {
      print('❌ WatchService 초기화 오류: $e');
      return false;
    }
  }

  /// 운동 시작 (워치에 알림 전송)
  Future<bool> startWorkout({
    required String workoutType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🏃‍♂️ 워치로 운동 시작: $workoutType');

      if (!_isConnected) {
        print('❌ 워치가 연결되지 않음');
        return false;
      }

      _workoutStartTime = DateTime.now();
      _currentWorkoutType = workoutType;
      _isWorkoutActive = true;

      // 워치에 운동 시작 알림 전송
      final success =
          await _healthKitService.sendWorkoutStartNotificationToWatch(
        workoutType: workoutType,
        startTime: _workoutStartTime!,
      );

      if (success) {
        print('✅ 워치에 운동 시작 알림 전송 성공');
        return true;
      } else {
        print('❌ 워치에 운동 시작 알림 전송 실패');
        _isWorkoutActive = false;
        _workoutStartTime = null;
        _currentWorkoutType = null;
        return false;
      }
    } catch (e) {
      print('❌ 워치 운동 시작 오류: $e');
      _isWorkoutActive = false;
      _workoutStartTime = null;
      _currentWorkoutType = null;
      return false;
    }
  }

  /// 운동 종료 (워치에 데이터 저장)
  Future<bool> endWorkout({
    double? distance,
    double? calories,
    int? averageHeartRate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🏁 워치로 운동 종료');

      if (!_isWorkoutActive ||
          _workoutStartTime == null ||
          _currentWorkoutType == null) {
        print('❌ 활성화된 운동이 없음');
        return false;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(_workoutStartTime!);

      // 워치에 운동 데이터 저장
      final success = await _healthKitService.writeWorkoutToHealthKit(
        workoutType: _currentWorkoutType!,
        startTime: _workoutStartTime!,
        endTime: endTime,
        distance: distance,
        calories: calories,
        heartRate: averageHeartRate,
        metadata: metadata,
      );

      if (success) {
        // 워치에 운동 종료 알림 전송
        await _healthKitService.sendWorkoutEndNotificationToWatch(
          workoutType: _currentWorkoutType!,
          endTime: endTime,
          duration: duration,
          distance: distance,
          calories: calories,
        );

        print('✅ 워치에 운동 종료 데이터 저장 성공');
        print('📊 운동 요약:');
        print('   - 타입: $_currentWorkoutType');
        print('   - 시간: ${duration.inMinutes}분');
        print('   - 거리: ${distance?.toStringAsFixed(2) ?? 'N/A'}km');
        print('   - 칼로리: ${calories?.toStringAsFixed(0) ?? 'N/A'}kcal');
        print('   - 평균 심박수: ${averageHeartRate ?? 'N/A'}BPM');
      } else {
        print('❌ 워치에 운동 종료 데이터 저장 실패');
      }

      // 상태 초기화
      _isWorkoutActive = false;
      _workoutStartTime = null;
      _currentWorkoutType = null;

      return success;
    } catch (e) {
      print('❌ 워치 운동 종료 오류: $e');
      _isWorkoutActive = false;
      _workoutStartTime = null;
      _currentWorkoutType = null;
      return false;
    }
  }

  /// 실시간 심박수 데이터를 워치에 전송
  Future<bool> sendHeartRateToWatch(int heartRate) async {
    try {
      if (!_isConnected) {
        print('❌ 워치가 연결되지 않음');
        return false;
      }

      final success = await _healthKitService.writeHeartRateToWatch(heartRate);

      if (success) {
        print('💓 워치에 심박수 전송 성공: ${heartRate}BPM');
      } else {
        print('❌ 워치에 심박수 전송 실패');
      }

      return success;
    } catch (e) {
      print('❌ 워치 심박수 전송 오류: $e');
      return false;
    }
  }

  /// 걸음 수 데이터를 워치에 전송
  Future<bool> sendStepsToWatch(int steps) async {
    try {
      if (!_isConnected) {
        print('❌ 워치가 연결되지 않음');
        return false;
      }

      final success =
          await _healthKitService.writeStepsToWatch(steps, DateTime.now());

      if (success) {
        print('👟 워치에 걸음 수 전송 성공: $steps걸음');
      } else {
        print('❌ 워치에 걸음 수 전송 실패');
      }

      return success;
    } catch (e) {
      print('❌ 워치 걸음 수 전송 오류: $e');
      return false;
    }
  }

  /// 칼로리 데이터를 워치에 전송
  Future<bool> sendCaloriesToWatch(double calories) async {
    try {
      if (!_isConnected) {
        print('❌ 워치가 연결되지 않음');
        return false;
      }

      final success = await _healthKitService.writeCaloriesToWatch(
          calories, DateTime.now());

      if (success) {
        print('🔥 워치에 칼로리 전송 성공: ${calories.toStringAsFixed(0)}kcal');
      } else {
        print('❌ 워치에 칼로리 전송 실패');
      }

      return success;
    } catch (e) {
      print('❌ 워치 칼로리 전송 오류: $e');
      return false;
    }
  }

  /// 워치 연결 상태 재확인
  Future<bool> checkConnection() async {
    try {
      _isConnected = await _healthKitService.checkWatchConnection();
      print('⌚ 워치 연결 상태: ${_isConnected ? '연결됨' : '연결되지 않음'}');
      return _isConnected;
    } catch (e) {
      print('❌ 워치 연결 상태 확인 오류: $e');
      _isConnected = false;
      return false;
    }
  }

  /// 현재 운동 정보 가져오기
  Map<String, dynamic>? getCurrentWorkoutInfo() {
    if (!_isWorkoutActive ||
        _workoutStartTime == null ||
        _currentWorkoutType == null) {
      return null;
    }

    final now = DateTime.now();
    final duration = now.difference(_workoutStartTime!);

    return {
      'workoutType': _currentWorkoutType,
      'startTime': _workoutStartTime,
      'duration': duration,
      'isActive': _isWorkoutActive,
    };
  }

  /// 운동 일시정지 (워치에 알림)
  Future<bool> pauseWorkout() async {
    try {
      if (!_isWorkoutActive) {
        print('❌ 활성화된 운동이 없음');
        return false;
      }

      print('⏸️ 워치로 운동 일시정지');

      // HealthKit에 일시정지 이벤트 저장
      final success = await _healthKitService.sendWorkoutEndNotificationToWatch(
        workoutType: _currentWorkoutType ?? 'Unknown',
        endTime: DateTime.now(),
        duration: Duration.zero,
        distance: 0.0,
        calories: 0.0,
      );

      if (success) {
        print('✅ 워치에 운동 일시정지 알림 전송 성공');
      } else {
        print('❌ 워치에 운동 일시정지 알림 전송 실패');
      }

      return success;
    } catch (e) {
      print('❌ 워치 운동 일시정지 오류: $e');
      return false;
    }
  }

  /// 운동 재개 (워치에 알림)
  Future<bool> resumeWorkout() async {
    try {
      if (!_isWorkoutActive) {
        print('❌ 활성화된 운동이 없음');
        return false;
      }

      print('▶️ 워치로 운동 재개');

      // HealthKit에 재개 이벤트 저장
      final success =
          await _healthKitService.sendWorkoutStartNotificationToWatch(
        workoutType: _currentWorkoutType ?? 'Unknown',
        startTime: DateTime.now(),
      );

      if (success) {
        print('✅ 워치에 운동 재개 알림 전송 성공');
      } else {
        print('❌ 워치에 운동 재개 알림 전송 실패');
      }

      return success;
    } catch (e) {
      print('❌ 워치 운동 재개 오류: $e');
      return false;
    }
  }

  /// 워치 상태 정보 가져오기
  Map<String, dynamic> getWatchStatus() {
    return {
      'isConnected': _isConnected,
      'isWorkoutActive': _isWorkoutActive,
      'currentWorkoutType': _currentWorkoutType,
      'workoutStartTime': _workoutStartTime,
      'hasAppleWatch': _healthKitService.hasAppleWatch,
    };
  }
}
