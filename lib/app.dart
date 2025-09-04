import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'features/auth/login_page.dart';
import 'features/habit/habit_page.dart';
import 'features/workout/workout_page.dart';
import 'features/meals/meal_page.dart';
import 'features/report/report_page.dart';
import 'features/settings/settings_page.dart';
import 'features/health/health_test_page.dart';
import 'features/running/running_analysis_page.dart';
import 'providers/auth_provider.dart';

class HabitFitApp extends ConsumerWidget {
  const HabitFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'HabitFit MVP',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Pretendard', // 한국어 폰트 설정
      ),
      routes: {
        '/home': (context) => const _HomeShell(),
      },
      home: const AuthWrapper(),
    );
  }
}

/// 인증 상태에 따른 화면 표시를 담당하는 위젯
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 로딩 중일 때는 스플래시 화면 표시
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('HabitFit 시작 중...'),
                ],
              ),
            ),
          );
        }

        // 인증된 사용자는 메인 화면으로
        if (authProvider.isSignedIn) {
          return const _HomeShell();
        }

        // 인증되지 않은 사용자는 로그인 화면으로
        return const LoginPage();
      },
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({super.key});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _idx = 0;
  final _pages = const [
    HabitPage(),
    WorkoutPage(),
    MealPage(),
    ReportPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_idx],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Habit'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Meals'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.person), label: 'User'),
        ],
      ),
    );
  }
}
