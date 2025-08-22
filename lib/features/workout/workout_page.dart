import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/services/firestore_service.dart';
import '../../common/services/remote_config_service.dart';
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
          ref.read(_repProvider.notifier).state++;
        }
      } catch (e) {
        // ignore
      } finally {
        _busy = false;
        if (mounted) setState(() {}); // 오버레이 갱신
      }
    });
  }

  void _stop() async {
    try {
      await _controller?.stopImageStream();
      _isStreaming = false; // Reset streaming state
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
            CustomPaint(painter: PoseOverlay(kps)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: preview),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Reps: $reps',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                await Fs.instance.addWorkout(uid, DateTime.now(), reps);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('운동 저장됨')));
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
              '※ Remote Config로 임계값/스무딩 조절. 모델 파일은 assets/models/movenet.tflite 로 교체하세요.',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
