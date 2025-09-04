import 'dart:async';
import 'package:flutter/material.dart';

/// Debounce 유틸리티 클래스
class Debounce {
  final int milliseconds;
  Timer? _timer;

  Debounce({required this.milliseconds});

  /// 함수 실행을 지연시킴
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// 타이머 취소
  void cancel() {
    _timer?.cancel();
  }

  /// 타이머가 활성화되어 있는지 확인
  bool get isActive => _timer?.isActive ?? false;
}

/// 전역 Debounce 인스턴스들
class GlobalDebounce {
  // 검색용 (300ms)
  static final Debounce search = Debounce(milliseconds: 300);
  
  // 필터링용 (200ms)
  static final Debounce filter = Debounce(milliseconds: 200);
  
  // API 호출용 (500ms)
  static final Debounce api = Debounce(milliseconds: 500);
  
  // UI 업데이트용 (100ms)
  static final Debounce ui = Debounce(milliseconds: 100);
}

/// Debounce를 사용한 검색 위젯
class DebouncedSearchField extends StatefulWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const DebouncedSearchField({
    super.key,
    this.initialValue,
    required this.hintText,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late TextEditingController _controller;
  late Debounce _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _debounce = Debounce(milliseconds: widget.debounceDuration.inMilliseconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        _debounce.run(() {
          widget.onChanged(value);
        });
      },
    );
  }
}

/// Debounce를 사용한 필터 위젯
class DebouncedFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final Duration debounceDuration;

  const DebouncedFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 200),
  });

  @override
  State<DebouncedFilterChip> createState() => _DebouncedFilterChipState();
}

class _DebouncedFilterChipState extends State<DebouncedFilterChip> {
  late Debounce _debounce;

  @override
  void initState() {
    super.initState();
    _debounce = Debounce(milliseconds: widget.debounceDuration.inMilliseconds);
  }

  @override
  void dispose() {
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: widget.selected,
      onSelected: (selected) {
        _debounce.run(() {
          widget.onChanged(selected);
        });
      },
    );
  }
}
