
import 'package:flutter/material.dart';

class PoseOverlay extends CustomPainter {
  final List<List<double>>? kps; // 17x3 (y,x,score) normalized 0..1
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
      final s = kps![i][2];
      if (s < 0.3) continue;
      final dx = kps![i][1] * size.width;
      final dy = kps![i][0] * size.height;
      canvas.drawCircle(Offset(dx, dy), 3.5, paintP);
    }
    // 선
    for (final e in edges) {
      final a = e[0], b = e[1];
      if (kps![a][2] < 0.3 || kps![b][2] < 0.3) continue;
      final ax = kps![a][1] * size.width;
      final ay = kps![a][0] * size.height;
      final bx = kps![b][1] * size.width;
      final by = kps![b][0] * size.height;
      canvas.drawLine(Offset(ax, ay), Offset(bx, by), paintL);
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlay oldDelegate) {
    return oldDelegate.kps != kps;
  }
}
