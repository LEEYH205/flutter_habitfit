import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:health/health.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'common/services/fcm_service.dart';
import 'common/services/local_notification_service.dart';
import 'common/services/remote_config_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Korean locale
  try {
    await initializeDateFormatting('ko_KR', null);
  } catch (e) {
    // Fallback to default locale if Korean fails
    await initializeDateFormatting();
    print('⚠️ Korean locale initialization failed, using default: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM과 Remote Config 초기화 (시뮬레이터에서는 FCM 비활성화)
  try {
    if (!Platform.isIOS || !await _isSimulator()) {
      await FcmService.instance.init();
    }
    await RemoteConfigService.instance.init();
  } catch (e) {
    print('Firebase services initialization failed: $e');
  }

  // 로컬 알림 서비스 초기화 (FCM과 독립적으로 작동)
  try {
    await LocalNotificationService.instance.init();
    print('✅ 로컬 알림 서비스 초기화 성공');
  } catch (e) {
    print('❌ 로컬 알림 서비스 초기화 실패: $e');
  }

  // HealthKit 권한 초기 체크 (iOS에서만)
  if (Platform.isIOS) {
    try {
      await _initializeHealthKit();
    } catch (e) {
      print('❌ HealthKit 초기화 실패: $e');
    }
  }

  runApp(const ProviderScope(child: HabitFitApp()));
}

/// HealthKit 초기화 및 기본 권한 체크
Future<void> _initializeHealthKit() async {
  try {
    final health = HealthFactory();

    // 기본 권한 요청 (걸음 수, 심박수, 운동 거리)
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.WORKOUT,
    ];

    final granted = await health.requestAuthorization(types);
    if (granted) {
      print('✅ HealthKit 기본 권한 승인됨');
    } else {
      print('⚠️ HealthKit 권한 거부됨');
    }
  } catch (e) {
    print('❌ HealthKit 초기화 오류: $e');
  }
}

// iOS 시뮬레이터인지 확인하는 헬퍼 함수
Future<bool> _isSimulator() async {
  try {
    final result = await Process.run('xcrun', ['simctl', 'list', 'devices']);
    return result.stdout.toString().contains('Simulator');
  } catch (e) {
    return false;
  }
}
