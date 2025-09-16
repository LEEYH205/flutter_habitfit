import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:provider/provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/today/today_page.dart';
import '../../features/journal/journal_page.dart';
import '../../features/insights/insights_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/watch/watch_test_page.dart';
import '../../features/bug_report/bug_report_page.dart';
import '../../features/user_level/user_level_page.dart';
import '../../features/points/points_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_provider.dart' as auth;

/// 탭 인덱스 관리 (간단한 방향성 계산용)
class _TabManager {
  static int _currentIndex = 0;

  static final List<String> _routes = [
    '/today',
    '/journal',
    '/insights',
    '/settings'
  ];

  static int getRouteIndex(String route) {
    for (int i = 0; i < _routes.length; i++) {
      if (route.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  static void updateCurrentIndex(String route) {
    final newIndex = getRouteIndex(route);
    print(
        '📍 Current index updated: $_currentIndex → $newIndex (route: $route)');
    _currentIndex = newIndex;
  }

  /// 슬라이드 방향 결정
  /// 현재인덱스 - 목표인덱스
  /// 음수 = 오른쪽에서 왼쪽으로 슬라이드 (목표가 더 큰 인덱스)
  /// 양수 = 왼쪽에서 오른쪽으로 슬라이드 (목표가 더 작은 인덱스)
  static bool isMovingRight(int targetIndex) {
    final diff = _currentIndex - targetIndex;
    final movingRight = diff > 0;

    if (_currentIndex != targetIndex) {
      print(
          '🎬 Tab Animation: ${_routes[_currentIndex]} → ${_routes[targetIndex]}');
      print('   📊 Index: $_currentIndex → $targetIndex (diff: $diff)');
      print('   ➡️ Direction: ${movingRight ? "왼쪽에서 오른쪽으로" : "오른쪽에서 왼쪽으로"}');
    }

    return movingRight;
  }
}

/// 앱 라우터 설정
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // 스플래시 화면
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 메인 앱 라우트
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => _MainAppWrapper(),
      ),

      // 인증 관련 라우트
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // 메인 셸 (하단 탭 네비게이션)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          // Today 페이지
          GoRoute(
            path: '/today',
            name: 'today',
            pageBuilder: (context, state) {
              print('🎯 TODAY pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              final action = state.uri.queryParameters['action'];

              return CustomTransitionPage(
                key: state.pageKey,
                child: TodayPage(action: action),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),

          // Journal 페이지
          GoRoute(
            path: '/journal',
            name: 'journal',
            pageBuilder: (context, state) {
              print('🎯 JOURNAL pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const JournalPage(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
            routes: [
              // 특정 날짜의 Journal 페이지
              GoRoute(
                path: '/:date',
                name: 'journal-date',
                builder: (context, state) {
                  final dateString = state.pathParameters['date']!;
                  final date = _parseDate(dateString);
                  return JournalPage(initialDate: date);
                },
              ),
            ],
          ),

          // Insights 페이지
          GoRoute(
            path: '/insights',
            name: 'insights',
            pageBuilder: (context, state) {
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              final range = state.uri.queryParameters['range'];

              return CustomTransitionPage(
                key: state.pageKey,
                child: InsightsPage(initialRange: range),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),

          // Settings 페이지
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) {
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsPage(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),

          // Watch 테스트 페이지
          GoRoute(
            path: '/watch-test',
            name: 'watch-test',
            builder: (context, state) => const WatchTestPage(),
          ),

          // 버그 리포트 페이지
          GoRoute(
            path: '/bug-report',
            name: 'bug-report',
            builder: (context, state) => const BugReportPage(),
          ),

          // 사용자 레벨 페이지
          GoRoute(
            path: '/user-level',
            name: 'user-level',
            builder: (context, state) => const UserLevelPage(),
          ),

          // 포인트 페이지
          GoRoute(
            path: '/points',
            name: 'points',
            builder: (context, state) => const PointsPage(),
          ),
        ],
      ),
    ],

    // 리다이렉트 로직
    redirect: (context, state) {
      // AuthProvider가 아직 초기화되지 않은 경우 로딩 상태 유지
      try {
        final authProvider =
            provider.Provider.of<AuthProvider>(context, listen: false);

        // 로딩 중인 경우 리다이렉트하지 않음
        if (authProvider.isLoading) {
          return null;
        }

        final isLoggedIn = authProvider.isSignedIn;

        // 로그인되지 않은 경우 로그인 페이지로
        if (!isLoggedIn && state.uri.toString() != '/login') {
          return '/login';
        }

        // 로그인된 경우 로그인 페이지에서 메인으로
        if (isLoggedIn && state.uri.toString() == '/login') {
          return '/today';
        }

        return null;
      } catch (e) {
        // Provider가 아직 준비되지 않은 경우 로그인 페이지로
        if (state.uri.toString() != '/login') {
          return '/login';
        }
        return null;
      }
    },

    // 에러 페이지
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/today'),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );

  /// 날짜 문자열 파싱 (YYYYMMDD)
  static DateTime _parseDate(String dateString) {
    final year = int.parse(dateString.substring(0, 4));
    final month = int.parse(dateString.substring(4, 6));
    final day = int.parse(dateString.substring(6, 8));
    return DateTime(year, month, day);
  }
}

/// 메인 앱 래퍼 (초기화 완료 후 메인 앱 표시)
class _MainAppWrapper extends ConsumerWidget {
  _MainAppWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'HabitFit MVP',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      routerConfig: _mainRouter,
    );
  }

  final GoRouter _mainRouter = GoRouter(
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            name: 'today',
            pageBuilder: (context, state) {
              print('🎯 TODAY pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              final action = state.uri.queryParameters['action'];

              return CustomTransitionPage(
                key: state.pageKey,
                child: TodayPage(action: action),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/journal',
            name: 'journal',
            pageBuilder: (context, state) {
              print('🎯 JOURNAL pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const JournalPage(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            pageBuilder: (context, state) {
              print('🎯 INSIGHTS pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const InsightsPage(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) {
              print('🎯 SETTINGS pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsPage(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideOffset = isMovingRight
                      ? const Offset(-1.0, 0.0) // 왼쪽에서 오른쪽으로
                      : const Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로

                  var tween = Tween(begin: slideOffset, end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/watch-test',
            name: 'watch-test',
            builder: (context, state) => const WatchTestPage(),
          ),
          GoRoute(
            path: '/bug-report',
            name: 'bug-report',
            builder: (context, state) => const BugReportPage(),
          ),
          GoRoute(
            path: '/user-level',
            name: 'user-level',
            builder: (context, state) => const UserLevelPage(),
          ),
          GoRoute(
            path: '/points',
            name: 'points',
            builder: (context, state) => const PointsPage(),
          ),
        ],
      ),
    ],
  );
}

/// 메인 셸 위젯 (하단 탭 네비게이션)
class _MainShell extends StatefulWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
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
                _buildNavItem(0, Icons.today_outlined, 'Today', '/today'),
                _buildNavItem(1, Icons.book_outlined, 'Journal', '/journal'),
                _buildNavItem(
                    2, Icons.analytics_outlined, 'Insights', '/insights'),
                _buildNavItem(
                    3, Icons.settings_outlined, 'Settings', '/settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, String route) {
    final isSelected = _isCurrentRoute(route);

    return GestureDetector(
      onTap: () {
        context.go(route);
      },
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

  /// 현재 라우트가 선택된 라우트인지 확인
  bool _isCurrentRoute(String route) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    return currentLocation.startsWith(route);
  }
}
