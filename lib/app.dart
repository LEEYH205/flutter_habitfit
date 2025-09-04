import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'features/auth/login_page.dart';
import 'features/habit/habit_page.dart';
import 'features/workout/workout_page.dart';
import 'features/meals/meal_page.dart';
import 'features/report/report_page.dart';
import 'features/settings/settings_page.dart';
import 'features/home/home_page.dart';
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
  int _idx = 2; // Start with Home page (index 2)
  final _pages = const [
    HabitPage(),
    WorkoutPage(),
    HomePage(),
    MealPage(),
    ReportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.check_circle_outline, 'Habit'),
                _buildNavItem(1, Icons.fitness_center_outlined, 'Workout'),
                _buildNavItem(2, Icons.home_outlined, 'Home'),
                _buildNavItem(3, Icons.restaurant_outlined, 'Meals'),
                _buildNavItem(4, Icons.assessment_outlined, 'Report'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _idx == index;

    return GestureDetector(
      onTap: () => setState(() => _idx = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
