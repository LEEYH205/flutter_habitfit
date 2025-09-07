import 'dart:async';
import 'package:flutter/services.dart';

class WatchConnectivityService {
  static const MethodChannel _channel = MethodChannel('watch_connectivity');

  static final WatchConnectivityService _instance =
      WatchConnectivityService._internal();
  factory WatchConnectivityService() => _instance;
  WatchConnectivityService._internal();

  // Watch 연결 상태 확인
  Future<bool> isWatchPaired() async {
    try {
      final bool result = await _channel.invokeMethod('isWatchPaired');
      return result;
    } catch (e) {
      print('Error checking watch pairing: $e');
      return false;
    }
  }

  // Watch 앱 설치 상태 확인
  Future<bool> isWatchAppInstalled() async {
    try {
      final bool result = await _channel.invokeMethod('isWatchAppInstalled');
      return result;
    } catch (e) {
      print('Error checking watch app installation: $e');
      return false;
    }
  }

  // Watch 연결 가능 상태 확인
  Future<bool> isWatchReachable() async {
    try {
      final bool result = await _channel.invokeMethod('isWatchReachable');
      return result;
    } catch (e) {
      print('Error checking watch reachability: $e');
      return false;
    }
  }

  // Watch로 메시지 전송
  Future<void> sendMessageToWatch(Map<String, dynamic> message) async {
    try {
      await _channel.invokeMethod('sendMessageToWatch', message);
    } catch (e) {
      print('Error sending message to watch: $e');
    }
  }

  // Watch로 메시지 전송 (응답 대기)
  Future<Map<String, dynamic>?> sendMessageToWatchWithReply(
    Map<String, dynamic> message,
    Duration timeout,
  ) async {
    try {
      final result = await _channel.invokeMethod(
        'sendMessageToWatchWithReply',
        {'message': message, 'timeout': timeout.inMilliseconds},
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error sending message to watch with reply: $e');
      return null;
    }
  }

  // Watch에서 오는 메시지 핸들러 설정
  void setMessageHandler(Function(Map<String, dynamic>) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWatchMessage') {
        final Map<String, dynamic> message =
            Map<String, dynamic>.from(call.arguments);
        handler(message);
      }
    });
  }

  // Watch 연결 테스트
  Future<bool> pingWatch() async {
    try {
      final result = await sendMessageToWatchWithReply(
        {'action': 'ping'},
        const Duration(seconds: 5),
      );
      return result != null && result['status'] == 'pong';
    } catch (e) {
      print('Error pinging watch: $e');
      return false;
    }
  }
}
