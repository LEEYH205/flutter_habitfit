import 'package:flutter/material.dart';

/// 통계 칩 위젯 - 라벨, 값, 변화량을 표시하는 작은 통계 카드
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final double? delta; // 변화량 (양수: 상승, 음수: 하락)
  final Color? color;
  final IconData? icon;
  final String? unit;
  final bool showDelta;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.color,
    this.icon,
    this.unit,
    this.showDelta = true,
  });

  /// 상승/하락 아이콘과 색상 결정
  Widget _buildDeltaIndicator() {
    if (delta == null || !showDelta) return const SizedBox.shrink();

    final isPositive = delta! > 0;
    final isNeutral = delta == 0;
    
    Color deltaColor;
    IconData deltaIcon;
    
    if (isNeutral) {
      deltaColor = Colors.grey;
      deltaIcon = Icons.remove;
    } else if (isPositive) {
      deltaColor = Colors.green;
      deltaIcon = Icons.trending_up;
    } else {
      deltaColor = Colors.red;
      deltaIcon = Icons.trending_down;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          deltaIcon,
          size: 16,
          color: deltaColor,
        ),
        const SizedBox(width: 2),
        Text(
          '${delta!.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: deltaColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라벨과 아이콘
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: chipColor,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: chipColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // 값과 단위
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: chipColor,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 12,
                    color: chipColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
          
          // 변화량 표시
          if (showDelta && delta != null) ...[
            const SizedBox(height: 2),
            _buildDeltaIndicator(),
          ],
        ],
      ),
    );
  }
}

/// 통계 칩들을 가로로 배치하는 위젯
class StatChipRow extends StatelessWidget {
  final List<StatChip> chips;
  final double spacing;

  const StatChipRow({
    super.key,
    required this.chips,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((chip) => Padding(
                  padding: EdgeInsets.only(
                    right: chip == chips.last ? 0 : spacing,
                  ),
                  child: chip,
                ))
            .toList(),
      ),
    );
  }
}
