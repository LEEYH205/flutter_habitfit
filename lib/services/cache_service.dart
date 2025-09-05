import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/today_summary.dart';

/// 캐시 서비스 - 데이터 캐싱 및 관리
class CacheService {
  static const String _cachePrefix = 'habitfit_cache_';
  static const Duration _defaultExpiry = Duration(hours: 1);

  /// 데이터 캐시 저장
  static Future<void> setCache(String key, dynamic data,
      {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // TodaySummary 객체인 경우 JSON으로 변환
      dynamic serializedData = data;
      if (data.runtimeType.toString().contains('TodaySummary')) {
        serializedData = data.toJson();
      }

      final cacheData = {
        'data': serializedData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': (expiry ?? _defaultExpiry).inMilliseconds,
        'type': data.runtimeType.toString(),
      };

      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      print('❌ 캐시 저장 실패: $e');
    }
  }

  /// 데이터 캐시 조회
  static Future<T?> getCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_cachePrefix$key');

      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiry = cacheData['expiry'] as int;

      // 만료 시간 확인
      if (DateTime.now().millisecondsSinceEpoch - timestamp > expiry) {
        await removeCache(key);
        return null;
      }

      final data = cacheData['data'];
      final type = cacheData['type'] as String?;

      // TodaySummary 객체인 경우 JSON에서 객체로 변환
      if (type != null &&
          type.contains('TodaySummary') &&
          data is Map<String, dynamic>) {
        return TodaySummary.fromJson(data) as T?;
      }

      return data as T?;
    } catch (e) {
      print('❌ 캐시 조회 실패: $e');
      return null;
    }
  }

  /// 캐시 삭제
  static Future<void> removeCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
    } catch (e) {
      print('❌ 캐시 삭제 실패: $e');
    }
  }

  /// 모든 캐시 삭제
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('❌ 전체 캐시 삭제 실패: $e');
    }
  }

  /// 캐시 키 생성
  static String generateKey(String baseKey, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return baseKey;

    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    return '$baseKey:${jsonEncode(sortedParams)}';
  }

  /// 캐시 상태 확인
  static Future<bool> hasValidCache(String key) async {
    final cache = await getCache(key);
    return cache != null;
  }

  /// 캐시 크기 확인
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      return keys.length;
    } catch (e) {
      return 0;
    }
  }
}

/// 캐시 키 상수
class CacheKeys {
  // Today 페이지 관련
  static const String todaySummary = 'today_summary';
  static const String todayHabits = 'today_habits';
  static const String todayWorkouts = 'today_workouts';
  static const String todayMeals = 'today_meals';
  static const String todaySteps = 'today_steps';

  // Journal 페이지 관련
  static const String dayLog = 'day_log';
  static const String dayHabits = 'day_habits';
  static const String dayWorkouts = 'day_workouts';
  static const String dayMeals = 'day_meals';

  // Insights 페이지 관련
  static const String trendData = 'trend_data';
  static const String weeklyTrend = 'weekly_trend';
  static const String monthlyTrend = 'monthly_trend';
  static const String habitAnalytics = 'habit_analytics';

  // 사용자 관련
  static const String userProfile = 'user_profile';
  static const String userSettings = 'user_settings';
  static const String userHabits = 'user_habits';

  // HealthKit 관련
  static const String healthData = 'health_data';
  static const String stepCount = 'step_count';
  static const String heartRate = 'heart_rate';
}

/// 캐시 만료 시간 상수
class CacheExpiry {
  static const Duration short = Duration(minutes: 5); // 5분
  static const Duration medium = Duration(minutes: 30); // 30분
  static const Duration long = Duration(hours: 1); // 1시간
  static const Duration veryLong = Duration(hours: 6); // 6시간
  static const Duration daily = Duration(days: 1); // 1일
}
