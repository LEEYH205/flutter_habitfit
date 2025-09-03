import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/services/firestore_service.dart';
import '../../common/services/local_notification_service.dart';

final _habitDoneProvider = StateProvider<bool>((ref) => false);
final _streakCountProvider = StateProvider<int>((ref) => 0);
final _maxStreakProvider = StateProvider<int>((ref) => 0);

class HabitPage extends ConsumerStatefulWidget {
  const HabitPage({super.key});

  @override
  ConsumerState<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends ConsumerState<HabitPage> {
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // 습관 설정
  int _dailyHabitGoal = 1;
  bool _goalAchievementEnabled = true;
  bool _habitRemindersEnabled = true;

  // 축하 메시지 표시 관련 변수
  bool _showCelebration = false;
  String _celebrationText = '';

  @override
  void initState() {
    super.initState();
    _loadHabitData();
  }

  Future<void> _loadHabitData() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 설정 로드
      _dailyHabitGoal = _prefs.getInt('dailyHabitGoal') ?? 1;
      _goalAchievementEnabled =
          _prefs.getBool('goalAchievementEnabled') ?? true;
      _habitRemindersEnabled = _prefs.getBool('habitRemindersEnabled') ?? true;

      // 오늘 습관 체크 여부 확인
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      print('🔐 현재 사용자 UID: $uid');
      final today = DateTime.now();
      final todayId = _getDateId(today);

      final habitDoc = await FirebaseFirestore.instance
          .collection('habits')
          .doc('$uid-$todayId')
          .get();

      if (habitDoc.exists) {
        final habitData = habitDoc.data()!;
        ref.read(_habitDoneProvider.notifier).state =
            habitData['done'] ?? false;
      }

      // 연속 달성 기록 계산
      await _calculateStreak(uid);
    } catch (e) {
      print('❌ 습관 데이터 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateStreak(String uid) async {
    try {
      int currentStreak = 0;
      int maxStreak = 0;
      final now = DateTime.now();

      // 최근 30일 동안의 습관 체크 기록 확인
      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateId = _getDateId(checkDate);

        final habitDoc = await FirebaseFirestore.instance
            .collection('habits')
            .doc('$uid-$dateId')
            .get();

        if (habitDoc.exists && (habitDoc.data()?['done'] ?? false)) {
          if (i == 0) {
            // 오늘 체크했으면 연속 달성 시작
            currentStreak = 1;
            // 이전 연속 기록 확인
            for (int j = 1; j < 30; j++) {
              final prevDate = now.subtract(Duration(days: j));
              final prevDateId = _getDateId(prevDate);

              final prevHabitDoc = await FirebaseFirestore.instance
                  .collection('habits')
                  .doc('$uid-$prevDateId')
                  .get();

              if (prevHabitDoc.exists &&
                  (prevHabitDoc.data()?['done'] ?? false)) {
                currentStreak++;
              } else {
                break;
              }
            }
          }
          break;
        }
      }

      // 최고 연속 기록 가져오기
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        maxStreak = userDoc.data()?['maxHabitStreak'] ?? 0;
      }

      // 현재 연속 기록이 최고 기록을 넘으면 업데이트
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'maxHabitStreak': maxStreak,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      ref.read(_streakCountProvider.notifier).state = currentStreak;
      ref.read(_maxStreakProvider.notifier).state = maxStreak;
    } catch (e) {
      print('❌ 연속 달성 기록 계산 실패: $e');
    }
  }

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveHabitAndShowAchievement(bool done) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      print('🔐 습관 체크 사용자 UID: $uid');
      final today = DateTime.now();

      // Firestore에 저장
      await Fs.instance.setHabitDone(uid, today, done);

      if (done) {
        // 연속 달성 기록 재계산
        await _calculateStreak(uid);

        final currentStreak = ref.read(_streakCountProvider);
        final maxStreak = ref.read(_maxStreakProvider);

        // 습관 체크 완료 알림
        if (_habitRemindersEnabled) {
          await LocalNotificationService.instance
              .showHabitCompletionNotification(
            '습관 체크 완료',
            '오늘의 습관을 완료했습니다! 🎉',
          );
        }

        // 목표 달성 확인 및 축하
        if (_goalAchievementEnabled) {
          await LocalNotificationService.instance
              .showGoalAchievementNotification(
            '습관 체크',
            1,
          );
        }

        // 연속 달성 기록 축하
        if (currentStreak > 1) {
          String streakMessage = '';
          if (currentStreak == maxStreak && currentStreak > 1) {
            streakMessage = '🎊 새로운 최고 기록! $currentStreak일 연속 달성! 🎊';
          } else if (currentStreak >= 7) {
            streakMessage = '🔥 $currentStreak일 연속 달성! 정말 대단해요! 🔥';
          } else if (currentStreak >= 3) {
            streakMessage = '💪 $currentStreak일 연속 달성! 계속 이어가세요! 💪';
          }

          if (streakMessage.isNotEmpty) {
            await LocalNotificationService.instance
                .showStreakAchievementNotification(
              '연속 달성 축하',
              streakMessage,
            );
          }
        }

        if (mounted) {
          // 화면에 축하 메시지 표시
          setState(() {
            _showCelebration = true;
            _celebrationText = '🎉 습관 체크 완료! $currentStreak일 연속 달성! 🎉';
          });

          // 3초 후 축하 메시지 숨기기
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showCelebration = false;
              });
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 습관 체크 완료! $currentStreak일 연속 달성'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // 습관 체크 해제 시 연속 기록 초기화
        await _calculateStreak(uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 습관 체크 해제됨'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 습관 저장 또는 알림 전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(_habitDoneProvider);
    final currentStreak = ref.watch(_streakCountProvider);
    final maxStreak = ref.watch(_maxStreakProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('✅ 습관 관리'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('✅ 습관 관리'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 연속 달성 기록 표시
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Text(
                            '연속 달성 기록',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$currentStreak',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                '현재 연속',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.blue[300],
                          ),
                          Column(
                            children: [
                              Text(
                                '$maxStreak',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[600],
                                ),
                              ),
                              Text(
                                '최고 기록',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 오늘의 습관
                Text(
                  '오늘의 습관: "아침 물 500ml"',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: done ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // 습관 체크박스
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: done ? Colors.green[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: done ? Colors.green[200]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: done,
                        onChanged: (value) async {
                          ref.read(_habitDoneProvider.notifier).state =
                              value ?? false;
                          await _saveHabitAndShowAchievement(value ?? false);
                        },
                        activeColor: Colors.green,
                      ),
                      Expanded(
                        child: Text(
                          done ? '완료했어요! 🎉' : '완료했어요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: done ? Colors.green[700] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 목표 설정 정보
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag, color: Colors.purple[600]),
                          const SizedBox(width: 8),
                          Text(
                            '목표 설정',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '일일 습관 목표: $_dailyHabitGoal회',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple[700],
                        ),
                      ),
                      Text(
                        '목표 달성 알림: ${_goalAchievementEnabled ? "활성화" : "비활성화"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '※ MVP: 하루 1개 습관만 체크 • 설정에서 알림 시간 변경 가능',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 축하 메시지 오버레이
          if (_showCelebration)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _celebrationText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
