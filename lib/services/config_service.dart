import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase 설정 관리 서비스
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 캐시된 설정 값들
  Map<String, dynamic>? _cachedConfig;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// 설정 값 가져오기
  Future<Map<String, dynamic>> getConfig() async {
    // 캐시가 유효한 경우 캐시된 값 반환
    if (_cachedConfig != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
      return _cachedConfig!;
    }

    try {
      final doc =
          await _firestore.collection('app_config').doc('game_settings').get();

      if (doc.exists) {
        _cachedConfig = doc.data()!;
        _lastFetch = DateTime.now();
        return _cachedConfig!;
      } else {
        // 기본 설정 생성
        return await _createDefaultConfig();
      }
    } catch (e) {
      print('❌ 설정 조회 오류: $e');
      // 오류 시 기본 설정 반환
      return _getDefaultConfig();
    }
  }

  /// 기본 설정 생성
  Future<Map<String, dynamic>> _createDefaultConfig() async {
    try {
      final defaultConfig = _getDefaultConfig();

      await _firestore
          .collection('app_config')
          .doc('game_settings')
          .set(defaultConfig);

      _cachedConfig = defaultConfig;
      _lastFetch = DateTime.now();

      print('✅ 기본 설정 생성 완료');
      return defaultConfig;
    } catch (e) {
      print('❌ 기본 설정 생성 오류: $e');
      return _getDefaultConfig();
    }
  }

  /// 기본 설정 값들
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'points': {
        'habitCompleted': 10,
        'workoutCompleted': 20,
        'streakAchieved': 15,
        'goalAchieved': 50,
        'dailyChallenge': 30,
        'weeklyChallenge': 100,
        'monthlyChallenge': 200,
        'socialShare': 5,
        'reviewWritten': 25,
        'friendInvited': 100,
        'achievementUnlocked': 75,
        'streakBonus': 5, // 연속일수당 보너스
        'firstTimeBonus': 20, // 첫 완료 보너스
        'levelUpBonus': 100, // 레벨업당 보너스
      },
      'levels': {
        'basePoints': 100,
        'multiplier': 1.2,
      },
      'achievements': {
        'level_5': {
          'points': 50,
          'title': '첫 번째 레벨업',
          'description': '레벨 5 달성',
          'icon': '🎯'
        },
        'level_10': {
          'points': 100,
          'title': '습관러',
          'description': '레벨 10 달성',
          'icon': '🌿'
        },
        'level_20': {
          'points': 200,
          'title': '달성자',
          'description': '레벨 20 달성',
          'icon': '🌳'
        },
        'level_30': {
          'points': 300,
          'title': '마스터',
          'description': '레벨 30 달성',
          'icon': '🏆'
        },
        'points_1000': {
          'points': 100,
          'title': '첫 1000점',
          'description': '1000 포인트 달성',
          'icon': '💯'
        },
        'points_5000': {
          'points': 200,
          'title': '포인트 마스터',
          'description': '5000 포인트 달성',
          'icon': '💰'
        },
        'points_10000': {
          'points': 500,
          'title': '포인트 레전드',
          'description': '10000 포인트 달성',
          'icon': '💎'
        },
      },
    };
  }

  /// 특정 포인트 타입의 기본 포인트 가져오기
  Future<int> getPointsForType(String type) async {
    final config = await getConfig();
    return config['points']?[type] ?? 0;
  }

  /// 업적 정보 가져오기
  Future<Map<String, dynamic>?> getAchievementConfig(
      String achievementId) async {
    final config = await getConfig();
    return config['achievements']?[achievementId];
  }

  /// 레벨 설정 가져오기
  Future<Map<String, dynamic>> getLevelConfig() async {
    final config = await getConfig();
    return config['levels'] ?? {'basePoints': 100, 'multiplier': 1.2};
  }

  /// 캐시 무효화
  void invalidateCache() {
    _cachedConfig = null;
    _lastFetch = null;
  }

  /// 앱 시작 시 초기화
  static Future<void> initialize() async {
    try {
      // ConfigService 인스턴스 생성 및 초기 설정 로드
      final instance = ConfigService();
      await instance.getConfig();
      print('✅ ConfigService 초기화 완료');
    } catch (e) {
      print('❌ ConfigService 초기화 실패: $e');
      // 초기화 실패해도 앱은 계속 실행되도록 함
    }
  }

  /// 디스코드 웹훅 URL 가져오기 (정적 메서드)
  static String getDiscordWebhookUrl() {
    // 실제 프로덕션에서는 환경변수나 보안 저장소에서 가져와야 함
    // 현재는 기본값 반환
    return '';
  }

  /// 웹훅 설정 여부 확인 (정적 메서드)
  static bool isWebhookConfigured() {
    return getDiscordWebhookUrl().isNotEmpty;
  }
}
