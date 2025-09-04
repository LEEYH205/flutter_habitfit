import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 네비게이션 서비스 - 딥링크 라우팅 관리
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Today 페이지로 이동
  static void goToToday() {
    navigatorKey.currentContext?.go('/today');
  }

  /// Journal 페이지로 이동
  static void goToJournal() {
    navigatorKey.currentContext?.go('/journal');
  }

  /// 특정 날짜의 Journal 페이지로 이동
  static void goToJournalDate(DateTime date) {
    final dateString = _formatDateForRoute(date);
    navigatorKey.currentContext?.go('/journal/$dateString');
  }

  /// Insights 페이지로 이동
  static void goToInsights() {
    navigatorKey.currentContext?.go('/insights');
  }

  /// 특정 범위의 Insights 페이지로 이동
  static void goToInsightsWithRange(String range) {
    navigatorKey.currentContext?.go('/insights?range=$range');
  }

  /// Settings 페이지로 이동
  static void goToSettings() {
    navigatorKey.currentContext?.go('/settings');
  }

  /// 습관 페이지로 이동 (Today에서 빠른 액션)
  static void goToHabits() {
    navigatorKey.currentContext?.go('/today?action=habits');
  }

  /// 운동 페이지로 이동 (Today에서 빠른 액션)
  static void goToWorkout() {
    navigatorKey.currentContext?.go('/today?action=workout');
  }

  /// 식사 페이지로 이동 (Today에서 빠른 액션)
  static void goToMeals() {
    navigatorKey.currentContext?.go('/today?action=meals');
  }

  /// 날짜를 라우트용 문자열로 변환 (YYYYMMDD)
  static String _formatDateForRoute(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// 라우트용 날짜 문자열을 DateTime으로 변환
  static DateTime parseDateFromRoute(String dateString) {
    final year = int.parse(dateString.substring(0, 4));
    final month = int.parse(dateString.substring(4, 6));
    final day = int.parse(dateString.substring(6, 8));
    return DateTime(year, month, day);
  }

  /// 현재 라우트 정보 가져오기
  static String? getCurrentRoute() {
    return GoRouterState.of(navigatorKey.currentContext!).uri.toString();
  }

  /// 라우트 파라미터 가져오기
  static Map<String, String> getRouteParams() {
    final uri = GoRouterState.of(navigatorKey.currentContext!).uri;
    return uri.queryParameters;
  }

  /// 뒤로 가기
  static void goBack() {
    navigatorKey.currentContext?.pop();
  }

  /// 특정 라우트로 교체 (뒤로 가기 불가)
  static void goReplace(String route) {
    navigatorKey.currentContext?.go(route);
  }

  /// 특정 라우트로 푸시 (뒤로 가기 가능)
  static void goPush(String route) {
    navigatorKey.currentContext?.push(route);
  }
}

/// 라우트 상수
class AppRoutes {
  static const String today = '/today';
  static const String journal = '/journal';
  static const String insights = '/insights';
  static const String settings = '/settings';
  
  // 동적 라우트
  static String journalDate(DateTime date) => '/journal/${_formatDate(date)}';
  static String insightsWithRange(String range) => '/insights?range=$range';
  
  static String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}

/// 라우트 가드 - 각 페이지의 접근 권한 관리
class RouteGuard {
  /// Today 페이지 접근 가능 여부
  static bool canAccessToday() {
    // 모든 사용자가 접근 가능
    return true;
  }

  /// Journal 페이지 접근 가능 여부
  static bool canAccessJournal() {
    // 로그인된 사용자만 접근 가능
    return true; // TODO: 실제 인증 상태 확인
  }

  /// Insights 페이지 접근 가능 여부
  static bool canAccessInsights() {
    // 로그인된 사용자만 접근 가능
    return true; // TODO: 실제 인증 상태 확인
  }

  /// Settings 페이지 접근 가능 여부
  static bool canAccessSettings() {
    // 로그인된 사용자만 접근 가능
    return true; // TODO: 실제 인증 상태 확인
  }
}
