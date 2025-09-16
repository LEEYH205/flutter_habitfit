import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 앱 설정 관리 서비스
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  // 캐시된 설정 값들
  Map<String, dynamic>? _cachedConfig;
  DateTime? _lastFetch;
  String? _cachedVersion; // 캐시된 설정의 버전
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Discord 웹훅 URL 가져오기
  static String getDiscordWebhookUrl() {
    try {
      // Firebase Remote Config에서 가져오기
      final webhookUrl = _remoteConfig.getString('discord_webhook_url');
      if (webhookUrl.isNotEmpty) {
        print('✅ Firebase에서 웹훅 URL 가져오기 성공');
        return webhookUrl;
      }

      // 개발 환경에서 Firebase에서 가져오지 못한 경우 임시 웹훅 URL 사용
      if (kDebugMode) {
        print('⚠️ 개발 환경: Firebase Remote Config에서 웹훅 URL을 가져올 수 없음');
        print('💡 Firebase 콘솔에서 discord_webhook_url 파라미터를 설정해주세요');
        print('🔧 임시로 개발용 웹훅 URL을 사용합니다');
        return 'https://discord.com/api/webhooks/1417307825020993566/kM49f32GkLktopMr4dzbHv4q6b17UhxnCgUyavAMRPWSNjqw2BV010w0Js7v4IWqoYGD';
      }

      // 폴백: 빈 문자열 반환 (웹훅 비활성화)
      return '';
    } catch (e) {
      print('⚠️ 웹훅 URL 가져오기 실패: $e');
      return '';
    }
  }

  /// 웹훅 URL 유효성 검사
  static bool isWebhookConfigured() {
    final webhookUrl = getDiscordWebhookUrl();
    return webhookUrl.contains('discord.com/api/webhooks') &&
        webhookUrl.isNotEmpty;
  }

  /// 설정 값 가져오기 (Firebase Remote Config에서, 버전 기반 캐시)
  Future<Map<String, dynamic>> getConfig() async {
    try {
      // 현재 Remote Config의 버전 정보 가져오기
      final configVersion = _remoteConfig.getString('config_version');

      // 캐시가 유효하고 버전이 같은 경우 캐시된 값 반환
      if (_cachedConfig != null &&
          _lastFetch != null &&
          _cachedVersion == configVersion &&
          DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
        print('✅ 캐시된 설정 사용 (버전: $_cachedVersion)');
        return _cachedConfig!;
      }

      // Firebase Remote Config에서 사용자 레벨 포인트 설정 가져오기
      final userLevelPointSettingsJson =
          _remoteConfig.getString('userlevelpoint_settings');

      if (userLevelPointSettingsJson.isNotEmpty) {
        final userLevelPointSettings =
            json.decode(userLevelPointSettingsJson) as Map<String, dynamic>;

        // 캐시 업데이트
        _cachedConfig = userLevelPointSettings;
        _cachedVersion = configVersion;
        _lastFetch = DateTime.now();

        print('✅ Remote Config에서 사용자 레벨 포인트 설정 로드 성공 (버전: $configVersion)');
        return _cachedConfig!;
      } else {
        // Remote Config에 설정이 없으면 기본 설정 사용
        print('⚠️ Remote Config에 userlevelpoint_settings가 없음, 기본 설정 사용');
        _cachedConfig = _getDefaultConfig();
        _cachedVersion = 'default';
        _lastFetch = DateTime.now();
        return _cachedConfig!;
      }
    } catch (e) {
      print('❌ Remote Config 설정 조회 오류: $e');
      // 오류 시 기본 설정 반환
      return _getDefaultConfig();
    }
  }

  /// 기본 설정 값들
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'points': {
        'habitCompleted': 10,
        'workoutCompleted': 20,
        'streakAchieved': 15,
        'goalAchieved': 50,
        'dailyChallenge': 30,
        'weeklyChallenge': 100,
        'monthlyChallenge': 200,
        'socialShare': 5,
        'reviewWritten': 25,
        'friendInvited': 100,
        'achievementUnlocked': 75,
        'streakBonus': 5, // 연속일수당 보너스
        'firstTimeBonus': 20, // 첫 완료 보너스
        'levelUpBonus': 100, // 레벨업당 보너스
      },
      'levels': {
        'basePoints': 100,
        'multiplier': 1.2,
      },
      'achievements': {
        'level_5': {
          'points': 50,
          'title': '첫 번째 레벨업',
          'description': '레벨 5 달성',
          'icon': '🎯'
        },
        'level_10': {
          'points': 100,
          'title': '습관러',
          'description': '레벨 10 달성',
          'icon': '🌿'
        },
        'level_20': {
          'points': 200,
          'title': '달성자',
          'description': '레벨 20 달성',
          'icon': '🌳'
        },
        'level_30': {
          'points': 300,
          'title': '마스터',
          'description': '레벨 30 달성',
          'icon': '🏆'
        },
        'points_1000': {
          'points': 100,
          'title': '첫 1000점',
          'description': '1000 포인트 달성',
          'icon': '💯'
        },
        'points_5000': {
          'points': 200,
          'title': '포인트 마스터',
          'description': '5000 포인트 달성',
          'icon': '💰'
        },
        'points_10000': {
          'points': 500,
          'title': '포인트 레전드',
          'description': '10000 포인트 달성',
          'icon': '💎'
        },
      },
    };
  }

  /// 특정 포인트 타입의 기본 포인트 가져오기
  Future<int> getPointsForType(String type) async {
    final config = await getConfig();
    return config['points']?[type] ?? 0;
  }

  /// 업적 정보 가져오기
  Future<Map<String, dynamic>?> getAchievementConfig(
      String achievementId) async {
    final config = await getConfig();
    return config['achievements']?[achievementId];
  }

  /// 레벨 설정 가져오기
  Future<Map<String, dynamic>> getLevelConfig() async {
    final config = await getConfig();
    return config['levels'] ?? {'basePoints': 100, 'multiplier': 1.2};
  }

  /// 캐시 무효화
  void invalidateCache() {
    _cachedConfig = null;
    _lastFetch = null;
    _cachedVersion = null;
    print('🗑️ ConfigService 캐시 무효화');
  }

  /// 강제로 Remote Config에서 최신 설정 가져오기
  Future<Map<String, dynamic>> forceRefreshConfig() async {
    print('🔄 Remote Config 강제 새로고침 시작...');

    try {
      // Remote Config 강제 새로고침
      await _remoteConfig.fetch();
      await _remoteConfig.activate();

      // 캐시 무효화
      invalidateCache();

      // 새로운 설정 로드
      final newConfig = await getConfig();
      print('✅ Remote Config 강제 새로고침 완료');
      return newConfig;
    } catch (e) {
      print('❌ Remote Config 강제 새로고침 실패: $e');
      return _getDefaultConfig();
    }
  }

  /// 설정 초기화
  static Future<void> initialize() async {
    try {
      print('🔧 ConfigService 초기화 시작...');

      // 개발 환경에서는 가져오기 간격을 짧게 설정
      if (kDebugMode) {
        await _remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 60),
          minimumFetchInterval: const Duration(seconds: 0), // 개발 중에는 즉시 가져오기
        ));
        print('✅ 개발용 Remote Config 설정 완료 (즉시 가져오기)');
      }

      // 기본값 없이 Remote Config만 사용
      await _remoteConfig.setDefaults({});
      print('✅ Remote Config 기본값 설정 완료');

      // Remote Config 값 가져오기
      print('🔄 Remote Config 데이터 가져오기 시작...');

      // 개발 환경에서는 캐시를 무시하고 강제로 새로고침
      if (kDebugMode) {
        await _remoteConfig.fetch();
        await _remoteConfig.activate();
        print('✅ Remote Config 데이터 강제 새로고침 완료');
      } else {
        await _remoteConfig.fetchAndActivate();
        print('✅ Remote Config 데이터 가져오기 완료');
      }

      // 웹훅 URL 확인
      final webhookUrl = _remoteConfig.getString('discord_webhook_url');
      print(
          '🔍 Firebase에서 가져온 웹훅 URL: ${webhookUrl.isEmpty ? "빈 문자열" : "${webhookUrl.substring(0, 50)}..."}');

      print('✅ ConfigService 초기화 완료');

      final finalWebhookUrl = getDiscordWebhookUrl();
      if (finalWebhookUrl.isNotEmpty) {
        print('🔗 최종 Discord 웹훅 URL: ${finalWebhookUrl.substring(0, 50)}...');
      } else {
        print('⚠️ Discord 웹훅 URL이 설정되지 않음');
        print('💡 Firebase 콘솔에서 discord_webhook_url 파라미터를 설정해주세요');
      }

      // ConfigService 인스턴스 생성 및 초기 설정 로드
      final instance = ConfigService();
      await instance.getConfig();
      print('✅ ConfigService 사용자 레벨 포인트 설정 로드 완료');
    } catch (e) {
      print('⚠️ ConfigService 초기화 실패: $e');
    }
  }
}
