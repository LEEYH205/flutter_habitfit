import 'package:flutter/services.dart';

/// HealthKit에서 실제 GPS 경로를 가져오는 서비스
class HealthKitRouteService {
  static const MethodChannel _channel =
      MethodChannel('healthkit_route_channel');

  /// HealthKit 권한 요청 (권한 상태 확인 후 요청)
  static Future<bool> requestPermissions() async {
    try {
      // 먼저 권한 상태를 확인
      print('🔍 HealthKit 권한 상태 확인 중...');
      final bool statusResult =
          await _channel.invokeMethod('checkHealthKitPermissions');

      if (statusResult) {
        print('✅ HealthKit 권한이 이미 승인되어 있습니다');
        return true;
      }

      print('🔄 HealthKit 권한 요청 시작...');
      final bool result =
          await _channel.invokeMethod('requestHealthKitPermissions');
      print('🔐 HealthKit 권한 요청 결과: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ HealthKit 권한 요청 실패: ${e.message}');
      return false;
    }
  }

  /// 운동 경로(GPS) 권한 요청
  static Future<bool> requestWorkoutRoutePermissions() async {
    try {
      print('🗺️ 운동 경로 권한 요청 시작...');
      final bool result =
          await _channel.invokeMethod('requestWorkoutRoutePermissions');
      print('🗺️ 운동 경로 권한 요청 결과: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ 운동 경로 권한 요청 실패: ${e.message}');
      return false;
    }
  }

  /// 운동의 GPS 경로 데이터 가져오기
  static Future<List<Map<String, dynamic>>?> getWorkoutRoute(
    DateTime startTime,
    DateTime endTime, {
    String? workoutId,
  }) async {
    print('🗺️ HealthKitRouteService: GPS 경로 데이터 조회 시작');
    print('📅 시간 범위: $startTime ~ $endTime');
    print('⏱️ 조회 기간: ${(endTime.difference(startTime).inMinutes)}분');
    print('🎯 운동 ID: ${workoutId ?? "없음 (시간 범위로 검색)"}');

    print('🔍 Flutter → iOS 요청 파라미터:');
    print('   - startDate: ${startTime.millisecondsSinceEpoch} ($startTime)');
    print('   - endDate: ${endTime.millisecondsSinceEpoch} ($endTime)');
    print('   - workoutId: ${workoutId ?? "null"}');

    try {
      print('🔄 iOS 네이티브 메서드 호출 중...');
      final result = await _channel.invokeMethod('getWorkoutRoute', {
        'startDate': startTime.millisecondsSinceEpoch,
        'endDate': endTime.millisecondsSinceEpoch,
        'workoutId': workoutId,
      });

      print('✅ iOS 네이티브 메서드 호출 완료');
      print('📨 iOS 네이티브 응답 타입: ${result.runtimeType}');
      print('📨 iOS 네이티브 응답 내용: $result');

      // 타입 안전하게 변환
      if (result == null) {
        print('🔍 iOS 네이티브 응답이 null입니다');
        return null;
      }

      if (result is List) {
        print('🔍 iOS 네이티브 응답이 List 타입입니다: ${result.length}개 항목');

        // 각 항목을 Map<String, dynamic>으로 안전하게 변환
        final convertedResult = <Map<String, dynamic>>[];

        for (int i = 0; i < result.length; i++) {
          final item = result[i];
          if (item is Map) {
            // Map의 키들을 String으로 변환
            final convertedMap = <String, dynamic>{};
            item.forEach((key, value) {
              if (key is String) {
                convertedMap[key] = value;
              } else {
                convertedMap[key.toString()] = value;
              }
            });
            convertedResult.add(convertedMap);
          } else {
            print('🔍 항목 $i이 Map이 아닙니다: ${item.runtimeType}');
          }
        }

        print('🔍 변환 완료: ${convertedResult.length}개 GPS 포인트');
        return convertedResult;
      } else {
        print('🔍 iOS 네이티브 응답이 List가 아닙니다: ${result.runtimeType}');
        return null;
      }
    } catch (e) {
      print('❌ HealthKitRouteService 오류: $e');
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
