
import 'package:flutter/material.dart';

class PoseOverlay extends CustomPainter {
  final List<Map<String, double>>? kps; // 17 keypoints with x, y, confidence
  PoseOverlay(this.kps);

  static const List<List<int>> edges = [
    // 간단 COCO 연결
    [5, 7], [7, 9],     // Left arm
    [6, 8], [8,10],     // Right arm
    [11,13], [13,15],   // Left leg
    [12,14], [14,16],   // Right leg
    [5,6], [11,12],     // shoulders, hips
    [5,11], [6,12],     // torso diagonals
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (kps == null) return;
    final paintL = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0;
    final paintP = Paint()..style = PaintingStyle.fill..strokeWidth = 2.0;

    // 점
    for (int i = 0; i < kps!.length; i++) {
      final keypoint = kps![i];
      final confidence = keypoint['confidence'] ?? 0.0;
      if (confidence < 0.3) continue;
      
      final x = keypoint['x'] ?? 0.0;
      final y = keypoint['y'] ?? 0.0;
      
      final dx = x * size.width;
      final dy = y * size.height;
      canvas.drawCircle(Offset(dx, dy), 3.5, paintP);
    }
    
    // 선
    for (final e in edges) {
      final a = e[0], b = e[1];
      if (a >= kps!.length || b >= kps!.length) continue;
      
      final confidenceA = kps![a]['confidence'] ?? 0.0;
      final confidenceB = kps![b]['confidence'] ?? 0.0;
      
      if (confidenceA < 0.3 || confidenceB < 0.3) continue;
      
      final ax = (kps![a]['x'] ?? 0.0) * size.width;
      final ay = (kps![a]['y'] ?? 0.0) * size.height;
      final bx = (kps![b]['x'] ?? 0.0) * size.width;
      final by = (kps![b]['y'] ?? 0.0) * size.height;
      
      canvas.drawLine(Offset(ax, ay), Offset(bx, by), paintL);
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlay oldDelegate) {
    return oldDelegate.kps != kps;
  }
}
