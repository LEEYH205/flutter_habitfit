import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../../providers/auth_provider.dart';
import '../insights/insights_page.dart';
import '../notifications/notifications_page.dart';
import '../running/running_detail_page.dart';
import '../../services/health_kit_service.dart';
import '../settings/user_profile_page.dart';

class ActivityPage extends ConsumerStatefulWidget {
  final DateTime? initialDate; // 초기 선택 날짜

  const ActivityPage({super.key, this.initialDate});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '주'; // 주, 월, 년, 전체
  List<Map<String, dynamic>> _activityData = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now(); // 현재 선택된 월
  List<WorkoutData> _recentWorkouts = []; // 실제 운동 데이터
  bool _isLoadingWorkouts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkHealthKitPermissions();
    _loadActivityData();
    _loadRecentWorkouts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // 페이지 상태 유지
  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '활동',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
              ),
              // Red dot for unread notifications
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _showProfileMenu(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    ref.read(authProviderProvider).user?.photoURL != null
                        ? NetworkImage(
                            ref.read(authProviderProvider).user!.photoURL!)
                        : null,
                child: ref.read(authProviderProvider).user?.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 탭 바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: '운동 기록', icon: Icon(Icons.fitness_center)),
                Tab(text: '분석', icon: Icon(Icons.analytics)),
              ],
            ),
          ),
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJournalTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Journal 탭 (운동 기록)
  Widget _buildJournalTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadActivityData();
          await _loadRecentWorkouts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 기간 선택 탭
              _buildPeriodSelector(),

              // 바 그래프 섹션
              _buildBarChartSection(),

              // 최근 활동 섹션
              _buildRecentActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Insights 탭 (분석)
  Widget _buildInsightsTab() {
    return const InsightsPage(showAppBar: false);
  }

  /// HealthKit 권한 확인 및 요청
  Future<void> _checkHealthKitPermissions() async {
    try {
      print('🔍 HealthKit 권한 상태 확인 중...');

      final health = HealthFactory();
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
      ];

      final granted = await health.requestAuthorization(types);

      if (granted) {
        print('✅ HealthKit 권한이 승인되었습니다');
      } else {
        print('❌ HealthKit 권한이 거부되었습니다');
      }
    } catch (e) {
      print('❌ HealthKit 권한 확인 오류: $e');
    }
  }

  /// 기간 선택 탭
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildPeriodTab('주'),
          _buildPeriodTab('월'),
          _buildPeriodTab('년'),
          _buildPeriodTab('전체'),
        ],
      ),
    );
  }

  /// 기간 탭 위젯
  Widget _buildPeriodTab(String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
          _loadActivityData();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 바 그래프 섹션
  Widget _buildBarChartSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '활동량',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedPeriod == '월') _buildMonthSelector(),
            ],
          ),
          const SizedBox(height: 16),
          // 월별 총량 표시
          if (_selectedPeriod == '월' && !_isLoading) _buildMonthlySummary(),
          if (_selectedPeriod == '월' && !_isLoading) const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildBarChart(),
        ],
      ),
    );
  }

  /// 월 선택 위젯
  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedMonth.year}년 ${_selectedMonth.month}월',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.blue.shade700,
            ),
          ],
        ),
      ),
    );
  }

  /// 월별 총량 요약 표시
  Widget _buildMonthlySummary() {
    if (_activityData.isEmpty) return const SizedBox.shrink();

    // 총 활동량 계산
    final totalValue = _activityData.fold<double>(
      0.0,
      (sum, data) => sum + (data['value'] as double),
    );

    // 러닝 횟수 (주말 활동 기준으로 추정)
    final runningCount = _activityData.where((data) {
      final day = int.parse((data['label'] as String).replaceAll('일', ''));
      final weekday =
          DateTime(_selectedMonth.year, _selectedMonth.month, day).weekday;
      return weekday == 6 || weekday == 7; // 토요일, 일요일
    }).length;

    // 평균 페이스 계산 (샘플)
    final avgPace =
        totalValue > 0 ? (totalValue / runningCount).toStringAsFixed(1) : '0.0';

    // 총 시간 계산 (샘플)
    final totalHours = (totalValue * 0.1).floor();
    final totalMinutes = ((totalValue * 0.1 - totalHours) * 60).round();
    final timeString = totalHours > 0
        ? '$totalHours:${totalMinutes.toString().padLeft(2, '0')}:00'
        : '$totalMinutes:00';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 총 거리
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                totalValue.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '킬로미터',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 세부 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '$runningCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '러닝',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$avgPace\'',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '평균 페이스',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    timeString,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '시간',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 월 선택기 표시
  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('월 선택'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              // 년도 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                            _selectedMonth.year - 1, _selectedMonth.month);
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_selectedMonth.year}년',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                            _selectedMonth.year + 1, _selectedMonth.month);
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 월 선택 그리드
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _selectedMonth.month;
                    final isCurrentMonth = month == DateTime.now().month &&
                        _selectedMonth.year == DateTime.now().year;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, month);
                        });
                        _loadActivityData();
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : isCurrentMonth
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentMonth && !isSelected
                              ? Border.all(
                                  color: Colors.blue.shade300, width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$month월',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : isCurrentMonth
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade700,
                              fontWeight: isSelected || isCurrentMonth
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 바 차트 위젯
  Widget _buildBarChart() {
    if (_activityData.isEmpty) {
      return SizedBox(
        height: 200,
        child: const Center(
          child: Text(
            '활동 데이터가 없습니다',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 월별 데이터인 경우 가로 스크롤 가능하도록
    if (_selectedPeriod == '월') {
      // 최대값 계산
      final maxValue = _activityData.isNotEmpty
          ? _activityData
              .map((d) => d['value'] as double)
              .reduce((a, b) => a > b ? a : b)
          : 1.0;

      return SizedBox(
        height: 220,
        child: Column(
          children: [
            // 차트 영역
            Expanded(
              child: Stack(
                children: [
                  // 배경 그리드 선
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(
                          maxValue: maxValue, dataLength: _activityData.length),
                    ),
                  ),
                  // 차트 내용
                  Row(
                    children: [
                      // Y축 라벨
                      SizedBox(
                        width: 30,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              maxValue.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              (maxValue * 0.75).toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              (maxValue * 0.5).toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              (maxValue * 0.25).toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              '0.0',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 바 차트 (라벨 제외)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 패딩과 바 너비를 먼저 계산하고 남은 공간을 간격으로 분배
                            final totalBarWidth =
                                _activityData.length * 4.0; // 바 너비 총합
                            final paddingWidth = 8.0; // 양쪽 패딩 (4px * 2)
                            final availableSpace = constraints.maxWidth -
                                totalBarWidth -
                                paddingWidth;
                            final spacing = _activityData.length > 1
                                ? (availableSpace / (_activityData.length - 1))
                                    .clamp(0.5, double.infinity)
                                : 0.0;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // 왼쪽 패딩
                                    SizedBox(width: spacing / 2),
                                    // 바들
                                    ..._activityData
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final data = entry.value;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right:
                                              index < _activityData.length - 1
                                                  ? spacing
                                                  : 0,
                                        ),
                                        child: _buildBarOnly(data),
                                      );
                                    }),
                                    // 오른쪽 패딩
                                    SizedBox(width: spacing / 2),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // X축 라벨 영역
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  const SizedBox(width: 38), // Y축 라벨 너비 + 간격
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 표시되는 라벨과 숨겨지는 라벨의 개수를 각각 계산
                        final visibleLabels = _activityData.where((data) {
                          final day = int.tryParse(data['label'] ?? '') ?? 0;
                          final lastDayOfMonth = DateTime(_selectedMonth.year,
                                  _selectedMonth.month + 1, 0)
                              .day;
                          return day == 1 ||
                              day == 7 ||
                              day == 14 ||
                              day == 21 ||
                              day == 28 ||
                              day == lastDayOfMonth;
                        }).length;

                        final hiddenLabels =
                            _activityData.length - visibleLabels;

                        print(
                            '📊 라벨 계산: 표시 $visibleLabels개 × 20px + 숨김 $hiddenLabels개 × 4px = ${(visibleLabels * 20.0) + (hiddenLabels * 4.0)}px');

                        // 표시되는 라벨(20px) + 숨겨지는 라벨(4px)의 총 너비 계산
                        final totalLabelWidth =
                            (visibleLabels * 20.0) + (hiddenLabels * 4.0);
                        final paddingWidth = 8.0; // 양쪽 패딩 (4px * 2)
                        final availableSpace = constraints.maxWidth -
                            totalLabelWidth -
                            paddingWidth;
                        final spacing = _activityData.length > 1
                            ? (availableSpace / (_activityData.length - 1))
                                .clamp(0.5, double.infinity)
                            : 0.0;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Row(
                              children: [
                                // 왼쪽 패딩
                                SizedBox(width: spacing / 2),
                                // 라벨들
                                ..._activityData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < _activityData.length - 1
                                          ? spacing
                                          : 0,
                                    ),
                                    child: _buildXAxisLabel(data),
                                  );
                                }),
                                // 오른쪽 패딩
                                SizedBox(width: spacing / 2),
                              ],
                            ),
                          ),
                        );
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

    // 다른 기간은 기존 방식 유지
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _activityData.map((data) => _buildBar(data)).toList(),
      ),
    );
  }

  /// 바만 생성 (라벨 제외)
  Widget _buildBarOnly(Map<String, dynamic> data) {
    final value = data['value'] as double;
    final maxValue = _activityData.isNotEmpty
        ? _activityData
            .map((d) => d['value'] as double)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;
    final height = (value / maxValue) * 150;

    // 바 너비 고정 (4px)
    final barWidth = 4.0;

    return SizedBox(
      width: 4.0, // 고정 너비
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 월별 데이터인 경우 바 위에 값 표시하지 않음
          if (_selectedPeriod != '월')
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10),
            ),
          if (_selectedPeriod != '월') const SizedBox(height: 4),
          Container(
            width: barWidth,
            height: height,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  /// X축 라벨만 생성
  Widget _buildXAxisLabel(Map<String, dynamic> data) {
    final fontSize = _selectedPeriod == '월' ? 6.0 : 8.0; // 글자 크기 축소

    // 월별 데이터에서 특정 날짜만 라벨 표시
    final day = int.tryParse(data['label'] ?? '') ?? 0;
    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final shouldShowLabel = _selectedPeriod == '월'
        ? (day == 1 ||
            day == 7 ||
            day == 14 ||
            day == 21 ||
            day == 28 ||
            day == lastDayOfMonth)
        : true;

    if (_selectedPeriod == '월' && shouldShowLabel) {
      print('🏷️ 라벨 표시: $day일 (말일: $lastDayOfMonth일)');
    }

    // 표시되는 라벨은 넉넉한 너비, 숨겨지는 라벨은 최소 너비로 할당
    final labelWidth =
        shouldShowLabel ? 20.0 : 4.0; // 표시되는 라벨은 20px, 숨겨지는 라벨은 4px

    return SizedBox(
      width: labelWidth,
      child: shouldShowLabel
          ? Text(
              data['label'] ?? '',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink(), // 텍스트는 숨기지만 공간은 차지
    );
  }

  /// 개별 바 위젯
  Widget _buildBar(Map<String, dynamic> data) {
    final value = data['value'] as double;
    final maxValue = _activityData.isNotEmpty
        ? _activityData
            .map((d) => d['value'] as double)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;
    final height = (value / maxValue) * 150;

    // 월별 데이터인 경우 바 너비와 간격 조정
    final barWidth = _selectedPeriod == '월' ? 4.0 : 20.0;
    final spacing = _selectedPeriod == '월' ? 0.8 : 4.0;
    final fontSize = _selectedPeriod == '월' ? 8.0 : 10.0;

    return Container(
      width: _selectedPeriod == '월' ? 6.0 : null, // 월별 데이터는 고정 너비
      margin: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 월별 데이터인 경우 바 위에 값 표시하지 않음
          if (_selectedPeriod != '월')
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(fontSize: fontSize),
            ),
          if (_selectedPeriod != '월') SizedBox(height: spacing),
          Container(
            width: barWidth,
            height: height,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: spacing),
        ],
      ),
    );
  }

  /// 최근 활동 섹션
  Widget _buildRecentActivitiesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 활동',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivitiesList(),
        ],
      ),
    );
  }

  /// 최근 활동 목록
  Widget _buildRecentActivitiesList() {
    if (_isLoadingWorkouts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recentWorkouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.directions_run,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '최근 운동 기록이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '운동을 시작해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentWorkouts
          .map((workout) => _buildActivityCardFromWorkout(workout))
          .toList(),
    );
  }

  /// WorkoutData에서 활동 카드 생성
  Widget _buildActivityCardFromWorkout(WorkoutData workout) {
    final date = workout.startTime;
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final timeOfDay = _getTimeOfDay(date.hour);

    // 페이스 계산 (분/km)
    final pace = workout.distance != null && workout.distance! > 0
        ? workout.duration.inMinutes / workout.distance!
        : 0.0;
    final paceMinutes = pace.floor();
    final paceSeconds = ((pace - paceMinutes) * 60).round();

    // 시간 포맷팅
    final hours = workout.duration.inHours;
    final minutes = workout.duration.inMinutes % 60;
    final timeString = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}'
        : '$minutes분';

    return GestureDetector(
      onTap: () {
        _navigateToRunningDetailFromWorkout(workout);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 앱 아이콘
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // 활동 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${date.year}. ${date.month}. ${date.day}.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$dayOfWeek $timeOfDay 러닝',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActivityMetric(
                          '${workout.distance?.toStringAsFixed(2) ?? '0.0'} Km'),
                      const SizedBox(width: 16),
                      _buildActivityMetric(
                          '$paceMinutes\'${paceSeconds.toString().padLeft(2, '0')}\'\' 평균 페이스'),
                      const SizedBox(width: 16),
                      _buildActivityMetric('$timeString 시간'),
                    ],
                  ),
                ],
              ),
            ),
            // 소스 정보
            Text(
              workout.source ?? 'HealthKit',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 요일 반환
  String _getDayOfWeek(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  /// 시간대 반환
  String _getTimeOfDay(int hour) {
    if (hour < 6) return '새벽';
    if (hour < 12) return '오전';
    if (hour < 18) return '오후';
    return '저녁';
  }

  /// 활동 카드 위젯 (기존 샘플 데이터용)
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return GestureDetector(
      onTap: () {
        _navigateToRunningDetail(activity);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 앱 아이콘
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // 활동 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['date'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    activity['day'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActivityMetric('${activity['distance']} Km'),
                      const SizedBox(width: 16),
                      _buildActivityMetric('${activity['pace']} 평균 페이스'),
                      const SizedBox(width: 16),
                      _buildActivityMetric('${activity['time']} 시간'),
                    ],
                  ),
                ],
              ),
            ),
            // 소스 정보
            Text(
              activity['source'],
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 활동 지표 위젯
  Widget _buildActivityMetric(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 실제 운동 데이터 로드
  Future<void> _loadRecentWorkouts() async {
    setState(() {
      _isLoadingWorkouts = true;
    });

    try {
      print('🏃‍♂️ 최근 운동 데이터 로드 시작');

      final healthKitService = HealthKitService();
      final workouts = await healthKitService.getRecentWorkouts(days: 30);

      // 최신순으로 정렬하고 최대 10개만 표시
      workouts.sort((a, b) => b.startTime.compareTo(a.startTime));

      setState(() {
        _recentWorkouts = workouts.take(10).toList();
        _isLoadingWorkouts = false;
      });

      print('✅ 최근 운동 데이터 ${_recentWorkouts.length}개 로드 완료');
    } catch (e) {
      print('❌ 최근 운동 데이터 로드 실패: $e');
      setState(() {
        _isLoadingWorkouts = false;
      });
    }
  }

  /// WorkoutData에서 러닝 상세 페이지로 이동
  void _navigateToRunningDetailFromWorkout(WorkoutData workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunningDetailPage(
          workout: workout,
        ),
      ),
    );
  }

  /// 러닝 상세 페이지로 이동 (샘플 데이터용)
  void _navigateToRunningDetail(Map<String, dynamic> activity) {
    // 활동 데이터를 WorkoutData 형태로 변환
    final startTime = DateTime.parse('2021-05-24'); // 샘플 날짜
    final endTime = startTime.add(const Duration(minutes: 30));

    final workoutData = WorkoutData(
      id: 'sample_${activity['date']}',
      uuid: 'sample_uuid_${activity['date']}',
      type: 'Running',
      startTime: startTime,
      endTime: endTime,
      duration: const Duration(minutes: 30),
      distance: double.tryParse(activity['distance']) ?? 0.0,
      calories: 300.0, // 샘플 칼로리
      source: 'GARMIN',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunningDetailPage(
          workout: workoutData,
        ),
      ),
    );
  }

  /// 활동 상세 보기 (기존 모달 방식)
  void _showActivityDetail(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.directions_run, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['day'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activity['date'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // 상세 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildDetailRow('거리', '${activity['distance']} Km'),
                    _buildDetailRow('평균 페이스', activity['pace']),
                    _buildDetailRow('시간', '${activity['time']}'),
                    _buildDetailRow('출처', activity['source']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상세 정보 행
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 월별 데이터 생성 (일별로 표시)
  List<Map<String, dynamic>> _generateMonthlyData() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    // 해당 월의 첫째 날과 마지막 날
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final totalDays = lastDay.day;

    print('📅 $year년 $month월: 총 $totalDays일');

    // 각 일별 데이터 생성
    List<Map<String, dynamic>> dailyData = [];
    for (int day = 1; day <= totalDays; day++) {
      // 샘플 데이터 (실제로는 해당 일의 운동 데이터를 계산해야 함)
      // 주말에는 더 높은 활동량, 평일에는 일반적인 활동량
      final weekday = DateTime(year, month, day).weekday;
      final isWeekend = weekday == 6 || weekday == 7; // 토요일, 일요일

      final baseValue = 5.0 + (day * 0.3);
      final weekendBonus = isWeekend ? 8.0 : 0.0;
      final randomVariation = (day % 3 == 0 ? 3.0 : 0.0); // 3일마다 변동

      final value = baseValue + weekendBonus + randomVariation;

      dailyData.add({
        'label': '$day',
        'value': value,
      });
    }

    return dailyData;
  }

  /// 활동 데이터 로드
  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 샘플 데이터 생성 (실제로는 HealthKit에서 가져와야 함)
      await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션

      List<Map<String, dynamic>> data = [];

      switch (_selectedPeriod) {
        case '주':
          data = [
            {'label': '월', 'value': 2.5},
            {'label': '화', 'value': 3.2},
            {'label': '수', 'value': 1.8},
            {'label': '목', 'value': 4.1},
            {'label': '금', 'value': 2.9},
            {'label': '토', 'value': 5.2},
            {'label': '일', 'value': 3.7},
          ];
          break;
        case '월':
          data = _generateMonthlyData();
          break;
        case '년':
          data = [
            {'label': '1월', 'value': 45.2},
            {'label': '2월', 'value': 38.7},
            {'label': '3월', 'value': 52.3},
            {'label': '4월', 'value': 41.5},
            {'label': '5월', 'value': 48.9},
            {'label': '6월', 'value': 35.2},
          ];
          break;
        case '전체':
          data = [
            {'label': '2021', 'value': 425.2},
            {'label': '2022', 'value': 538.7},
            {'label': '2023', 'value': 652.3},
            {'label': '2024', 'value': 441.5},
            {'label': '2025', 'value': 248.9},
          ];
          break;
      }

      setState(() {
        _activityData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 활동 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProfileMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserProfilePage(),
      ),
    );
  }
}

/// 그리드 선을 그리는 CustomPainter
class GridPainter extends CustomPainter {
  final double maxValue;
  final int dataLength;

  GridPainter({required this.maxValue, required this.dataLength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Y축 그리드 선 (수평선)
    final yPositions = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (final yPos in yPositions) {
      final y = size.height * (1 - yPos); // Y축은 아래에서 위로
      canvas.drawLine(
        Offset(30, y), // Y축 라벨 너비만큼 오프셋
        Offset(size.width, y),
        paint,
      );
    }

    // X축 그리드 선 (수직선) - 실제 데이터 길이에 맞게 조정
    final xPositions = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (final xPos in xPositions) {
      // 실제 데이터 길이에 비례하여 X 위치 계산
      final actualXPos = xPos * (dataLength - 1) / dataLength; // 0~29를 0~1로 정규화
      final x = 30 + (size.width - 30) * actualXPos; // Y축 라벨 너비만큼 오프셋
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // X축 기준선 (하단)
    final xAxisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(30, size.height),
      Offset(size.width, size.height),
      xAxisPaint,
    );

    // Y축 기준선 (좌측)
    final yAxisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(30, 0),
      Offset(30, size.height),
      yAxisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
