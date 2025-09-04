import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/services/firestore_service.dart';
import '../../common/services/remote_config_service.dart';
import '../../common/services/local_notification_service.dart';
import '../../widgets/app_bar_with_notifications.dart';
import 'pose_estimator.dart';
import 'pose_overlay.dart';
import 'pushup_detector.dart';

// 운동별 독립 카운터
final _squatCountProvider = StateProvider<int>((ref) => 0);
final _pushupCountProvider = StateProvider<int>((ref) => 0);
final _angleProvider = StateProvider<double?>((ref) => null);

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  CameraController? _controller;
  late PoseEstimator _estimator;
  bool _busy = false;
  bool _isStreaming = false; // Add streaming state tracking
  double? _aspectRatioOverride; // 프리뷰 비율 유지

  // 목표 달성 축하 메시지 관련 변수
  bool _showGoalAchievement = false;
  String _goalAchievementText = '';

  // 운동 타입 선택
  String _selectedExercise = 'squat';
  late PushUpDetector _pushUpDetector;

  // FPS 제한을 위한 변수
  DateTime? _lastProcessTime;
  static const Duration minProcessInterval =
      Duration(milliseconds: 100); // 10 FPS

  // 운동 타입별 설정
  final Map<String, Map<String, dynamic>> _exerciseSettings = {
    'squat': {
      'name': '스쿼트',
      'goal': 20,
      'description': '무릎 각도 기반 스쿼트 감지',
    },
    'pushup': {
      'name': '푸시업',
      'goal': 15,
      'description': '팔꿈치 각도 기반 푸시업 감지',
    },
  };

  @override
  void initState() {
    super.initState();
    _estimator = MoveNetPoseEstimator();
    _pushUpDetector = PushUpDetector();

    // 푸시업 완료 시 목표 달성 체크를 위한 콜백 설정
    _pushUpDetector.onRepCompleted = (int repCount) {
      if (mounted) {
        _checkGoalAchievement(repCount);
      }
    };

    _init();
    _loadUserGoals(); // 사용자 목표 설정 로드
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        // Simulator에서는 카메라가 없을 수 있음
        return;
      }
      final cam = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cams.first);
      _controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
    } catch (e) {
      // Simulator에서는 카메라 초기화 실패할 수 있음
      print('Camera initialization failed: $e');
      return;
    }

    // 포즈 추정기 로드
    await _estimator.load();
    if (!mounted) return;
    setState(() {
      _aspectRatioOverride = _controller!.value.previewSize != null
          ? _controller!.value.previewSize!.width /
              _controller!.value.previewSize!.height
          : null;
    });

    // 자동으로 운동 감지 시작
    _start();
  }

  void _start() {
    if (!(_controller?.value.isInitialized ?? false)) return;
    if (_isStreaming) return; // Don't start if already streaming

    _isStreaming = true;
    _controller!.startImageStream((img) async {
      // FPS 제한 적용 (10 FPS)
      final now = DateTime.now();
      if (_lastProcessTime != null &&
          now.difference(_lastProcessTime!) < minProcessInterval) {
        return; // 너무 빠른 처리 방지
      }
      _lastProcessTime = now;

      if (_busy) return;
      _busy = true;
      try {
        int inc = 0;
        double? angle;

        // MoveNet은 항상 실행하여 키포인트 생성 (UI 표시용)
        final keypoints = _estimator.process(img);

        if (_selectedExercise == 'squat') {
          // 스쿼트 감지
          inc = keypoints;
          angle = _estimator.lastAngle;
        } else if (_selectedExercise == 'pushup') {
          // 푸시업 감지 (MoveNet 키포인트 사용)
          if (_estimator.lastKeypoints != null) {
            inc = _pushUpDetector.detectPushUp(_estimator.lastKeypoints!);
            angle = _pushUpDetector.lastAngle;

            // 푸시업 디버그 로그
            if (angle != null) {
              print(
                  '🤸 PushUp: angle=${angle.toStringAsFixed(1)}°, phase=${_pushUpDetector.pushUpPhase}, count=${_pushUpDetector.repCount}');
            }
          }
        }

        if (angle != null && mounted) {
          ref.read(_angleProvider.notifier).state = angle;
        }

        if (inc > 0 && mounted) {
          // 운동별로 적절한 카운터 증가
          int newReps;
          if (_selectedExercise == 'squat') {
            newReps = ref.read(_squatCountProvider.notifier).state + 1;
            ref.read(_squatCountProvider.notifier).state = newReps;
          } else {
            newReps = ref.read(_pushupCountProvider.notifier).state + 1;
            ref.read(_pushupCountProvider.notifier).state = newReps;
          }

          final exerciseName = _exerciseSettings[_selectedExercise]!['name'];
          print('💪 $exerciseName 카운트 증가: $newReps회');

          // 실시간으로 목표 달성 확인
          _checkGoalAchievement(newReps);
        }
      } catch (e) {
        print('운동 감지 오류: $e');
      } finally {
        _busy = false;
        if (mounted) setState(() {}); // 오버레이 갱신
      }
    });
  }

  // 목표 달성 감지 및 축하 메시지 표시
  void _checkGoalAchievement(int currentCount) {
    final goal = _exerciseSettings[_selectedExercise]?['goal'] as int? ?? 0;

    print(
        '🎯 목표 달성 체크: 현재=$currentCount회, 목표=$goal회, 운동=${_exerciseSettings[_selectedExercise]?['name']}');
    print('🎯 오버레이 상태: $_showGoalAchievement');

    if (currentCount >= goal && !_showGoalAchievement) {
      print('🎉 목표 달성! 오버레이 표시 시작');

      setState(() {
        _showGoalAchievement = true;
        _goalAchievementText =
            '🎉 목표 달성! ${_exerciseSettings[_selectedExercise]?['name']} $goal회 완료! 🎉';
      });

      // 3초 후 축하 메시지 숨기기
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showGoalAchievement = false;
          });
          print('🎯 오버레이 3초 후 자동 숨김');
        }
      });

      // 목표 달성 알림 전송
      _showGoalAchievementNotification(currentCount);
    } else {
      print(
          '🎯 목표 달성 조건 불충족: currentCount >= goal = ${currentCount >= goal}, !_showGoalAchievement = ${!_showGoalAchievement}');
    }
  }

  // 실시간 목표 달성 알림
  Future<void> _showGoalAchievementNotification(int reps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalAchievementEnabled =
          prefs.getBool('goalAchievementEnabled') ?? true;

      if (goalAchievementEnabled) {
        await LocalNotificationService.instance.showGoalAchievementNotification(
            _exerciseSettings[_selectedExercise]?['name'] ?? '운동', reps);
        print('🎯 실시간 목표 달성 축하 알림 전송 성공: $reps회');
      }
    } catch (e) {
      print('❌ 실시간 목표 달성 축하 알림 전송 실패: $e');
    }
  }

  void _stop() async {
    try {
      await _controller?.stopImageStream();
      _isStreaming = false; // Reset streaming state

      // 현재 선택된 운동의 카운터 가져오기
      final reps = _selectedExercise == 'squat'
          ? ref.read(_squatCountProvider)
          : ref.read(_pushupCountProvider);
      final exerciseName = _exerciseSettings[_selectedExercise]!['name'];
      print('🛑 운동 중지: $exerciseName $reps회 완료');

      if (reps > 0) {
        print('📝 운동 기록 저장 및 알림 전송 시작...');

        // Firestore에 운동 기록 저장
        try {
          final today = DateTime.now();
          final dateId =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          // 현재 사용자 UID 가져오기
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';

          print(
              '💾 Firestore에 저장 중: $dateId, $reps회, $exerciseName, uid: $uid');
          await FirebaseFirestore.instance.collection('workouts').add({
            'uid': uid,
            'date': dateId,
            'reps': reps,
            'exerciseType': exerciseName,
            'exerciseCategory': _selectedExercise, // 'squat' 또는 'pushup'
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Firestore 저장 성공');

          // 설정 확인 후 알림 전송
          final prefs = await SharedPreferences.getInstance();
          final workoutNotificationsEnabled =
              prefs.getBool('workoutNotificationsEnabled') ?? true;
          final goalAchievementEnabled =
              prefs.getBool('goalAchievementEnabled') ?? true;
          final exerciseGoal =
              _exerciseSettings[_selectedExercise]!['goal'] as int;

          print(
              '⚙️ 설정 확인: 운동알림=$workoutNotificationsEnabled, 목표알림=$goalAchievementEnabled, 목표=$exerciseGoal회');

          if (workoutNotificationsEnabled) {
            print('🔔 운동 완료 알림 전송 시도...');
            await LocalNotificationService.instance
                .showWorkoutCompletionNotification(reps, exerciseName);
            print('💪 운동 완료 알림 자동 전송: $exerciseName $reps회');
          } else {
            print('⚠️ 운동 완료 알림이 비활성화되어 있습니다');
          }

          // 목표 달성 확인 및 축하 알림
          if (reps >= exerciseGoal && goalAchievementEnabled) {
            print('🎯 목표 달성 축하 알림 전송 시도...');
            await LocalNotificationService.instance
                .showGoalAchievementNotification(exerciseName, reps);
            print('🎯 목표 달성 축하 알림 자동 전송: $reps/$exerciseGoal');
          } else if (reps >= exerciseGoal) {
            print('⚠️ 목표 달성했지만 축하 알림이 비활성화되어 있습니다');
          } else {
            print('📊 목표 미달성: $reps/$exerciseGoal');
          }
        } catch (e) {
          print('❌ 운동 기록 저장 또는 알림 전송 실패: $e');
          print('❌ 오류 상세: ${StackTrace.current}');
        }
      } else {
        print('⚠️ 운동 횟수가 0회입니다. 알림을 보내지 않습니다.');
      }
    } catch (_) {}
  }

  // 사용자 설정에서 목표값 가져오기
  Future<void> _loadUserGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final squatGoal = prefs.getInt('dailySquatGoal') ?? 20;
      final pushupGoal = prefs.getInt('dailyPushupGoal') ?? 15;

      setState(() {
        _exerciseSettings['squat']!['goal'] = squatGoal;
        _exerciseSettings['pushup']!['goal'] = pushupGoal;
      });

      print('🎯 사용자 목표 설정 로드: 스쿼트 $squatGoal회, 푸시업 $pushupGoal회');
    } catch (e) {
      print('❌ 사용자 목표 설정 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    _stop();
    _isStreaming = false; // Ensure streaming state is reset
    _controller?.dispose();
    _estimator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 운동별 독립적인 카운터 사용
    final squatCount = ref.watch(_squatCountProvider);
    final pushupCount = ref.watch(_pushupCountProvider);
    final currentCount =
        _selectedExercise == 'squat' ? squatCount : pushupCount;
    final angle = ref.watch(_angleProvider);
    final kps = _estimator.lastKeypoints;

    // 스쿼트 단계와 카운트 정보 가져오기
    String squatPhase = 'idle';
    int displayCount = currentCount;

    // MoveNet 포즈 추정기에서 스쿼트 단계 정보 가져오기
    if (_estimator is MoveNetPoseEstimator) {
      final moveNetEstimator = _estimator as MoveNetPoseEstimator;
      squatPhase = moveNetEstimator.squatPhase;
      // squatCount는 이미 위에서 정의되었으므로 사용하지 않음
    }

    Widget preview = _controller?.value.isInitialized == true
        ? CameraPreview(_controller!)
        : const Center(child: CircularProgressIndicator());

    if (_controller?.value.isInitialized == true) {
      // 카메라 비율을 더 안정적으로 설정
      final targetAspectRatio = _aspectRatioOverride ??
          (_controller!.value.previewSize != null
              ? _controller!.value.previewSize!.width /
                  _controller!.value.previewSize!.height
              : 16.0 / 9.0);

      preview = AspectRatio(
        aspectRatio: targetAspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            // 새로운 PoseOverlay 위젯 사용
            LayoutBuilder(
              builder: (context, constraints) {
                return PoseOverlay(
                  keypoints: kps,
                  kneeAngle: angle,
                  squatPhase: squatPhase,
                  squatCount: displayCount,
                  screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                  exerciseType: _selectedExercise,
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWithNotifications(
        title: '운동 관리',
        showNotifications: true,
        showProfile: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 운동 타입 선택
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('운동 타입: '),
                    DropdownButton<String>(
                      value: _selectedExercise,
                      items: _exerciseSettings.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(_exerciseSettings[key]!['name']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedExercise = newValue;
                            if (_selectedExercise == 'pushup') {
                              _pushUpDetector.reset();
                            }
                          });
                          _loadUserGoals();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: preview),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Reps: $currentCount',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('Angle: ${angle?.toStringAsFixed(1) ?? "-"}°'),
                ],
              ),
            ],
          ),

          // 목표 달성 축하 메시지 오버레이
          if (_showGoalAchievement)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _goalAchievementText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
