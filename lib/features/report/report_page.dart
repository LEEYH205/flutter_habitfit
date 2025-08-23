import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../common/services/fcm_service.dart';
import '../../common/services/local_notification_service.dart';

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

    return Padding(
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
              int reps = 0;
              if (snap.data != null) {
                for (final d in snap.data!.docs) {
                  reps += d.data()['reps'] as int? ?? 0;
                }
              }
              return Text('스쿼트: $reps회');
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
                          try {
                            final messaging = FirebaseMessaging.instance;
                            final token = await messaging.getToken();
                            if (token != null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '📋 FCM 토큰: ${token.substring(0, 20)}...'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 5),
                                    action: SnackBarAction(
                                      label: '복사',
                                      onPressed: () {
                                        // TODO: 클립보드에 복사
                                      },
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ FCM 토큰을 가져올 수 없습니다'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ 오류: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('FCM 토큰 확인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '📱 고급 알림 기능들',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await LocalNotificationService.instance
                              .showWorkoutCompletionNotification(15, '스쿼트');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('💪 운동 완료 알림을 보냈습니다!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('운동 완료 알림'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
