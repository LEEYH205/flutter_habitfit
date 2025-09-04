import 'package:flutter/material.dart';

/// 미니 스파크라인 위젯 - Today 페이지 전용 작은 그래프
class MiniSpark extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final bool showDots;
  final bool showArea;
  final String? label;

  const MiniSpark({
    super.key,
    required this.data,
    this.color = Colors.blue,
    this.height = 40.0,
    this.showDots = false,
    this.showArea = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '데이터 없음',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Expanded(
            child: CustomPaint(
              painter: SparklinePainter(
                data: data,
                color: color,
                showDots: showDots,
                showArea: showArea,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

/// 스파크라인 그리기 페인터
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool showDots;
  final bool showArea;

  SparklinePainter({
    required this.data,
    required this.color,
    this.showDots = false,
    this.showArea = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 데이터 정규화
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    
    if (range == 0) return; // 모든 값이 같은 경우

    // 점들 계산
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    // 영역 그리기
    if (showArea && points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, areaPaint);
    }

    // 라인 그리기
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // 점들 그리기
    if (showDots) {
      for (final point in points) {
        canvas.drawCircle(point, 3.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is SparklinePainter &&
        (oldDelegate.data != data ||
            oldDelegate.color != color ||
            oldDelegate.showDots != showDots ||
            oldDelegate.showArea != showArea);
  }
}

/// 걸음 수용 미니 스파크라인
class StepsMiniSpark extends StatelessWidget {
  final List<int> stepsData;
  final String? label;

  const StepsMiniSpark({
    super.key,
    required this.stepsData,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedData = stepsData.map((e) => e.toDouble()).toList();
    
    return MiniSpark(
      data: normalizedData,
      color: Colors.orange,
      showDots: true,
      showArea: true,
      label: label ?? '걸음 수',
    );
  }
}

/// 칼로리용 미니 스파크라인
class CaloriesMiniSpark extends StatelessWidget {
  final List<double> caloriesData;
  final String? label;

  const CaloriesMiniSpark({
    super.key,
    required this.caloriesData,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return MiniSpark(
      data: caloriesData,
      color: Colors.red,
      showDots: false,
      showArea: true,
      label: label ?? '칼로리',
    );
  }
}

/// 습관 완료율용 미니 스파크라인
class HabitsMiniSpark extends StatelessWidget {
  final List<double> completionRates;
  final String? label;

  const HabitsMiniSpark({
    super.key,
    required this.completionRates,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return MiniSpark(
      data: completionRates,
      color: Colors.green,
      showDots: true,
      showArea: false,
      label: label ?? '습관 완료율',
    );
  }
}
