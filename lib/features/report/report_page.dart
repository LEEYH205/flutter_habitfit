import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/services/fcm_service.dart';
import '../../common/services/local_notification_service.dart';
import '../health/health_test_page.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final id =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 운동 리포트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘 요약',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                int squatReps = 0;
                int pushupReps = 0;
                if (snap.data != null) {
                  for (final d in snap.data!.docs) {
                    final data = d.data();
                    final reps = data['reps'] as int? ?? 0;
                    final exerciseCategory =
                        data['exerciseCategory'] as String? ?? 'squat';

                    if (exerciseCategory == 'squat') {
                      squatReps += reps;
                    } else if (exerciseCategory == 'pushup') {
                      pushupReps += reps;
                    }
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('스쿼트: $squatReps회'),
                    const SizedBox(height: 4),
                    Text('푸시업: $pushupReps회'),
                  ],
                );
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
                return Text('섭취 칼로리: $kcal kcal');
              },
            ),
            const SizedBox(height: 24),
            const Text('내일도 파이팅! 🎉'),
            const SizedBox(height: 32),

            // FCM 테스트 섹션
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔔 로컬 알림 시스템 테스트',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '로컬 알림 기능들을 테스트해보세요.',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FcmService.instance.showTestNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🧪 로컬 테스트 알림을 보냈습니다!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('로컬 알림 테스트'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await LocalNotificationService.instance
                                .showDailyWorkoutSummary(25, 120);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📊 일일 요약 알림을 보냈습니다!'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.summarize),
                          label: const Text('일일 요약 알림'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await LocalNotificationService.instance
                                .showGoalAchievementNotification('스쿼트', 20);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎯 목표 달성 알림을 보냈습니다!'),
                                  backgroundColor: Colors.purple,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.emoji_events),
                          label: const Text('목표 달성 알림'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await LocalNotificationService.instance
                                .scheduleHabitReminder(
                                    const TimeOfDay(hour: 20, minute: 0));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📝 오후 8시 습관 체크 리마인더를 설정했습니다!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: const Text('습관 리마인더'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 로컬 알림은 FCM 없이도 완벽하게 작동합니다!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // HealthKit 테스트 섹션
                  const Text(
                    '🏥 HealthKit 연동 테스트',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HealthTestPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite),
                    label: const Text('HealthKit 테스트'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 iPhone 건강앱과 연동하여 운동 데이터를 가져옵니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
