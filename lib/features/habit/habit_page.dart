import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/services/firestore_service.dart';

final _habitDoneProvider = StateProvider<bool>((ref) => false);

class HabitPage extends ConsumerWidget {
  const HabitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(_habitDoneProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('오늘의 습관: "아침 물 500ml"', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(value: done, onChanged: (v) => ref.read(_habitDoneProvider.notifier).state = v ?? false),
              const Text('완료했어요'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Firestore 저장'),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
              await Fs.instance.setHabitDone(uid, DateTime.now(), ref.read(_habitDoneProvider));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
              }
            },
          ),
          const Spacer(),
          const Text('※ MVP: 하루 1개 습관만 체크', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
