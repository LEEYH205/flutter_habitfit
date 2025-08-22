import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../common/services/fcm_service.dart';

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
                  '🔔 FCM 푸시 알림 테스트',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '푸시 알림 기능을 테스트해보세요.',
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
                const SizedBox(height: 12),
                const Text(
                  '💡 Firebase Console에서 이 토큰으로 테스트 메시지를 보내보세요!',
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
