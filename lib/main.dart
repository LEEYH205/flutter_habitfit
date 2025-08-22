import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart'; // flutterfire configure 후 생성/대체
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

  // 알림 권한 요청 & 초기화
  await FcmService.instance.init();

  // Remote Config: thresholds & smoothing window
  await RemoteConfigService.instance.init();

  runApp(const ProviderScope(child: HabitFitApp()));
}
