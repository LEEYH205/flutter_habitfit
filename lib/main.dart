import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'firebase_options.dart';
import 'app.dart';
import 'common/services/fcm_service.dart';
import 'common/services/remote_config_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(const ProviderScope(child: HabitFitApp()));
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
