import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 포즈 오버레이 위젯 - 실시간 키포인트 시각화
class PoseOverlay extends StatelessWidget {
  final List<Map<String, double>>? keypoints;
  final double? kneeAngle;
  final String squatPhase;
  final int squatCount;
  final Size screenSize;
  final String exerciseType; // 새로 추가

  const PoseOverlay({
    super.key,
    required this.keypoints,
    required this.kneeAngle,
    required this.squatPhase,
    required this.squatCount,
    required this.screenSize,
    this.exerciseType = 'squat', // 기본값
  });

  @override
  Widget build(BuildContext context) {
    if (keypoints == null || keypoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 키포인트 점들
        ..._buildKeypoints(),

        // 스켈레톤 연결선
        ..._buildSkeletonLines(),

        // 자세 상태 표시
        _buildPoseStatus(),

        // 운동 카운트
        _buildExerciseCount(),

        // 디버깅 정보 (개발 중에만)
        if (keypoints!.isNotEmpty) _buildDebugInfo(),
      ],
    );
  }

  /// 키포인트 점들 생성
  List<Widget> _buildKeypoints() {
    final List<Widget> widgets = [];

    for (int i = 0; i < keypoints!.length; i++) {
      final kp = keypoints![i];
      final confidence = kp['confidence'] ?? 0.0;

      if (confidence > 0.1) {
        // 신뢰도가 낮은 점은 표시하지 않음
        final x = kp['x'] ?? 0.0;
        final y = kp['y'] ?? 0.0;

        // 기기별 좌표계 조정
        final adjustedCoords = _adjustCoordinatesForDevice(x, y);
        final screenX = adjustedCoords.dx;
        final screenY = adjustedCoords.dy;

        // 신뢰도에 따른 색상
        final color = _getConfidenceColor(confidence);

        widgets.add(
          Positioned(
            left: screenX - 4,
            top: screenY - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// 기기별 좌표계 조정 메서드
  Offset _adjustCoordinatesForDevice(double x, double y) {
    // 기본 좌표계 (0.0~1.0 → 픽셀)
    double screenX = x * screenSize.width;
    double screenY = y * screenSize.height;

    // 기기별 특수 조정
    if (screenSize.width > 1000) {
      // 고해상도 기기 (Android 대부분)
      // Y축 미세 조정 (Android 카메라 좌표계 차이)
      screenY = screenY * 0.95 + screenSize.height * 0.025;

      // X축 미세 조정 (Android 화면 비율 차이)
      screenX = screenX * 0.98 + screenSize.width * 0.01;
    } else {
      // iOS 기기 (기본값 유지)
      // 추가 조정 불필요
    }

    // 화면 경계 체크
    screenX = screenX.clamp(0.0, screenSize.width);
    screenY = screenY.clamp(0.0, screenSize.height);

    return Offset(screenX, screenY);
  }

  /// 스켈레톤 연결선 생성 (수정된 버전)
  List<Widget> _buildSkeletonLines() {
    final List<Widget> widgets = [];

    // MoveNet 키포인트 인덱스 (COCO 17 포인트 형식)
    // 0: nose, 1: left_eye, 2: right_eye, 3: left_ear, 4: right_ear
    // 5: left_shoulder, 6: right_shoulder, 7: left_elbow, 8: right_elbow
    // 9: left_wrist, 10: right_wrist, 11: left_hip, 12: right_hip
    // 13: left_knee, 14: right_knee, 15: left_ankle, 16: right_ankle
    final connections = [
      // 머리
      [1, 3], [2, 4], // 눈-귀

      // 상체
      [5, 6], // 어깨-어깨
      [5, 7], [7, 9], // 왼쪽 팔 (어깨-팔꿈치-손목)
      [6, 8], [8, 10], // 오른쪽 팔 (어깨-팔꿈치-손목)

      // 몸통
      [5, 11], [6, 12], // 어깨-고관절
      [11, 12], // 고관절-고관절

      // 하체
      [11, 13], [13, 15], // 왼쪽 다리 (고관절-무릎-발목)
      [12, 14], [14, 16], // 오른쪽 다리 (고관절-무릎-발목)
    ];

    for (final connection in connections) {
      final startIdx = connection[0];
      final endIdx = connection[1];

      // 인덱스 범위 체크
      if (startIdx >= keypoints!.length || endIdx >= keypoints!.length) {
        continue;
      }

      final start = keypoints![startIdx];
      final end = keypoints![endIdx];

      final startConf = start['confidence'] ?? 0.0;
      final endConf = end['confidence'] ?? 0.0;

      // 양쪽 끝점의 신뢰도가 모두 높을 때만 선 표시
      if (startConf > 0.2 && endConf > 0.2) {
        final startX = start['x'] ?? 0.0;
        final startY = start['y'] ?? 0.0;
        final endX = end['x'] ?? 0.0;
        final endY = end['y'] ?? 0.0;

        // 기기별 좌표계 조정
        final startCoords = _adjustCoordinatesForDevice(startX, startY);
        final endCoords = _adjustCoordinatesForDevice(endX, endY);

        final screenStartX = startCoords.dx;
        final screenStartY = startCoords.dy;
        final screenEndX = endCoords.dx;
        final screenEndY = endCoords.dy;

        // 선의 길이와 각도 계산
        final dx = screenEndX - screenStartX;
        final dy = screenEndY - screenStartY;
        final length = math.sqrt(dx * dx + dy * dy);

        // 선이 너무 짧으면 건너뛰기
        if (length < 5.0) continue;

        final angle = math.atan2(dy, dx);

        // 평균 신뢰도에 따른 색상
        final avgConf = (startConf + endConf) / 2;
        final color = _getConfidenceColor(avgConf);

        // CustomPaint를 사용한 선 그리기 (더 정확함)
        widgets.add(
          Positioned(
            left: 0,
            top: 0,
            child: CustomPaint(
              size: screenSize,
              painter: SkeletonLinePainter(
                start: Offset(screenStartX, screenStartY),
                end: Offset(screenEndX, screenEndY),
                color: color,
                strokeWidth: 2.0,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// 자세 상태 표시
  Widget _buildPoseStatus() {
    return Positioned(
      top: 50,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getPhaseColor().withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPhaseIcon(),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _getPhaseText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 운동 카운트 표시
  Widget _buildExerciseCount() {
    final exerciseLabel = exerciseType == 'pushup' ? 'PUSHUPS' : 'SQUATS';
    final exerciseColor =
        exerciseType == 'pushup' ? Colors.orange : Colors.blue;

    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: exerciseColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              exerciseLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              '$squatCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 디버깅 정보 (개발 중에만)
  Widget _buildDebugInfo() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Screen: ${screenSize.width.toInt()}x${screenSize.height.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Keypoints: ${keypoints!.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (keypoints!.isNotEmpty) ...[
              Text(
                'Nose: (${(keypoints![0]['x'] ?? 0).toStringAsFixed(2)}, ${(keypoints![0]['y'] ?? 0).toStringAsFixed(2)})',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                'L Hip: (${(keypoints![11]['x'] ?? 0).toStringAsFixed(2)}, ${(keypoints![11]['y'] ?? 0).toStringAsFixed(2)})',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 신뢰도에 따른 색상 반환
  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  /// 스쿼트 단계에 따른 색상 반환
  Color _getPhaseColor() {
    switch (squatPhase) {
      case 'idle':
        return Colors.grey;
      case 'down':
        return Colors.orange;
      case 'up':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 스쿼트 단계에 따른 아이콘 반환
  IconData _getPhaseIcon() {
    switch (squatPhase) {
      case 'idle':
        return Icons.accessibility_new;
      case 'down':
        return Icons.keyboard_arrow_down;
      case 'up':
        return Icons.keyboard_arrow_up;
      default:
        return Icons.accessibility_new;
    }
  }

  /// 스쿼트 단계에 따른 텍스트 반환
  String _getPhaseText() {
    switch (squatPhase) {
      case 'idle':
        return '준비';
      case 'down':
        return '내려가기';
      case 'up':
        return '올라오기';
      default:
        return '준비';
    }
  }
}

/// 스켈레톤 선을 그리는 CustomPainter
class SkeletonLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  SkeletonLinePainter({
    required this.start,
    required this.end,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
