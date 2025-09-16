import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 패턴 분석을 위한 데이터 모델
class UserPattern {
  final String uid;
  final Map<int, double> timeBasedPerformance; // 시간대별 성과 (0-23시)
  final Map<int, double> dayBasedPerformance; // 요일별 성과 (1-7, 월-일)
  final double overallCompletionRate; // 전체 완료율
  final int totalHabits; // 총 습관 수
  final int completedHabits; // 완료된 습관 수
  final List<String> bestTimeSlots; // 최적 시간대
  final List<String> bestDays; // 최적 요일
  final double consistencyScore; // 일관성 점수 (0-1)
  final DateTime lastUpdated;

  UserPattern({
    required this.uid,
    required this.timeBasedPerformance,
    required this.dayBasedPerformance,
    required this.overallCompletionRate,
    required this.totalHabits,
    required this.completedHabits,
    required this.bestTimeSlots,
    required this.bestDays,
    required this.consistencyScore,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'timeBasedPerformance':
          _convertIntDoubleMapToStringMap(timeBasedPerformance),
      'dayBasedPerformance':
          _convertIntDoubleMapToStringMap(dayBasedPerformance),
      'overallCompletionRate': overallCompletionRate,
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'bestTimeSlots': bestTimeSlots,
      'bestDays': bestDays,
      'consistencyScore': consistencyScore,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Map<int, double>를 Map<String, double>로 변환 (Firestore 저장용)
  Map<String, double> _convertIntDoubleMapToStringMap(Map<int, double> intMap) {
    final result = <String, double>{};
    intMap.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  factory UserPattern.fromMap(Map<String, dynamic> map) {
    // lastUpdated 필드 처리 - Timestamp 또는 String 모두 지원
    DateTime lastUpdated;
    final lastUpdatedValue = map['lastUpdated'];
    if (lastUpdatedValue == null) {
      lastUpdated = DateTime.now();
    } else if (lastUpdatedValue is Timestamp) {
      lastUpdated = lastUpdatedValue.toDate();
    } else if (lastUpdatedValue is String) {
      lastUpdated = DateTime.parse(lastUpdatedValue);
    } else {
      lastUpdated = DateTime.now();
    }

    return UserPattern(
      uid: map['uid'] ?? '',
      timeBasedPerformance: _parseIntDoubleMap(map['timeBasedPerformance']),
      dayBasedPerformance: _parseIntDoubleMap(map['dayBasedPerformance']),
      overallCompletionRate: (map['overallCompletionRate'] ?? 0.0).toDouble(),
      totalHabits: map['totalHabits'] ?? 0,
      completedHabits: map['completedHabits'] ?? 0,
      bestTimeSlots: _parseStringList(map['bestTimeSlots']),
      bestDays: _parseStringList(map['bestDays']),
      consistencyScore: (map['consistencyScore'] ?? 0.0).toDouble(),
      lastUpdated: lastUpdated,
    );
  }

  /// Map<String, dynamic>에서 Map<int, double>로 안전하게 변환
  static Map<int, double> _parseIntDoubleMap(dynamic data) {
    if (data == null) return {};

    final result = <int, double>{};
    if (data is Map) {
      data.forEach((key, value) {
        // 키를 int로 변환
        int? intKey;
        if (key is int) {
          intKey = key;
        } else if (key is String) {
          intKey = int.tryParse(key);
        }

        // 값을 double로 변환
        double? doubleValue;
        if (value is double) {
          doubleValue = value;
        } else if (value is int) {
          doubleValue = value.toDouble();
        } else if (value is String) {
          doubleValue = double.tryParse(value);
        } else if (value is num) {
          doubleValue = value.toDouble();
        }

        if (intKey != null && doubleValue != null) {
          result[intKey] = doubleValue;
        }
      });
    }

    return result;
  }

  /// 동적 리스트에서 List<String>로 안전하게 변환
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];

    final result = <String>[];
    if (data is List) {
      for (final item in data) {
        if (item != null) {
          result.add(item.toString());
        }
      }
    }

    return result;
  }
}

/// 사용자 패턴 분석 서비스
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자 패턴 분석 (최근 30일 데이터 기반)
  Future<UserPattern> analyzeUserPattern(String uid) async {
    try {
      print('🔍 사용자 패턴 분석 시작: $uid');

      // 최근 30일 데이터 수집
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      // 습관 완료 데이터 수집
      final habitCompletions =
          await _getHabitCompletions(uid, startDate, endDate);
      final userHabits = await _getUserHabits(uid);

      // 시간대별 성과 분석
      final timeBasedPerformance =
          _analyzeTimeBasedPerformance(habitCompletions);

      // 요일별 성과 분석
      final dayBasedPerformance = _analyzeDayBasedPerformance(habitCompletions);

      // 전체 완료율 계산
      final overallCompletionRate =
          _calculateOverallCompletionRate(habitCompletions, userHabits);

      // 최적 시간대 찾기
      final bestTimeSlots = _findBestTimeSlots(timeBasedPerformance);

      // 최적 요일 찾기
      final bestDays = _findBestDays(dayBasedPerformance);

      // 일관성 점수 계산
      final consistencyScore = _calculateConsistencyScore(habitCompletions);

      final pattern = UserPattern(
        uid: uid,
        timeBasedPerformance: timeBasedPerformance,
        dayBasedPerformance: dayBasedPerformance,
        overallCompletionRate: overallCompletionRate,
        totalHabits: userHabits.length,
        completedHabits: habitCompletions.length,
        bestTimeSlots: bestTimeSlots,
        bestDays: bestDays,
        consistencyScore: consistencyScore,
        lastUpdated: DateTime.now(),
      );

      // 분석 결과를 Firestore에 저장
      await _saveUserPattern(pattern);

      print(
          '✅ 사용자 패턴 분석 완료: 완료율 ${(overallCompletionRate * 100).toStringAsFixed(1)}%');
      return pattern;
    } catch (e, stackTrace) {
      print('❌ 사용자 패턴 분석 실패: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 습관 완료 데이터 수집
  Future<List<Map<String, dynamic>>> _getHabitCompletions(
      String uid, DateTime startDate, DateTime endDate) async {
    final querySnapshot = await _firestore
        .collection('habit_completions')
        .where('uid', isEqualTo: uid)
        .where('done', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: _formatDate(startDate))
        .where('date', isLessThanOrEqualTo: _formatDate(endDate))
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// 사용자 습관 목록 수집
  Future<List<Map<String, dynamic>>> _getUserHabits(String uid) async {
    final querySnapshot = await _firestore
        .collection('user_habits')
        .where('uid', isEqualTo: uid)
        .where('isActive', isEqualTo: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// 시간대별 성과 분석
  Map<int, double> _analyzeTimeBasedPerformance(
      List<Map<String, dynamic>> completions) {
    final timeCounts = <int, int>{};
    final timeTotal = <int, int>{};

    // 0-23시 초기화
    for (int hour = 0; hour < 24; hour++) {
      timeCounts[hour] = 0;
      timeTotal[hour] = 0;
    }

    for (final completion in completions) {
      final timestamp = completion['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final hour = timestamp.toDate().hour;
        timeCounts[hour] = (timeCounts[hour] ?? 0) + 1;
      }
    }

    // 각 시간대별 성과율 계산
    final performance = <int, double>{};
    for (int hour = 0; hour < 24; hour++) {
      final count = timeCounts[hour] ?? 0;
      final total = completions.length;
      performance[hour] = total > 0 ? count / total : 0.0;
    }

    return performance;
  }

  /// 요일별 성과 분석
  Map<int, double> _analyzeDayBasedPerformance(
      List<Map<String, dynamic>> completions) {
    final dayCounts = <int, int>{};

    // 1-7 (월-일) 초기화
    for (int day = 1; day <= 7; day++) {
      dayCounts[day] = 0;
    }

    for (final completion in completions) {
      final timestamp = completion['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final dayOfWeek = timestamp.toDate().weekday;
        dayCounts[dayOfWeek] = (dayCounts[dayOfWeek] ?? 0) + 1;
      }
    }

    // 각 요일별 성과율 계산
    final performance = <int, double>{};
    for (int day = 1; day <= 7; day++) {
      final count = dayCounts[day] ?? 0;
      final total = completions.length;
      performance[day] = total > 0 ? count / total : 0.0;
    }

    return performance;
  }

  /// 전체 완료율 계산
  double _calculateOverallCompletionRate(List<Map<String, dynamic>> completions,
      List<Map<String, dynamic>> habits) {
    if (habits.isEmpty) return 0.0;

    // 최근 30일 동안의 예상 완료 수 (습관 수 × 30일)
    final expectedCompletions = habits.length * 30;
    final actualCompletions = completions.length;

    return expectedCompletions > 0
        ? actualCompletions / expectedCompletions
        : 0.0;
  }

  /// 최적 시간대 찾기 (상위 3개)
  List<String> _findBestTimeSlots(Map<int, double> timePerformance) {
    final sortedTimes = timePerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTimes.take(3).map((entry) {
      final hour = entry.key;
      final percentage = (entry.value * 100).toStringAsFixed(1);
      return '$hour시 ($percentage%)';
    }).toList();
  }

  /// 최적 요일 찾기 (상위 3개)
  List<String> _findBestDays(Map<int, double> dayPerformance) {
    const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];

    final sortedDays = dayPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDays.take(3).map((entry) {
      final day = entry.key;
      final percentage = (entry.value * 100).toStringAsFixed(1);
      return '${dayNames[day]}요일 ($percentage%)';
    }).toList();
  }

  /// 일관성 점수 계산 (연속성과 규칙성 고려)
  double _calculateConsistencyScore(List<Map<String, dynamic>> completions) {
    if (completions.isEmpty) return 0.0;

    // 날짜별 완료 수 계산
    final dailyCompletions = <String, int>{};
    for (final completion in completions) {
      // date 필드를 안전하게 처리 (int, String 모두 지원)
      final dateValue = completion['date'];
      String? date;

      if (dateValue is String) {
        date = dateValue;
      } else if (dateValue is int) {
        // int인 경우 문자열로 변환 (예: 20240101)
        date = dateValue.toString();
      } else if (dateValue != null) {
        // 기타 타입인 경우 toString() 사용
        date = dateValue.toString();
      }

      if (date != null) {
        dailyCompletions[date] = (dailyCompletions[date] ?? 0) + 1;
      }
    }

    // 연속성 점수 (연속된 날의 비율)
    final dates = dailyCompletions.keys.toList()..sort();
    int consecutiveDays = 0;
    int maxConsecutive = 0;

    for (int i = 0; i < dates.length; i++) {
      if (i == 0 || _isConsecutiveDay(dates[i - 1], dates[i])) {
        consecutiveDays++;
        maxConsecutive =
            maxConsecutive > consecutiveDays ? maxConsecutive : consecutiveDays;
      } else {
        consecutiveDays = 1;
      }
    }

    // 규칙성 점수 (완료한 날의 비율)
    final totalDays = 30; // 분석 기간
    final completedDays = dailyCompletions.length;
    final regularityScore = completedDays / totalDays;

    // 연속성 점수 (최대 연속일 / 총 일수)
    final consistencyScore = maxConsecutive / totalDays;

    // 최종 점수 (규칙성 70% + 연속성 30%)
    return (regularityScore * 0.7) + (consistencyScore * 0.3);
  }

  /// 연속된 날인지 확인
  bool _isConsecutiveDay(String date1, String date2) {
    final d1 = DateTime.parse(date1);
    final d2 = DateTime.parse(date2);
    return d2.difference(d1).inDays == 1;
  }

  /// 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 사용자 패턴을 Firestore에 저장
  Future<void> _saveUserPattern(UserPattern pattern) async {
    await _firestore
        .collection('user_patterns')
        .doc(pattern.uid)
        .set(pattern.toMap());
  }

  /// 저장된 사용자 패턴 조회
  Future<UserPattern?> getUserPattern(String uid) async {
    try {
      final doc = await _firestore.collection('user_patterns').doc(uid).get();

      if (doc.exists) {
        return UserPattern.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 사용자 패턴 조회 실패: $e');
      return null;
    }
  }

  /// 시간대별 성과 데이터 조회
  Future<Map<int, double>> getTimeBasedPerformance(String uid) async {
    final pattern = await getUserPattern(uid);
    return pattern?.timeBasedPerformance ?? {};
  }

  /// 요일별 성과 데이터 조회
  Future<Map<int, double>> getDayBasedPerformance(String uid) async {
    final pattern = await getUserPattern(uid);
    return pattern?.dayBasedPerformance ?? {};
  }
}
