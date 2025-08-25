import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// HealthKit에서 실제 GPS 경로를 가져오는 서비스
class HealthKitRouteService {
  static const MethodChannel _channel =
      MethodChannel('healthkit_route_channel');

  /// HealthKit 권한 요청
  static Future<bool> requestPermissions() async {
    try {
      final bool result =
          await _channel.invokeMethod('requestHealthKitPermissions');
      return result;
    } on PlatformException catch (e) {
      print('❌ HealthKit 권한 요청 실패: ${e.message}');
      return false;
    }
  }

  /// 특정 운동의 GPS 경로 데이터 가져오기
  static Future<List<Map<String, dynamic>>?> getWorkoutRoute(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod('getWorkoutRoute', {
        'startDate': startTime.millisecondsSinceEpoch,
        'endDate': endTime.millisecondsSinceEpoch,
      });

      if (result != null) {
        // 안전한 타입 변환
        return result.map((item) {
          if (item is Map) {
            final convertedMap = <String, dynamic>{};
            item.forEach((key, value) {
              if (key is String) {
                convertedMap[key] = value;
              } else {
                convertedMap[key.toString()] = value;
              }
            });
            return convertedMap;
          }
          return <String, dynamic>{};
        }).toList();
      }
      return null;
    } on PlatformException catch (e) {
      print('❌ 운동 경로 데이터 가져오기 실패: ${e.message}');
      return null;
    }
  }

  /// 특정 기간의 모든 운동 경로 데이터 가져오기
  static Future<List<Map<String, dynamic>>?> getWorkoutRoutes(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod('getWorkoutRoutes', {
        'startDate': startTime.millisecondsSinceEpoch,
        'endDate': endTime.millisecondsSinceEpoch,
      });

      if (result != null) {
        // 안전한 타입 변환
        return result.map((item) {
          if (item is Map) {
            final convertedMap = <String, dynamic>{};
            item.forEach((key, value) {
              if (key is String) {
                convertedMap[key] = value;
              } else {
                convertedMap[key.toString()] = value;
              }
            });
            return convertedMap;
          }
          return <String, dynamic>{};
        }).toList();
      }
      return null;
    } on PlatformException catch (e) {
      print('❌ 운동 경로 데이터 가져오기 실패: ${e.message}');
      return null;
    }
  }
}
