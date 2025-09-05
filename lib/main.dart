import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'providers/auth_provider.dart';

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

  // 초기화 로직은 이제 SplashScreen에서 처리됨
  print('🚀 앱 시작 - 스플래시 화면으로 이동');

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ProviderScope(child: HabitFitApp()),
    ),
  );
}
