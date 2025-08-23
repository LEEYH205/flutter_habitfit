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
import 'pose_estimator.dart';
import 'pose_overlay.dart';

final _repProvider = StateProvider<int>((ref) => 0);
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

  @override
  void initState() {
    super.initState();
    _estimator = MoveNetPoseEstimator();
    _init();
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
  }

  void _start() {
    if (!(_controller?.value.isInitialized ?? false)) return;
    if (_isStreaming) return; // Don't start if already streaming

    _isStreaming = true;
    _controller!.startImageStream((img) async {
      if (_busy) return;
      _busy = true;
      try {
        final inc = _estimator.process(img);
        final angle = _estimator.lastAngle;
        if (angle != null && mounted) {
          ref.read(_angleProvider.notifier).state = angle;
        }
        if (inc > 0 && mounted) {
          final newReps = ref.read(_repProvider.notifier).state + 1;
          ref.read(_repProvider.notifier).state = newReps;
          print('💪 스쿼트 카운트 증가: $newReps회');

          // 실시간으로 목표 달성 확인
          _checkAndShowGoalAchievement(newReps);
        }
      } catch (e) {
        // ignore
      } finally {
        _busy = false;
        if (mounted) setState(() {}); // 오버레이 갱신
      }
    });
  }

  // 실시간 목표 달성 확인 및 알림
  Future<void> _checkAndShowGoalAchievement(int reps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailySquatGoal = prefs.getInt('dailySquatGoal') ?? 20;
      final goalAchievementEnabled =
          prefs.getBool('goalAchievementEnabled') ?? true;

      if (reps >= dailySquatGoal && goalAchievementEnabled) {
        print('🎯 목표 $dailySquatGoal회 달성! 축하 알림 전송 시도...');

        // 로컬 알림 전송
        await LocalNotificationService.instance
            .showGoalAchievementNotification('스쿼트', reps);
        print('🎯 실시간 목표 달성 축하 알림 전송 성공: $reps/$dailySquatGoal회');

        // 화면에 축하 메시지 표시
        if (mounted) {
          _showGoalAchievementOverlay(reps, dailySquatGoal);
        }
      }
    } catch (e) {
      print('❌ 실시간 목표 달성 알림 전송 실패: $e');
    }
  }

  // 화면에 축하 메시지 오버레이 표시
  void _showGoalAchievementOverlay(int reps, int goal) {
    setState(() {
      _showGoalAchievement = true;
      _goalAchievementText = '🎯 목표 달성!\n$reps/$goal회 완료!';
    });

    // 3초 후 자동으로 숨기기
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showGoalAchievement = false;
        });
      }
    });
  }

  // 실시간 목표 달성 알림
  Future<void> _showGoalAchievementNotification(int reps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalAchievementEnabled =
          prefs.getBool('goalAchievementEnabled') ?? true;

      if (goalAchievementEnabled) {
        await LocalNotificationService.instance
            .showGoalAchievementNotification('스쿼트', reps);
        print('🎯 실시간 목표 달성 축하 알림 전송 성공: $reps회');
      }
    } catch (e) {
      print('❌ 실시간 목표 달성 알림 전송 실패: $e');
    }
  }

  void _stop() async {
    try {
      await _controller?.stopImageStream();
      _isStreaming = false; // Reset streaming state

      // 운동 완료 시 자동 알림 전송
      final reps = ref.read(_repProvider);
      print('🛑 운동 중지: 총 $reps회 완료');

      if (reps > 0) {
        print('📝 운동 기록 저장 및 알림 전송 시작...');

        // Firestore에 운동 기록 저장
        try {
          final today = DateTime.now();
          final dateId =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          print('💾 Firestore에 저장 중: $dateId, $reps회');
          await FirebaseFirestore.instance.collection('workouts').add({
            'date': dateId,
            'reps': reps,
            'exerciseType': '스쿼트',
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Firestore 저장 성공');

          // 설정 확인 후 알림 전송
          final prefs = await SharedPreferences.getInstance();
          final workoutNotificationsEnabled =
              prefs.getBool('workoutNotificationsEnabled') ?? true;
          final goalAchievementEnabled =
              prefs.getBool('goalAchievementEnabled') ?? true;
          final dailySquatGoal = prefs.getInt('dailySquatGoal') ?? 20;

          print(
              '⚙️ 설정 확인: 운동알림=$workoutNotificationsEnabled, 목표알림=$goalAchievementEnabled, 목표=$dailySquatGoal회');

          if (workoutNotificationsEnabled) {
            print('🔔 운동 완료 알림 전송 시도...');
            await LocalNotificationService.instance
                .showWorkoutCompletionNotification(reps, '스쿼트');
            print('💪 운동 완료 알림 자동 전송: 스쿼트 $reps회');
          } else {
            print('⚠️ 운동 완료 알림이 비활성화되어 있습니다');
          }

          // 목표 달성 확인 및 축하 알림
          if (reps >= dailySquatGoal && goalAchievementEnabled) {
            print('🎯 목표 달성 축하 알림 전송 시도...');
            await LocalNotificationService.instance
                .showGoalAchievementNotification('스쿼트', reps);
            print('🎯 목표 달성 축하 알림 자동 전송: $reps/$dailySquatGoal');
          } else if (reps >= dailySquatGoal) {
            print('⚠️ 목표 달성했지만 축하 알림이 비활성화되어 있습니다');
          } else {
            print('📊 목표 미달성: $reps/$dailySquatGoal');
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
    final reps = ref.watch(_repProvider);
    final angle = ref.watch(_angleProvider);
    final kps = _estimator.lastKeypoints;

    // 스쿼트 단계와 카운트 정보 가져오기
    String squatPhase = 'idle';
    int squatCount = reps;

    // MoveNet 포즈 추정기에서 스쿼트 단계 정보 가져오기
    if (_estimator is MoveNetPoseEstimator) {
      final moveNetEstimator = _estimator as MoveNetPoseEstimator;
      squatPhase = moveNetEstimator.squatPhase;
      squatCount = moveNetEstimator.repCount;
    }

    Widget preview = _controller?.value.isInitialized == true
        ? CameraPreview(_controller!)
        : const Center(child: CircularProgressIndicator());

    if (_controller?.value.isInitialized == true) {
      preview = AspectRatio(
        aspectRatio: _aspectRatioOverride ?? (_controller!.value.aspectRatio),
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
                  squatCount: squatCount,
                  screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                );
              },
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: preview),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Reps: $reps',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('Angle: ${angle?.toStringAsFixed(1) ?? "-"}°'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                    await Fs.instance.addWorkout(uid, DateTime.now(), reps);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('운동 저장됨')));
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  '※ Remote Config로 임계값/스무딩 조절. 모델 파일은 assets/models/에 *.tflite',
                  style: TextStyle(color: Colors.grey)),
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
    );
  }
}
