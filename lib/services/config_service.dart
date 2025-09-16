import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// 앱 설정 관리 서비스
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

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
    } catch (e) {
      print('⚠️ ConfigService 초기화 실패: $e');
    }
  }
}
