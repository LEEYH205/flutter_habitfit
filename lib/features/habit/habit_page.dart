import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/services/local_notification_service.dart';
import '../../models/habit.dart';
import '../../services/habit_service.dart';
import '../../services/cache_service.dart';
import '../../providers/today_summary_provider.dart';
import '../../widgets/habit_dialog.dart';
import '../../widgets/app_bar_with_notifications.dart';

final _habitsProvider = StateProvider<List<Habit>>((ref) => []);
final _habitCompletionsProvider = StateProvider<Map<String, bool>>((ref) => {});
final _habitStreaksProvider =
    StateProvider<Map<String, Map<String, int>>>((ref) => {});

class HabitPage extends ConsumerStatefulWidget {
  const HabitPage({super.key});

  @override
  ConsumerState<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends ConsumerState<HabitPage> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  final HabitService _habitService = HabitService();

  // 습관 설정
  bool _habitRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHabitData();
  }

  @override
  void dispose() {
    // 메모리 누수 방지
    super.dispose();
  }

  Future<void> _loadHabitData() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 설정 로드
      _habitRemindersEnabled = _prefs.getBool('habitRemindersEnabled') ?? true;

      // 사용자 습관 목록 로드
      final habits = await _habitService.getUserHabits();
      ref.read(_habitsProvider.notifier).state = habits;

      // 병렬로 모든 습관의 완료 상태와 연속 기록 로드
      final today = DateTime.now();
      final completions = <String, bool>{};
      final streaks = <String, Map<String, int>>{};

      // Future.wait를 사용하여 병렬 처리 (연속 기록은 Habit 모델에서 가져옴)
      final futures = habits.map((habit) async {
        final isDone = await _habitService.getHabitDone(habit.id, today);
        return {
          'habitId': habit.id,
          'isDone': isDone,
        };
      }).toList();

      final results = await Future.wait(futures);

      // 결과를 맵에 저장
      for (final result in results) {
        final habitId = result['habitId'] as String;
        final isDone = result['isDone'] as bool;
        completions[habitId] = isDone;

        // Habit 모델에서 연속 기록 가져오기
        final habit = habits.firstWhere((h) => h.id == habitId);
        streaks[habitId] = {
          'current': habit.currentStreak,
          'max': habit.maxStreak,
        };
      }

      ref.read(_habitCompletionsProvider.notifier).state = completions;
      ref.read(_habitStreaksProvider.notifier).state = streaks;

      print('✅ 습관 데이터 로드 완료: ${habits.length}개 습관');
    } catch (e) {
      print('❌ 습관 데이터 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 습관 추가
  Future<void> _addHabit() async {
    print('🔧 습관 추가 버튼 클릭됨');

    await showDialog(
      context: context,
      builder: (context) => HabitDialog(
        onSave: (title, description, emoji) async {
          print('🔧 습관 다이얼로그에서 저장 버튼 클릭됨: $title');

          final habitId = await _habitService.addHabit(
            title: title,
            description: description,
            emoji: emoji,
          );

          print('🔧 습관 추가 결과: $habitId');

          if (habitId != null) {
            await _loadHabitData(); // 데이터 새로고침

            // Today Summary 캐시 무효화 (총 습관 개수 업데이트를 위해)
            await CacheService.removeCache(CacheKeys.todaySummary);
            // Provider 무효화
            if (mounted) {
              ref.invalidate(todaySummaryProvider);
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('새 습관이 추가되었습니다: $title'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('습관 추가에 실패했습니다. 로그인 상태를 확인해주세요.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // 습관 편집
  Future<void> _editHabit(Habit habit) async {
    await showDialog(
      context: context,
      builder: (context) => HabitDialog(
        habit: habit,
        onSave: (title, description, emoji) async {
          final success = await _habitService.updateHabit(
            habitId: habit.id,
            title: title,
            description: description,
            emoji: emoji,
          );

          if (success) {
            await _loadHabitData(); // 데이터 새로고침
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('습관이 수정되었습니다: $title'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // 습관 삭제
  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('습관 삭제'),
        content: Text('정말로 "${habit.title}" 습관을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _habitService.deleteHabit(habit.id);
      if (success) {
        await _loadHabitData(); // 데이터 새로고침

        // Today 페이지 캐시 무효화 (습관 개수 업데이트를 위해)
        CacheService.removeCache(CacheKeys.todaySummary);
        ref.invalidate(todaySummaryProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('습관이 삭제되었습니다: ${habit.title}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  // 습관 완료 상태 토글
  Future<void> _toggleHabitCompletion(Habit habit, bool done) async {
    try {
      final today = DateTime.now();
      final success = await _habitService.setHabitDone(habit.id, today, done);

      if (success) {
        // 완료 상태 업데이트
        final completions = ref.read(_habitCompletionsProvider);
        completions[habit.id] = done;
        ref.read(_habitCompletionsProvider.notifier).state =
            Map.from(completions);

        // 연속 기록 업데이트 후 Habit 모델 새로고침
        final updatedHabits = await _habitService.getUserHabits();
        ref.read(_habitsProvider.notifier).state = updatedHabits;

        // 업데이트된 Habit에서 연속 기록 가져오기
        final updatedHabit = updatedHabits.firstWhere((h) => h.id == habit.id);
        final streaks = ref.read(_habitStreaksProvider);
        streaks[habit.id] = {
          'current': updatedHabit.currentStreak,
          'max': updatedHabit.maxStreak,
        };
        ref.read(_habitStreaksProvider.notifier).state = Map.from(streaks);

        // Today Summary 캐시 무효화 (완료된 습관 개수 업데이트를 위해)
        await CacheService.removeCache(CacheKeys.todaySummary);
        if (mounted) {
          ref.invalidate(todaySummaryProvider);
        }

        if (done) {
          // 습관 체크 완료 알림
          if (_habitRemindersEnabled && mounted) {
            await LocalNotificationService.instance
                .showHabitCompletionNotification(
              '습관 체크 완료',
              '${habit.title} 습관을 완료했습니다! 🎉',
            );
          }

          // 연속 달성 기록 축하
          final currentStreak = updatedHabit.currentStreak;
          final maxStreak = updatedHabit.maxStreak;

          if (currentStreak > 1 && mounted) {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ ${habit.title} 완료! ${updatedHabit.currentStreak}일 연속 달성'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${habit.title} 체크 해제됨'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ 습관 완료 상태 변경 실패: $e');
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
    final habits = ref.watch(_habitsProvider);
    final completions = ref.watch(_habitCompletionsProvider);
    final streaks = ref.watch(_habitStreaksProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: const AppBarWithNotifications(title: '습관 관리'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const AppBarWithNotifications(title: '습관 관리'),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 습관 목록 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '나의 습관 (${habits.length}개)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addHabit,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('추가'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 습관 목록
                Expanded(
                  child: habits.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            final isDone = completions[habit.id] ?? false;
                            final streak =
                                streaks[habit.id] ?? {'current': 0, 'max': 0};

                            return _buildHabitCard(habit, isDone, streak);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_task,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 등록된 습관이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 습관을 추가해서 시작해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addHabit,
            icon: const Icon(Icons.add),
            label: const Text('첫 습관 추가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 습관 카드 위젯
  Widget _buildHabitCard(Habit habit, bool isDone, Map<String, int> streak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.green[200]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 습관 헤더
            Row(
              children: [
                // 이모지
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      habit.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 습관 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.green[700] : Colors.grey[800],
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 완료 체크박스
                Checkbox(
                  value: isDone,
                  onChanged: (value) async {
                    await _toggleHabitCompletion(habit, value ?? false);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 연속 달성 기록
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${streak['current']}일 연속',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: Colors.purple[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '최고 ${streak['max']}일',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple[600],
                  ),
                ),
                const Spacer(),

                // 편집/삭제 버튼
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editHabit(habit);
                    } else if (value == 'delete') {
                      _deleteHabit(habit);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('편집'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
