import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 디스코드 웹훅을 통한 버그 리포트 서비스
class BugReportService {
  static final BugReportService _instance = BugReportService._internal();
  factory BugReportService() => _instance;
  BugReportService._internal();

  // 디스코드 웹훅 URL (실제 사용 시 환경변수로 관리)
  static const String _discordWebhookUrl = 'YOUR_DISCORD_WEBHOOK_URL_HERE';

  /// 버그 리포트 전송
  Future<bool> sendBugReport({
    required String title,
    required String description,
    String? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    String? deviceInfo,
    String? appVersion,
    String? userEmail,
    List<String>? attachments,
  }) async {
    try {
      print('🐛 버그 리포트 전송 시작');

      // 디바이스 정보 수집
      final deviceInfoData = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      // 디스코드 임베드 메시지 생성
      final embed = {
        'title': '🐛 버그 리포트',
        'description': description,
        'color': 0xff0000, // 빨간색
        'fields': [
          {
            'name': '📱 제목',
            'value': title,
            'inline': false,
          },
          {
            'name': '📝 설명',
            'value': description,
            'inline': false,
          },
          if (stepsToReproduce != null) ...[
            {
              'name': '🔄 재현 단계',
              'value': stepsToReproduce,
              'inline': false,
            },
          ],
          if (expectedBehavior != null) ...[
            {
              'name': '✅ 예상 동작',
              'value': expectedBehavior,
              'inline': false,
            },
          ],
          if (actualBehavior != null) ...[
            {
              'name': '❌ 실제 동작',
              'value': actualBehavior,
              'inline': false,
            },
          ],
          {
            'name': '📱 앱 정보',
            'value':
                '버전: ${packageInfo.version}\n빌드: ${packageInfo.buildNumber}',
            'inline': true,
          },
          {
            'name': '🔧 디바이스 정보',
            'value': deviceInfoData,
            'inline': true,
          },
          if (userEmail != null) ...[
            {
              'name': '📧 연락처',
              'value': userEmail,
              'inline': true,
            },
          ],
          {
            'name': '⏰ 보고 시간',
            'value': DateTime.now().toIso8601String(),
            'inline': true,
          },
        ],
        'footer': {
          'text': 'HabitFit MVP - 버그 리포트 시스템',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 디스코드 웹훅 페이로드 생성
      final payload = {
        'username': 'HabitFit Bug Reporter',
        'avatar_url': 'https://cdn.discordapp.com/embed/avatars/0.png',
        'embeds': [embed],
      };

      // HTTP 요청 전송
      final response = await http.post(
        Uri.parse(_discordWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 204) {
        print('✅ 버그 리포트 전송 성공');
        return true;
      } else {
        print('❌ 버그 리포트 전송 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 버그 리포트 전송 오류: $e');
      return false;
    }
  }

  /// 크래시 리포트 전송
  Future<bool> sendCrashReport({
    required String error,
    required String stackTrace,
    String? context,
    Map<String, dynamic>? userData,
  }) async {
    try {
      print('💥 크래시 리포트 전송 시작');

      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      final embed = {
        'title': '💥 크래시 리포트',
        'description': '앱이 예상치 못하게 종료되었습니다.',
        'color': 0xff0000, // 빨간색
        'fields': [
          {
            'name': '🚨 오류 메시지',
            'value': '```\n$error\n```',
            'inline': false,
          },
          {
            'name': '📚 스택 트레이스',
            'value':
                '```\n${stackTrace.length > 1000 ? '${stackTrace.substring(0, 1000)}...' : stackTrace}\n```',
            'inline': false,
          },
          if (context != null) ...[
            {
              'name': '🔍 컨텍스트',
              'value': context,
              'inline': false,
            },
          ],
          {
            'name': '📱 앱 정보',
            'value':
                '버전: ${packageInfo.version}\n빌드: ${packageInfo.buildNumber}',
            'inline': true,
          },
          {
            'name': '🔧 디바이스 정보',
            'value': deviceInfo,
            'inline': true,
          },
          {
            'name': '⏰ 발생 시간',
            'value': DateTime.now().toIso8601String(),
            'inline': true,
          },
        ],
        'footer': {
          'text': 'HabitFit MVP - 크래시 리포트 시스템',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = {
        'username': 'HabitFit Crash Reporter',
        'avatar_url': 'https://cdn.discordapp.com/embed/avatars/1.png',
        'embeds': [embed],
      };

      final response = await http.post(
        Uri.parse(_discordWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 204) {
        print('✅ 크래시 리포트 전송 성공');
        return true;
      } else {
        print('❌ 크래시 리포트 전송 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 크래시 리포트 전송 오류: $e');
      return false;
    }
  }

  /// 피드백 전송
  Future<bool> sendFeedback({
    required String feedback,
    required String type, // 'feature', 'improvement', 'general'
    String? userEmail,
    int? rating,
  }) async {
    try {
      print('💬 피드백 전송 시작');

      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      String emoji = '💬';
      String title = '피드백';
      int color = 0x00ff00; // 초록색

      switch (type) {
        case 'feature':
          emoji = '✨';
          title = '기능 요청';
          color = 0x0099ff; // 파란색
          break;
        case 'improvement':
          emoji = '🔧';
          title = '개선 제안';
          color = 0xff9900; // 주황색
          break;
        case 'general':
        default:
          emoji = '💬';
          title = '일반 피드백';
          color = 0x00ff00; // 초록색
          break;
      }

      final embed = {
        'title': '$emoji $title',
        'description': feedback,
        'color': color,
        'fields': [
          {
            'name': '📝 피드백 내용',
            'value': feedback,
            'inline': false,
          },
          if (rating != null) ...[
            {
              'name': '⭐ 평점',
              'value': '${'⭐' * rating} ($rating/5)',
              'inline': true,
            },
          ],
          {
            'name': '📱 앱 정보',
            'value':
                '버전: ${packageInfo.version}\n빌드: ${packageInfo.buildNumber}',
            'inline': true,
          },
          {
            'name': '🔧 디바이스 정보',
            'value': deviceInfo,
            'inline': true,
          },
          if (userEmail != null) ...[
            {
              'name': '📧 연락처',
              'value': userEmail,
              'inline': true,
            },
          ],
          {
            'name': '⏰ 제출 시간',
            'value': DateTime.now().toIso8601String(),
            'inline': true,
          },
        ],
        'footer': {
          'text': 'HabitFit MVP - 피드백 시스템',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = {
        'username': 'HabitFit Feedback',
        'avatar_url': 'https://cdn.discordapp.com/embed/avatars/2.png',
        'embeds': [embed],
      };

      final response = await http.post(
        Uri.parse(_discordWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 204) {
        print('✅ 피드백 전송 성공');
        return true;
      } else {
        print('❌ 피드백 전송 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 피드백 전송 오류: $e');
      return false;
    }
  }

  /// 디바이스 정보 수집
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo();
        return 'iOS ${iosInfo.systemVersion}\n${iosInfo.model}\n${iosInfo.name}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo();
        return 'Android ${androidInfo.version.release}\n${androidInfo.model}\n${androidInfo.brand}';
      } else {
        return 'Unknown Platform';
      }
    } catch (e) {
      return '디바이스 정보 수집 실패: $e';
    }
  }

  /// 웹훅 URL 유효성 검사
  bool isWebhookConfigured() {
    return _discordWebhookUrl != 'YOUR_DISCORD_WEBHOOK_URL_HERE' &&
        _discordWebhookUrl.isNotEmpty;
  }

  /// 테스트 메시지 전송
  Future<bool> sendTestMessage() async {
    try {
      print('🧪 테스트 메시지 전송 시작');

      final embed = {
        'title': '🧪 테스트 메시지',
        'description': '버그 리포트 시스템이 정상적으로 작동합니다!',
        'color': 0x00ff00, // 초록색
        'fields': [
          {
            'name': '✅ 상태',
            'value': '시스템 정상 작동',
            'inline': true,
          },
          {
            'name': '⏰ 테스트 시간',
            'value': DateTime.now().toIso8601String(),
            'inline': true,
          },
        ],
        'footer': {
          'text': 'HabitFit MVP - 테스트 시스템',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = {
        'username': 'HabitFit Test',
        'avatar_url': 'https://cdn.discordapp.com/embed/avatars/3.png',
        'embeds': [embed],
      };

      final response = await http.post(
        Uri.parse(_discordWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 204) {
        print('✅ 테스트 메시지 전송 성공');
        return true;
      } else {
        print('❌ 테스트 메시지 전송 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 테스트 메시지 전송 오류: $e');
      return false;
    }
  }
}
