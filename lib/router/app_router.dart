import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_page.dart';
import '../../features/today/today_page.dart';
import '../../features/journal/journal_page.dart';
import '../../features/insights/insights_page.dart';
import '../../features/settings/settings_page.dart';
import '../../providers/auth_provider.dart';
import '../../services/navigation_service.dart';

/// 앱 라우터 설정
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/today',
    routes: [
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
            builder: (context, state) {
              final action = state.uri.queryParameters['action'];
              return TodayPage(action: action);
            },
          ),
          
          // Journal 페이지
          GoRoute(
            path: '/journal',
            name: 'journal',
            builder: (context, state) => const JournalPage(),
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
            builder: (context, state) {
              final range = state.uri.queryParameters['range'];
              return InsightsPage(initialRange: range);
            },
          ),
          
          // Settings 페이지
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    
    // 리다이렉트 로직
    redirect: (context, state) {
      final isLoggedIn = true; // TODO: 실제 인증 상태 확인
      
      // 로그인되지 않은 경우 로그인 페이지로
      if (!isLoggedIn && state.location != '/login') {
        return '/login';
      }
      
      // 로그인된 경우 로그인 페이지에서 메인으로
      if (isLoggedIn && state.location == '/login') {
        return '/today';
      }
      
      return null;
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
              state.location,
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

/// 메인 셸 위젯 (하단 탭 네비게이션)
class _MainShell extends StatefulWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

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
                _buildNavItem(2, Icons.analytics_outlined, 'Insights', '/insights'),
                _buildNavItem(3, Icons.settings_outlined, 'Settings', '/settings'),
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
        setState(() {
          _currentIndex = index;
        });
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
