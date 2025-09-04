import 'package:flutter/material.dart';

/// 섹션 카드 위젯 - 제목, 내용, 액션 버튼을 포함하는 재사용 가능한 카드
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showDivider;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.icon,
    this.color,
    this.padding,
    this.margin,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.white;
    final cardIcon = icon;
    final cardColorScheme = _getColorScheme(cardColor);

    Widget cardContent = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: cardColor == Colors.white
            ? Border.all(color: Colors.grey.shade200)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (제목과 액션)
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                // 아이콘과 제목
                if (cardIcon != null) ...[
                  Icon(
                    cardIcon,
                    color: cardColorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cardColorScheme.onSurface,
                    ),
                  ),
                ),
                
                // 액션 버튼들
                if (actions != null) ...[
                  const SizedBox(width: 8),
                  ...actions!,
                ],
              ],
            ),
          ),
          
          // 구분선
          if (showDivider)
            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
          
          // 내용
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );

    // 탭 가능한 경우 InkWell로 감싸기
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// 색상에 따른 색상 스키마 반환
  ColorScheme _getColorScheme(Color color) {
    if (color == Colors.white) {
      return const ColorScheme.light(
        primary: Colors.blue,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
    } else if (color == Colors.green.shade50) {
      return ColorScheme.light(
        primary: Colors.green.shade600,
        onPrimary: Colors.white,
        surface: Colors.green.shade50,
        onSurface: Colors.green.shade800,
      );
    } else if (color == Colors.blue.shade50) {
      return ColorScheme.light(
        primary: Colors.blue.shade600,
        onPrimary: Colors.white,
        surface: Colors.blue.shade50,
        onSurface: Colors.blue.shade800,
      );
    } else if (color == Colors.orange.shade50) {
      return ColorScheme.light(
        primary: Colors.orange.shade600,
        onPrimary: Colors.white,
        surface: Colors.orange.shade50,
        onSurface: Colors.orange.shade800,
      );
    } else {
      return ColorScheme.light(
        primary: color,
        onPrimary: Colors.white,
        surface: color,
        onSurface: Colors.black,
      );
    }
  }
}

/// 간단한 섹션 카드 (제목만 있는 버전)
class SimpleSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const SimpleSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      color: color,
      padding: padding,
      showDivider: false,
      child: child,
    );
  }
}

/// 액션 버튼을 위한 헬퍼 위젯
class SectionActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const SectionActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        iconSize: 20,
      ),
    );
  }
}
