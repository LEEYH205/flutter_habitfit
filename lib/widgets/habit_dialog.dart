import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitDialog extends StatefulWidget {
  final Habit? habit; // null이면 새 습관, 있으면 편집
  final Function(String title, String description, String emoji) onSave;

  const HabitDialog({
    super.key,
    this.habit,
    required this.onSave,
  });

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedEmoji;

  final List<String> _emojis = [
    '💧',
    '🏃‍♂️',
    '📚',
    '🧘‍♀️',
    '🍎',
    '💤',
    '💪',
    '🎯',
    '🌟',
    '🔥',
    '✅',
    '🎨',
    '🎵',
    '🌱',
    '☀️',
    '🌙',
    '🏋️‍♀️',
    '🚴‍♂️',
    '🧠',
    '❤️',
    '🎪',
    '🎭',
    '🎨',
    '🎪'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.habit?.description ?? '');
    _selectedEmoji = widget.habit?.emoji ?? '✅';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.habit == null ? '새 습관 추가' : '습관 편집',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지 선택
            const Text(
              '이모지 선택',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    children: _emojis.map((emoji) {
                      final isSelected = emoji == _selectedEmoji;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = emoji;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[100]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blue)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 제목 입력
            const Text(
              '습관 제목',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '예: 아침 물 마시기',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),

            const SizedBox(height: 16),

            // 설명 입력
            const Text(
              '설명 (선택사항)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '예: 매일 아침 500ml 물 마시기',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 100,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _saveHabit,
          child: Text(widget.habit == null ? '추가' : '수정'),
        ),
      ],
    );
  }

  void _saveHabit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('습관 제목을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSave(title, description, _selectedEmoji);
    Navigator.of(context).pop();
  }
}
