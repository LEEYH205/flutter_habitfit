import 'dart:async';
import 'package:flutter/services.dart';

/// Apple Watch와의 통신을 위한 서비스
class WatchConnectivityService {
  static final WatchConnectivityService _instance =
      WatchConnectivityService._internal();
  factory WatchConnectivityService() => _instance;
  WatchConnectivityService._internal();

  static const MethodChannel _channel = MethodChannel('watch_connectivity');

  // Stream controllers for watch events
  final StreamController<Map<String, dynamic>> _workoutStartController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _workoutEndController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _workoutPauseController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _workoutResumeController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _heartRateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _stepsController =
      StreamController.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get workoutStartStream =>
      _workoutStartController.stream;
  Stream<Map<String, dynamic>> get workoutEndStream =>
      _workoutEndController.stream;
  Stream<Map<String, dynamic>> get workoutPauseStream =>
      _workoutPauseController.stream;
  Stream<Map<String, dynamic>> get workoutResumeStream =>
      _workoutResumeController.stream;
  Stream<Map<String, dynamic>> get heartRateStream =>
      _heartRateController.stream;
  Stream<Map<String, dynamic>> get stepsStream => _stepsController.stream;

  bool _isInitialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');
      _isInitialized = true;
      print('✅ Watch Connectivity Service 초기화 완료');
    } catch (e) {
      print('❌ Watch Connectivity Service 초기화 실패: $e');
    }
  }

  /// 네이티브 메서드 호출 처리
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWorkoutStarted':
        _workoutStartController.add(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onWorkoutEnded':
        _workoutEndController.add(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onWorkoutPaused':
        _workoutPauseController.add(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onWorkoutResumed':
        _workoutResumeController.add(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onHeartRateUpdated':
        _heartRateController.add(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onStepsUpdated':
        _stepsController.add(Map<String, dynamic>.from(call.arguments));
        break;
      default:
        print('⚠️ 알 수 없는 메서드 호출: ${call.method}');
    }
  }

  /// Watch 연결 상태 확인
  Future<bool> isWatchConnected() async {
    try {
      final result = await _channel.invokeMethod('isWatchConnected');
      return result as bool;
    } catch (e) {
      print('❌ Watch 연결 상태 확인 실패: $e');
      return false;
    }
  }

  /// Watch 연결 상태 문자열 반환
  Future<String> getWatchConnectionState() async {
    try {
      final result = await _channel.invokeMethod('getWatchConnectionState');
      return result as String;
    } catch (e) {
      print('❌ Watch 연결 상태 문자열 가져오기 실패: $e');
      return '알 수 없음';
    }
  }

  /// Watch로 운동 데이터 전송
  Future<bool> sendWorkoutDataToWatch({
    required String workoutType,
    required DateTime startTime,
    required DateTime endTime,
    required double calories,
    required double distance,
    required double heartRate,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendWorkoutDataToWatch', {
        'workoutType': workoutType,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'calories': calories,
        'distance': distance,
        'heartRate': heartRate,
      });
      return result as bool;
    } catch (e) {
      print('❌ Watch로 운동 데이터 전송 실패: $e');
      return false;
    }
  }

  /// Watch로 실시간 데이터 전송
  Future<bool> sendRealTimeDataToWatch({
    required double heartRate,
    required int steps,
    required double calories,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendRealTimeDataToWatch', {
        'heartRate': heartRate,
        'steps': steps,
        'calories': calories,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return result as bool;
    } catch (e) {
      print('❌ Watch로 실시간 데이터 전송 실패: $e');
      return false;
    }
  }

  /// Watch로 운동 시작 알림 전송
  Future<bool> sendWorkoutStartToWatch(String workoutType) async {
    try {
      final result = await _channel.invokeMethod('sendWorkoutStartToWatch', {
        'workoutType': workoutType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return result as bool;
    } catch (e) {
      print('❌ Watch로 운동 시작 알림 전송 실패: $e');
      return false;
    }
  }

  /// Watch로 운동 종료 알림 전송
  Future<bool> sendWorkoutEndToWatch({
    required String workoutType,
    required Duration duration,
    required double calories,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendWorkoutEndToWatch', {
        'workoutType': workoutType,
        'duration': duration.inSeconds,
        'calories': calories,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return result as bool;
    } catch (e) {
      print('❌ Watch로 운동 종료 알림 전송 실패: $e');
      return false;
    }
  }

  /// Watch로 운동 일시정지 알림 전송
  Future<bool> sendWorkoutPauseToWatch() async {
    try {
      final result = await _channel.invokeMethod('sendWorkoutPauseToWatch', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return result as bool;
    } catch (e) {
      print('❌ Watch로 운동 일시정지 알림 전송 실패: $e');
      return false;
    }
  }

  /// Watch로 운동 재개 알림 전송
  Future<bool> sendWorkoutResumeToWatch() async {
    try {
      final result = await _channel.invokeMethod('sendWorkoutResumeToWatch', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return result as bool;
    } catch (e) {
      print('❌ Watch로 운동 재개 알림 전송 실패: $e');
      return false;
    }
  }

  /// 리소스 정리
  void dispose() {
    _workoutStartController.close();
    _workoutEndController.close();
    _workoutPauseController.close();
    _workoutResumeController.close();
    _heartRateController.close();
    _stepsController.close();
  }
}
