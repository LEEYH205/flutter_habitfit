import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final id = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final habitQ = FirebaseFirestore.instance
        .collection('habits')
        .where('date', isEqualTo: id)
        .limit(1)
        .snapshots();

    final workoutQ = FirebaseFirestore.instance
        .collection('workouts')
        .where('date', isEqualTo: id)
        .snapshots();

    final mealQ = FirebaseFirestore.instance
        .collection('meals')
        .where('date', isEqualTo: id)
        .snapshots();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('오늘 요약', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: habitQ,
            builder: (context, snap) {
              final done = (snap.data?.docs.isNotEmpty ?? false)
                  ? (snap.data!.docs.first.data()['done'] == true)
                  : false;
              return Text('습관: ${done ? "완료" : "미완료"}');
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: workoutQ,
            builder: (context, snap) {
              int reps = 0;
              if (snap.data != null) {
                for (final d in snap.data!.docs) {
                  reps += d.data()['reps'] as int? ?? 0;
                }
              }
              return Text('스쿼트: ${reps}회');
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: mealQ,
            builder: (context, snap) {
              int kcal = 0;
              if (snap.data != null) {
                for (final d in snap.data!.docs) {
                  kcal += d.data()['kcal'] as int? ?? 0;
                }
              }
              return Text('섭취 칼로리: ${kcal} kcal');
            },
          ),
          const SizedBox(height: 24),
          const Text('내일도 파이팅! 🎉'),
        ],
      ),
    );
  }
}
