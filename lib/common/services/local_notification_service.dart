import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print('🔔 로컬 알림 서비스 초기화 시작...');

    // 타임존 초기화
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      print('✅ 로컬 알림 초기화 성공');
    } catch (e) {
      print('❌ 로컬 알림 초기화 실패: $e');
    }
  }

  // 1. 운동 완료 시 자동 알림
  Future<void> showWorkoutCompletionNotification(
      int reps, String exerciseType) async {
    try {
      await _localNotifications.show(
        1,
        '💪 운동 완료!',
        '오늘 $exerciseType $reps회 완료했습니다!',
        _getWorkoutNotificationDetails(),
      );
      print('✅ 운동 완료 알림 전송 성공');
    } catch (e) {
      print('❌ 운동 완료 알림 전송 실패: $e');
    }
  }

  // 1-1. 습관 체크 완료 알림
  Future<void> showHabitCompletionNotification(
      String title, String body) async {
    try {
      await _localNotifications.show(
        3,
        title,
        body,
        _getHabitNotificationDetails(),
      );
      print('✅ 습관 체크 완료 알림 전송 성공');
    } catch (e) {
      print('❌ 습관 체크 완료 알림 전송 실패: $e');
    }
  }

  // 1-2. 연속 달성 축하 알림
  Future<void> showStreakAchievementNotification(
      String title, String body) async {
    try {
      await _localNotifications.show(
        4,
        title,
        body,
        _getHabitNotificationDetails(),
      );
      print('✅ 연속 달성 축하 알림 전송 성공');
    } catch (e) {
      print('❌ 연속 달성 축하 알림 전송 실패: $e');
    }
  }

  // 2. 습관 체크 리마인더 (매일 특정 시간)
  Future<void> scheduleHabitReminder(TimeOfDay reminderTime) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // 이미 오늘 시간이 지났다면 내일로 설정
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        2,
        '📝 습관 체크',
        '오늘의 습관을 체크해보세요!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getHabitNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print(
          '✅ 습관 체크 리마인더 설정 성공: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ 습관 체크 리마인더 설정 실패: $e');
    }
  }

  // 2-1. 일일 운동 요약 알림 (매일 특정 시간)
  Future<void> scheduleDailyWorkoutSummary(TimeOfDay summaryTime) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        summaryTime.hour,
        summaryTime.minute,
      );

      // 이미 오늘 시간이 지났다면 내일로 설정
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        3,
        '📊 일일 운동 요약',
        '오늘의 운동 기록을 확인해보세요!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getSummaryNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print(
          '✅ 일일 운동 요약 알림 설정 성공: ${summaryTime.hour}:${summaryTime.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ 일일 운동 요약 알림 설정 실패: $e');
    }
  }

  // 3. 일일/주간 운동 요약 알림
  Future<void> showDailyWorkoutSummary(int totalReps, int totalCalories) async {
    try {
      await _localNotifications.show(
        3,
        '📊 오늘의 운동 요약',
        '총 $totalReps회, ${totalCalories}kcal 소모!',
        _getSummaryNotificationDetails(),
      );
      print('✅ 일일 운동 요약 알림 전송 성공');
    } catch (e) {
      print('❌ 일일 운동 요약 알림 전송 실패: $e');
    }
  }

  // 4. 목표 달성 축하 알림
  Future<void> showGoalAchievementNotification(
      String goalType, int achievedValue) async {
    try {
      await _localNotifications.show(
        4,
        '🎯 목표 달성!',
        '$goalType 목표를 달성했습니다! ($achievedValue)',
        _getAchievementNotificationDetails(),
      );
      print('✅ 목표 달성 축하 알림 전송 성공');
    } catch (e) {
      print('❌ 목표 달성 축하 알림 전송 실패: $e');
    }
  }

  // 5. 주간 운동 요약 알림 (매주 일요일)
  Future<void> scheduleWeeklyWorkoutSummary() async {
    try {
      final now = DateTime.now();
      var nextSunday = now;

      // 다음 일요일 찾기
      while (nextSunday.weekday != DateTime.sunday) {
        nextSunday = nextSunday.add(const Duration(days: 1));
      }

      // 오후 8시로 설정
      final scheduledDate = DateTime(
        nextSunday.year,
        nextSunday.month,
        nextSunday.day,
        20, // 오후 8시
        0,
      );

      await _localNotifications.zonedSchedule(
        5,
        '📈 주간 운동 요약',
        '이번 주 운동 기록을 확인해보세요!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getWeeklySummaryNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      print('✅ 주간 운동 요약 알림 설정 성공');
    } catch (e) {
      print('❌ 주간 운동 요약 알림 설정 실패: $e');
    }
  }

  // 6. 테스트 알림
  Future<void> showTestNotification() async {
    try {
      await _localNotifications.show(
        999,
        '🧪 테스트 알림',
        '로컬 알림이 정상 작동합니다!',
        _getTestNotificationDetails(),
      );
      print('✅ 테스트 알림 전송 성공');
    } catch (e) {
      print('❌ 테스트 알림 전송 실패: $e');
    }
  }

  // 알림 상세 설정들
  NotificationDetails _getWorkoutNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_channel',
        '운동 완료',
        channelDescription: '운동 완료 시 알림',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50), // 초록색
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  NotificationDetails _getHabitNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_channel',
        '습관 체크',
        channelDescription: '습관 체크 리마인더',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3), // 파란색
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  NotificationDetails _getSummaryNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'summary_channel',
        '운동 요약',
        channelDescription: '일일/주간 운동 요약',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800), // 주황색
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  NotificationDetails _getAchievementNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'achievement_channel',
        '목표 달성',
        channelDescription: '목표 달성 축하',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE91E63), // 분홍색
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  NotificationDetails _getWeeklySummaryNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_summary_channel',
        '주간 요약',
        channelDescription: '주간 운동 요약',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF9C27B0), // 보라색
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  NotificationDetails _getTestNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        '테스트',
        channelDescription: '테스트 알림',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  // 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 알림 탭됨: ${response.payload}');
    // TODO: 특정 화면으로 네비게이션
  }

  // 모든 예약된 알림 취소
  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ 모든 예약된 알림 취소됨');
    } catch (e) {
      print('❌ 알림 취소 실패: $e');
    }
  }

  // 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      print('✅ 알림 취소됨: ID $id');
    } catch (e) {
      print('❌ 알림 취소 실패: $e');
    }
  }
}
