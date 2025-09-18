import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../features/auth/login_page.dart';
import '../../features/plan/plan_page.dart';
import '../../features/activity/activity_page.dart';
import '../../features/running/running_page.dart';
import '../../features/ranking/ranking_main_page.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/watch/watch_test_page.dart';
import '../../features/bug_report/bug_report_page.dart';
import '../../features/user_level/user_membership_page.dart';
import '../../features/points/points_page.dart';
import '../../features/test_security_page.dart';
import '../../providers/auth_provider.dart';

/// 탭 인덱스 관리 (간단한 방향성 계산용)
class _TabManager {
  static int _currentIndex = 0;

  static final List<String> _routes = [
    '/plan',
    '/activity',
    '/running',
    '/ranking',
    '/points'
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

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/plan',
    redirect: (context, state) {
      final authNotifier =
          provider.Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authNotifier.isSignedIn;
      final isLoading = authNotifier.isLoading;

      // 로딩 중이면 대기
      if (isLoading) {
        return null;
      }

      // 인증되지 않은 사용자는 로그인 페이지로
      if (!isAuthenticated) {
        return '/login';
      }

      // 인증된 사용자는 메인 페이지로
      return null;
    },
    routes: [
      // 스플래시 화면
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 로그인 페이지
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
          // Plan 페이지
          GoRoute(
            path: '/plan',
            name: 'plan',
            pageBuilder: (context, state) {
              print('🎯 PLAN pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              final action = state.uri.queryParameters['action'];

              return CustomTransitionPage(
                key: state.pageKey,
                child: PlanPage(action: action),
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

          // Activity 페이지
          GoRoute(
            path: '/activity',
            name: 'activity',
            pageBuilder: (context, state) {
              print('🎯 ACTIVITY pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const ActivityPage(),
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

          // Running 페이지
          GoRoute(
            path: '/running',
            name: 'running',
            pageBuilder: (context, state) {
              print('🎯 RUNNING pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const RunningPage(),
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

          // Ranking 페이지
          GoRoute(
            path: '/ranking',
            name: 'ranking',
            pageBuilder: (context, state) {
              print('🎯 RANKING pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const RankingMainPage(),
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

          // Points 페이지
          GoRoute(
            path: '/points',
            name: 'points',
            pageBuilder: (context, state) {
              print('🎯 POINTS pageBuilder called: ${state.uri.path}');
              final targetIndex = _TabManager.getRouteIndex(state.uri.path);
              final isMovingRight = _TabManager.isMovingRight(targetIndex);
              _TabManager.updateCurrentIndex(state.uri.path);

              return CustomTransitionPage(
                key: state.pageKey,
                child: const PointsPage(),
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
        ],
      ),

      // 독립 페이지들 (하단 탭에 포함되지 않음)
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
        path: '/membership',
        name: 'membership',
        builder: (context, state) => const UserMembershipPage(),
      ),
      GoRoute(
        path: '/test-security',
        name: 'test-security',
        builder: (context, state) => const TestSecurityPage(),
      ),
    ],
  );
}

class _MainShell extends ConsumerWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _BottomNavigationBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.path;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _TabManager.getRouteIndex(currentLocation),
      onTap: (index) {
        final routes = ['/plan', '/activity', '/running', '/ranking', '/points'];
        if (index < routes.length) {
          context.go(routes[index]);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '플랜',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: '활동',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_run),
          label: '러닝',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: '랭킹',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.stars),
          label: '포인트',
        ),
      ],
    );
  }
}
