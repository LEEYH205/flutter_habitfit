import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime createdAt;
  final bool isActive;
  final int currentStreak;
  final int maxStreak;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.createdAt,
    this.isActive = true,
    this.currentStreak = 0,
    this.maxStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    // createdAt 필드 처리 - Timestamp 또는 String 모두 지원
    DateTime createdAt;
    final createdAtValue = map['createdAt'];
    if (createdAtValue == null) {
      createdAt = DateTime.now();
    } else if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else {
      createdAt = DateTime.now();
    }

    return Habit(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '✅',
      createdAt: createdAt,
      isActive: map['isActive'] ?? true,
      currentStreak: map['currentStreak'] ?? 0,
      maxStreak: map['maxStreak'] ?? 0,
    );
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    DateTime? createdAt,
    bool? isActive,
    int? currentStreak,
    int? maxStreak,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }
}
