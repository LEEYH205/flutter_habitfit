import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';

class HabitFitApp extends ConsumerWidget {
  const HabitFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'HabitFit MVP',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Pretendard', // 한국어 폰트 설정
      ),
      routerConfig: AppRouter.router,
    );
  }
}

// GoRouter를 사용하므로 기존 네비게이션 코드는 app_router.dart로 이동
