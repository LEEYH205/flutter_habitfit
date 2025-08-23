import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/services/firestore_service.dart';
import '../../common/services/local_notification_service.dart';

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
              final habitDone = ref.read(_habitDoneProvider);
              
              try {
                // Firestore에 저장
                await Fs.instance.setHabitDone(uid, DateTime.now(), habitDone);
                
                // 습관 체크 완료 시 알림 전송
                if (habitDone) {
                  final prefs = await SharedPreferences.getInstance();
                  final habitRemindersEnabled = prefs.getBool('habitRemindersEnabled') ?? true;
                  
                  if (habitRemindersEnabled) {
                    await LocalNotificationService.instance.showTestNotification();
                    print('📝 습관 체크 완료 알림 전송');
                  }
                  
                  // 목표 달성 확인
                  final dailyHabitGoal = prefs.getInt('dailyHabitGoal') ?? 1;
                  final goalAchievementEnabled = prefs.getBool('goalAchievementEnabled') ?? true;
                  
                  if (goalAchievementEnabled) {
                    await LocalNotificationService.instance.showGoalAchievementNotification('습관 체크', 1);
                    print('🎯 습관 목표 달성 축하 알림 전송');
                  }
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
                }
              } catch (e) {
                print('❌ 습관 저장 또는 알림 전송 실패: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                }
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
