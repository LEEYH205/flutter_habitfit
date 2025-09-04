import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_bar_with_notifications.dart';
import '../../widgets/common/section_card.dart';
import '../../providers/day_log_provider.dart';
import '../../models/day_log.dart';
// import 'day_details_page.dart'; // TODO: 필요시 구현

/// Journal 페이지 - 기록/편집 중심: "이 날 뭘 했지?"
class JournalPage extends ConsumerStatefulWidget {
  final DateTime? initialDate; // 초기 선택 날짜

  const JournalPage({super.key, this.initialDate});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage>
    with AutomaticKeepAliveClientMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
  }

  @override
  bool get wantKeepAlive => true; // 페이지 상태 유지

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWithNotifications(title: 'Journal'),
      body: SafeArea(
        child: RepaintBoundary(
          child: Column(
            children: [
              // 캘린더 헤더
              _buildCalendarHeader(),

              // 캘린더
              _buildCalendar(),

              // 선택된 날짜의 상세 정보
              Expanded(
                child: _buildSelectedDayDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 캘린더 헤더
  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_focusedDay.month}월 ${_focusedDay.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _previousMonth(),
              ),
              TextButton(
                onPressed: () => _goToToday(),
                child: const Text('Today'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _nextMonth(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 캘린더
  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        headerVisible: false,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          weekendTextStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  /// 선택된 날짜의 상세 정보
  Widget _buildSelectedDayDetails() {
    return Consumer(
      builder: (context, ref, child) {
        final dayLogAsync = ref.watch(dayLogProvider(_selectedDay));

        return dayLogAsync.when(
          data: (dayLog) => _buildDayLogContent(dayLog),
          loading: () => _buildLoadingContent(),
          error: (error, stack) => _buildErrorContent(),
        );
      },
    );
  }

  /// 날짜 로그 내용
  Widget _buildDayLogContent(DayLog dayLog) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          _buildDateHeader(dayLog),
          const SizedBox(height: 16),

          // 활동 요약
          if (dayLog.hasAnyActivity) ...[
            _buildActivitySummary(dayLog),
            const SizedBox(height: 16),
          ],

          // 습관 섹션
          _buildHabitsSection(dayLog),
          const SizedBox(height: 16),

          // 운동 섹션
          _buildWorkoutsSection(dayLog),
          const SizedBox(height: 16),

          // 달리기 섹션
          if (dayLog.hasRunningData) ...[
            _buildRunningSection(dayLog),
            const SizedBox(height: 16),
          ],

          // 식사 섹션
          _buildMealsSection(dayLog),
          const SizedBox(height: 16),

          // 편집 액션
          _buildEditActions(dayLog),
        ],
      ),
    );
  }

  /// 날짜 헤더
  Widget _buildDateHeader(DayLog dayLog) {
    return SectionCard(
      title: dayLog.displayDate,
      icon: Icons.calendar_today,
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLog.activitySummary,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (dayLog.hasAnyActivity) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (dayLog.totalWorkoutMinutes > 0) ...[
                  _buildStatChip(
                    '운동 시간',
                    '${dayLog.totalWorkoutMinutes}분',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                ],
                if (dayLog.totalBurnedCalories > 0) ...[
                  _buildStatChip(
                    '소모 칼로리',
                    '${dayLog.totalBurnedCalories.toInt()}kcal',
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                ],
                if (dayLog.totalConsumedCalories > 0) ...[
                  _buildStatChip(
                    '섭취 칼로리',
                    '${dayLog.totalConsumedCalories.toInt()}kcal',
                    Colors.orange,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 활동 요약
  Widget _buildActivitySummary(DayLog dayLog) {
    return SectionCard(
      title: '활동 요약',
      icon: Icons.summarize,
      color: Colors.green.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '습관',
                  '${dayLog.completedHabitsCount}개',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '운동',
                  '${dayLog.completedWorkoutsCount}개',
                  Colors.blue,
                  Icons.fitness_center,
                ),
              ),
            ],
          ),
          if (dayLog.hasRunningData) ...[
            const SizedBox(height: 12),
            _buildSummaryItem(
              '달리기',
              '${dayLog.runningDistance.toStringAsFixed(1)}km',
              Colors.purple,
              Icons.directions_run,
            ),
          ],
        ],
      ),
    );
  }

  /// 습관 섹션
  Widget _buildHabitsSection(DayLog dayLog) {
    return SectionCard(
      title: '습관',
      icon: Icons.check_circle,
      color: Colors.green.shade50,
      actions: [
        SectionActionButton(
          icon: Icons.add,
          tooltip: '습관 추가',
          onPressed: () => _addHabit(),
        ),
      ],
      child: dayLog.habits.isEmpty
          ? _buildEmptyState('습관이 없습니다', '새로운 습관을 추가해보세요')
          : Column(
              children:
                  dayLog.habits.map((habit) => _buildHabitItem(habit)).toList(),
            ),
    );
  }

  /// 운동 섹션
  Widget _buildWorkoutsSection(DayLog dayLog) {
    return SectionCard(
      title: '운동',
      icon: Icons.fitness_center,
      color: Colors.blue.shade50,
      actions: [
        SectionActionButton(
          icon: Icons.add,
          tooltip: '운동 추가',
          onPressed: () => _addWorkout(),
        ),
      ],
      child: dayLog.workouts.isEmpty
          ? _buildEmptyState('운동이 없습니다', '새로운 운동을 추가해보세요')
          : Column(
              children: dayLog.workouts
                  .map((workout) => _buildWorkoutItem(workout))
                  .toList(),
            ),
    );
  }

  /// 달리기 섹션
  Widget _buildRunningSection(DayLog dayLog) {
    return SectionCard(
      title: '달리기',
      icon: Icons.directions_run,
      color: Colors.purple.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '거리',
                  '${dayLog.runningDistance.toStringAsFixed(1)}km',
                  Colors.purple,
                  Icons.straighten,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '시간',
                  '${dayLog.totalWorkoutMinutes}분',
                  Colors.purple,
                  Icons.timer,
                ),
              ),
            ],
          ),
          if (dayLog.runningAveragePace > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryItem(
              '평균 페이스',
              '${dayLog.runningAveragePace.toStringAsFixed(1)}분/km',
              Colors.purple,
              Icons.speed,
            ),
          ],
        ],
      ),
    );
  }

  /// 식사 섹션
  Widget _buildMealsSection(DayLog dayLog) {
    return SectionCard(
      title: '식사',
      icon: Icons.restaurant,
      color: Colors.orange.shade50,
      actions: [
        SectionActionButton(
          icon: Icons.add,
          tooltip: '식사 추가',
          onPressed: () => _addMeal(),
        ),
      ],
      child: dayLog.meals.isEmpty
          ? _buildEmptyState('식사 기록이 없습니다', '새로운 식사를 추가해보세요')
          : Column(
              children:
                  dayLog.meals.map((meal) => _buildMealItem(meal)).toList(),
            ),
    );
  }

  /// 편집 액션
  Widget _buildEditActions(DayLog dayLog) {
    return SectionCard(
      title: '편집',
      icon: Icons.edit,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _duplicateDay(dayLog),
                  icon: const Icon(Icons.copy),
                  label: const Text('이 날 복제'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportDay(dayLog),
                  icon: const Icon(Icons.share),
                  label: const Text('내보내기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 통계 칩
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 요약 아이템
  Widget _buildSummaryItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 습관 아이템
  Widget _buildHabitItem(Map<String, dynamic> habit) {
    final emoji = habit['emoji'] ?? '✅';
    final title = habit['title'] ?? '제목 없음';
    final description = habit['description'] ?? '';
    final completedAt = habit['completedAt'];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        subtitle: description.isNotEmpty 
            ? Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              )
            : completedAt != null 
                ? Text(
                    '완료 시간: ${_formatTime(completedAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  )
                : null,
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('편집'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleHabitAction(value, habit),
        ),
      ),
    );
  }

  /// 운동 아이템
  Widget _buildWorkoutItem(Map<String, dynamic> workout) {
    return ListTile(
      leading: const Icon(Icons.fitness_center, color: Colors.blue),
      title: Text(workout['title'] ?? '제목 없음'),
      subtitle: Text('${workout['duration'] ?? 0}분'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('편집'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('삭제'),
          ),
        ],
        onSelected: (value) => _handleWorkoutAction(value, workout),
      ),
    );
  }

  /// 식사 아이템
  Widget _buildMealItem(Map<String, dynamic> meal) {
    return ListTile(
      leading: const Icon(Icons.restaurant, color: Colors.orange),
      title: Text(meal['name'] ?? '제목 없음'),
      subtitle: Text('${meal['calories'] ?? 0}kcal'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('편집'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('삭제'),
          ),
        ],
        onSelected: (value) => _handleMealAction(value, meal),
      ),
    );
  }

  /// 로딩 상태
  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 에러 상태
  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            '데이터를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 새로고침
              setState(() {});
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 액션 메서드들
  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  void _addHabit() {
    // TODO: 습관 추가 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('습관 추가 기능은 곧 추가될 예정입니다')),
    );
  }

  void _addWorkout() {
    // TODO: 운동 추가 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('운동 추가 기능은 곧 추가될 예정입니다')),
    );
  }

  void _addMeal() {
    // TODO: 식사 추가 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('식사 추가 기능은 곧 추가될 예정입니다')),
    );
  }

  void _duplicateDay(DayLog dayLog) {
    // TODO: 날짜 복제 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('날짜 복제 기능은 곧 추가될 예정입니다')),
    );
  }

  void _exportDay(DayLog dayLog) {
    // TODO: 내보내기 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('내보내기 기능은 곧 추가될 예정입니다')),
    );
  }

  void _handleHabitAction(String action, Map<String, dynamic> habit) {
    // TODO: 습관 액션 처리
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('습관 $action 기능은 곧 추가될 예정입니다')),
    );
  }

  void _handleWorkoutAction(String action, Map<String, dynamic> workout) {
    // TODO: 운동 액션 처리
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('운동 $action 기능은 곧 추가될 예정입니다')),
    );
  }

  void _handleMealAction(String action, Map<String, dynamic> meal) {
    // TODO: 식사 액션 처리
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('식사 $action 기능은 곧 추가될 예정입니다')),
    );
  }

  /// 시간 포맷팅
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      return '';
    }
    
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
