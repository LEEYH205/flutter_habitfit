import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print('🔔 FCM 서비스 초기화 시작...');
    final messaging = FirebaseMessaging.instance;

    try {
      // iOS foreground permission
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('🔐 FCM 권한 상태: $permission');

      // iOS에서 APNS 토큰 가져오기 (선택적)
      if (Platform.isIOS) {
        try {
          final apnsToken = await messaging.getAPNSToken();
          print('🍎 APNS Token: $apnsToken');

          if (apnsToken == null) {
            print('⚠️ APNS 토큰이 null입니다. FCM만으로 시도합니다...');
          }
        } catch (e) {
          print('⚠️ APNS 토큰 가져오기 실패: $e');
          print('⚠️ FCM만으로 시도합니다...');
        }
      }

      // FCM 토큰 가져오기 (APNS 없이도 시도)
      try {
        final token = await messaging.getToken();
        print('🔔 FCM Token: $token');

        if (token != null) {
          print('✅ FCM 토큰 획득 성공!');
          print('📱 이 토큰을 Firebase Console에서 사용하여 테스트 메시지를 보내세요!');
        } else {
          print('❌ FCM 토큰 획득 실패');
        }
      } catch (e) {
        print('❌ FCM 토큰 가져오기 실패: $e');
        print('💡 APNS 환경 설정이 필요할 수 있습니다.');
      }

      // 로컬 알림 초기화
      await _initLocalNotifications();
    } catch (e) {
      print('❌ FCM 초기화 실패: $e');
      print('❌ 오류 상세: ${StackTrace.current}');
    }

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      print('📝 Title: ${message.notification?.title}');
      print('📝 Body: ${message.notification?.body}');

      // 로컬 알림으로 표시
      _showLocalNotification(message);
    });

    // 백그라운드 메시지 처리
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 알림 탭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped: ${message.messageId}');
      // TODO: 특정 화면으로 네비게이션
    });
  }

  Future<void> _initLocalNotifications() async {
    print('🔔 로컬 알림 초기화 시작...');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(initSettings);
      print('✅ 로컬 알림 초기화 성공');

      // iOS 권한 요청
      if (Platform.isIOS) {
        final result = await _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        print('🔐 iOS 알림 권한 결과: $result');
      }
    } catch (e) {
      print('❌ 로컬 알림 초기화 실패: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'habitfit_channel',
      'HabitFit Notifications',
      channelDescription: '습관 관리 및 운동 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'HabitFit',
      message.notification?.body ?? '새로운 알림이 있습니다',
      details,
    );
  }

  // 테스트용 로컬 알림
  Future<void> showTestNotification() async {
    print('🧪 테스트 알림 시작...');

    try {
      const androidDetails = AndroidNotificationDetails(
        'habitfit_channel',
        'HabitFit Notifications',
        channelDescription: '습관 관리 및 운동 알림',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'test_category',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('📱 알림 세부사항 설정 완료');

      await _localNotifications.show(
        0,
        '🧪 FCM 테스트',
        '푸시 알림이 정상적으로 작동합니다!',
        details,
      );

      print('✅ 테스트 알림 전송 성공');
    } catch (e) {
      print('❌ 테스트 알림 전송 실패: $e');
      print('❌ 오류 상세: ${StackTrace.current}');
    }
  }
}

// 백그라운드 메시지 핸들러 (최상위 레벨에 정의)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');
  print('📝 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
}
