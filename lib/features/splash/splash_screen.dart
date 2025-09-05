import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:health/health.dart';
import '../../common/services/fcm_service.dart';
import '../../common/services/local_notification_service.dart';
import '../../common/services/remote_config_service.dart';

/// 앱 시작 시 로딩 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _loadingMessage = '앱을 시작하는 중...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    // 애니메이션 초기화
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // 초기화 시작
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 앱 초기화 진행
  Future<void> _initializeApp() async {
    try {
      await _animationController.forward();

      // 1. 날짜 포맷팅 초기화
      setState(() {
        _loadingMessage = '날짜 설정을 초기화하는 중...';
        _progress = 0.1;
      });
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. FCM 초기화 (실제 기기에서만)
      setState(() {
        _loadingMessage = '푸시 알림을 설정하는 중...';
        _progress = 0.3;
      });

      try {
        if (!Platform.isIOS || !await _isSimulator()) {
          await FcmService.instance.init();
          print('✅ FCM 초기화 성공');
        } else {
          print('📱 시뮬레이터에서는 FCM 생략');
        }
      } catch (e) {
        print('⚠️ FCM 초기화 실패: $e');
      }

      // 3. Remote Config 초기화
      setState(() {
        _loadingMessage = '앱 설정을 불러오는 중...';
        _progress = 0.5;
      });

      try {
        await RemoteConfigService.instance.init();
        print('✅ Remote Config 초기화 성공');
      } catch (e) {
        print('⚠️ Remote Config 초기화 실패: $e');
      }

      // 4. 로컬 알림 서비스 초기화
      setState(() {
        _loadingMessage = '알림 서비스를 설정하는 중...';
        _progress = 0.7;
      });

      try {
        await LocalNotificationService.instance.init();
        print('✅ 로컬 알림 서비스 초기화 성공');
      } catch (e) {
        print('⚠️ 로컬 알림 서비스 초기화 실패: $e');
      }

      // 5. HealthKit 초기화 (iOS에서만)
      if (Platform.isIOS) {
        setState(() {
          _loadingMessage = '건강 데이터를 불러오는 중...';
          _progress = 0.9;
        });

        try {
          await _initializeHealthKit();
        } catch (e) {
          print('⚠️ HealthKit 초기화 실패: $e');
        }
      }

      // 초기화 완료
      setState(() {
        _loadingMessage = '준비 완료!';
        _progress = 1.0;
      });

      // 잠시 대기 후 메인 앱으로 전환
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      print('❌ 앱 초기화 실패: $e');
      setState(() {
        _loadingMessage = '초기화 실패. 다시 시도해주세요.';
      });
    }
  }

  /// HealthKit 초기화
  Future<void> _initializeHealthKit() async {
    try {
      final health = HealthFactory();

      // 앱 시작 시 필요한 모든 권한 요청
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.WORKOUT,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME,
      ];

      final granted = await health.requestAuthorization(types);
      if (granted) {
        print('✅ HealthKit 권한 승인됨');
      } else {
        print('⚠️ HealthKit 권한 거부됨');
      }
    } catch (e) {
      print('❌ HealthKit 초기화 오류: $e');
    }
  }

  /// iOS 시뮬레이터인지 확인
  Future<bool> _isSimulator() async {
    try {
      final result = await Process.run('xcrun', ['simctl', 'list', 'devices']);
      return result.stdout.toString().contains('Simulator');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Pink
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 로고/아이콘
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 앱 이름
                    const Text(
                      'HabitFit',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 태그라인
                    Text(
                      '건강한 습관, 더 나은 삶',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // 로딩 메시지
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // 프로그레스 바
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 로딩 인디케이터
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
