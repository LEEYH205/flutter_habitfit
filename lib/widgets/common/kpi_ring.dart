import 'package:flutter/material.dart';

/// KPI 링 위젯 - 칼로리, 단백질, 습관 등의 진행률을 원형으로 표시
class KpiRing extends StatelessWidget {
  final String title;
  final String value;
  final double progress; // 0.0 ~ 1.0
  final Color color;
  final IconData? icon;
  final String? unit;
  final String? subtitle;
  final VoidCallback? onTap;

  const KpiRing({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
    this.icon,
    this.unit,
    this.subtitle,
    this.onTap,
  });

  /// 칼로리 링 생성
  factory KpiRing.calories({
    required String value,
    required double progress,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return KpiRing(
      title: '움직이기',
      value: value,
      progress: progress,
      color: Colors.red,
      icon: Icons.local_fire_department,
      unit: 'kcal',
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  /// 운동 시간 링 생성
  factory KpiRing.exercise({
    required String value,
    required double progress,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return KpiRing(
      title: '운동 시간',
      value: value,
      progress: progress,
      color: Colors.blue,
      icon: Icons.timer,
      unit: null, // 값에 이미 '분'이 포함되어 있음
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  /// 습관 링 생성
  factory KpiRing.habits({
    required String value,
    required double progress,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return KpiRing(
      title: '습관',
      value: value,
      progress: progress,
      color: Colors.green,
      icon: Icons.check_circle,
      unit: '개',
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  /// 걸음 수 링 생성
  factory KpiRing.steps({
    required String value,
    required double progress,
    String? subtitle,
  }) {
    return KpiRing(
      title: '걸음',
      value: value,
      progress: progress,
      color: Colors.orange,
      icon: Icons.directions_walk,
      unit: '걸음',
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        children: [
          // 아이콘과 제목
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),

          // 원형 진행률 표시
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                // 배경 원
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                ),
                // 진행률 원
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // 중앙 값 표시
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (unit != null)
                        Text(
                          unit!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 부제목
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      ),
    );
  }
}
