import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/running_coach_service.dart';
import '../../widgets/app_bar_with_notifications.dart';

/// 러닝 코치 설정 페이지
class RunningCoachSetupPage extends ConsumerStatefulWidget {
  const RunningCoachSetupPage({super.key});

  @override
  ConsumerState<RunningCoachSetupPage> createState() =>
      _RunningCoachSetupPageState();
}

class _RunningCoachSetupPageState extends ConsumerState<RunningCoachSetupPage>
    with SingleTickerProviderStateMixin {
  final RunningCoachService _coachService = RunningCoachService();

  late TabController _tabController;
  final PageController _pageController = PageController();

  // 이벤트 정보
  final _eventNameController = TextEditingController();
  final _targetDistanceController = TextEditingController();
  final _targetHoursController = TextEditingController();
  final _targetMinutesController = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(days: 90));

  // 개인 설정
  final _paceMinutesController = TextEditingController();
  final _paceSecondsController = TextEditingController();
  final _weeklyDistanceController = TextEditingController();
  int _weeklyRunningDays = 3;
  int _weeklyLsdDays = 1;
  List<int> _runningDays = [1, 3, 5]; // 월, 수, 금
  List<int> _lsdDays = [6]; // 토요일

  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _weekDayNames = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _eventNameController.dispose();
    _targetDistanceController.dispose();
    _targetHoursController.dispose();
    _targetMinutesController.dispose();
    _paceMinutesController.dispose();
    _paceSecondsController.dispose();
    _weeklyDistanceController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSettings() async {
    final settings = await _coachService.getCoachSettings();
    if (settings != null) {
      setState(() {
        _paceMinutesController.text = settings.averagePace.inMinutes.toString();
        _paceSecondsController.text =
            (settings.averagePace.inSeconds % 60).toString();
        _weeklyDistanceController.text =
            settings.currentWeeklyDistance.toString();
        _weeklyRunningDays = settings.weeklyRunningDays;
        _weeklyLsdDays = settings.weeklyLsdDays;
        _runningDays = List<int>.from(settings.runningDays);
        _lsdDays = List<int>.from(settings.lsdDays);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(
        title: '🏃‍♂️ 러닝 코치 설정',
        showProfile: false,
      ),
      body: Column(
        children: [
          // 진행 표시기
          _buildProgressIndicator(),

          // 탭바
          TabBar(
            controller: _tabController,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            tabs: const [
              Tab(text: '이벤트 정보'),
              Tab(text: '개인 설정'),
            ],
          ),

          // 페이지 뷰
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildEventInfoPage(),
                _buildPersonalSettingsPage(),
              ],
            ),
          ),

          // 하단 버튼
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepIndicator(0, '이벤트'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 0 ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          _buildStepIndicator(1, '설정'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isActive
                    ? Colors.blue
                    : Colors.grey.shade300,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color:
                isCompleted || isActive ? Colors.white : Colors.grey.shade600,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 러닝 이벤트 정보',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '참가하고자 하는 러닝 이벤트의 정보를 입력해주세요.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // 이벤트 이름
          _buildTextField(
            controller: _eventNameController,
            label: '이벤트 이름',
            hint: '예: 서울 마라톤, 10K 대회',
            icon: Icons.event,
          ),

          const SizedBox(height: 16),

          // 이벤트 날짜
          _buildDatePicker(),

          const SizedBox(height: 16),

          // 목표 거리
          _buildTextField(
            controller: _targetDistanceController,
            label: '목표 거리 (km)',
            hint: '예: 21.1, 42.2',
            icon: Icons.straighten,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
          ),

          const SizedBox(height: 16),

          // 목표 시간
          _buildTimeInput(),

          const SizedBox(height: 24),

          // 목표 페이스 표시
          _buildTargetPaceDisplay(),
        ],
      ),
    );
  }

  Widget _buildPersonalSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ 개인 설정',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '현재 러닝 능력과 일정에 맞는 설정을 해주세요.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // 현재 평균 페이스
          _buildCurrentPaceInput(),

          const SizedBox(height: 16),

          // 현재 주간 거리
          _buildTextField(
            controller: _weeklyDistanceController,
            label: '현재 주간 거리 (km)',
            hint: '예: 25',
            icon: Icons.timeline,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
          ),

          const SizedBox(height: 24),

          // 주간 러닝 일수
          _buildWeeklyDaysSelector(),

          const SizedBox(height: 24),

          // 러닝 가능 요일
          _buildRunningDaysSelector(),

          const SizedBox(height: 24),

          // LSD 가능 요일
          _buildLsdDaysSelector(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이벤트 날짜',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _eventDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() {
                _eventDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  '${_eventDate.year}년 ${_eventDate.month}월 ${_eventDate.day}일',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '목표 시간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _targetHoursController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  hintText: '시간',
                  prefixIcon: const Icon(Icons.timer),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _targetMinutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  hintText: '분',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentPaceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '현재 평균 페이스 (분:초/km)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _paceMinutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  hintText: '분',
                  prefixIcon: const Icon(Icons.speed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _paceSecondsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  hintText: '초',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetPaceDisplay() {
    if (_targetDistanceController.text.isEmpty ||
        _targetHoursController.text.isEmpty ||
        _targetMinutesController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final distance = double.parse(_targetDistanceController.text);
      final hours = int.parse(_targetHoursController.text);
      final minutes = int.parse(_targetMinutesController.text);
      final totalMinutes = hours * 60 + minutes;
      final paceMinutes = totalMinutes / distance;
      final paceMin = paceMinutes.floor();
      final paceSec = ((paceMinutes - paceMin) * 60).round();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '계산된 목표 페이스',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$paceMin:${paceSec.toString().padLeft(2, '0')}/km',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildWeeklyDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주간 훈련 일수',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('러닝: '),
            Expanded(
              child: Slider(
                value: _weeklyRunningDays.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: '$_weeklyRunningDays일',
                onChanged: (value) {
                  setState(() {
                    _weeklyRunningDays = value.round();
                  });
                },
              ),
            ),
            Text('$_weeklyRunningDays일'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('LSD: '),
            Expanded(
              child: Slider(
                value: _weeklyLsdDays.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: '$_weeklyLsdDays일',
                onChanged: (value) {
                  setState(() {
                    _weeklyLsdDays = value.round();
                  });
                },
              ),
            ),
            Text('$_weeklyLsdDays일'),
          ],
        ),
      ],
    );
  }

  Widget _buildRunningDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '러닝 가능 요일',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _runningDays.contains(index);
            return FilterChip(
              label: Text(_weekDayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _runningDays.add(index);
                  } else {
                    _runningDays.remove(index);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLsdDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LSD 가능 요일',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'LSD(Long Slow Distance)는 장거리 저강도 러닝입니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _lsdDays.contains(index);
            return FilterChip(
              label: Text(_weekDayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _lsdDays.add(index);
                  } else {
                    _lsdDays.remove(index);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('이전'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextOrComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep == 1 ? '완료' : '다음'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextOrComplete() async {
    if (_currentStep == 0) {
      if (_validateEventInfo()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      await _completeSetup();
    }
  }

  bool _validateEventInfo() {
    if (_eventNameController.text.trim().isEmpty) {
      _showError('이벤트 이름을 입력해주세요');
      return false;
    }
    if (_targetDistanceController.text.trim().isEmpty) {
      _showError('목표 거리를 입력해주세요');
      return false;
    }
    if (_targetHoursController.text.trim().isEmpty ||
        _targetMinutesController.text.trim().isEmpty) {
      _showError('목표 시간을 입력해주세요');
      return false;
    }
    return true;
  }

  bool _validatePersonalSettings() {
    if (_paceMinutesController.text.trim().isEmpty ||
        _paceSecondsController.text.trim().isEmpty) {
      _showError('현재 평균 페이스를 입력해주세요');
      return false;
    }
    if (_weeklyDistanceController.text.trim().isEmpty) {
      _showError('현재 주간 거리를 입력해주세요');
      return false;
    }
    if (_runningDays.isEmpty) {
      _showError('러닝 가능 요일을 선택해주세요');
      return false;
    }
    return true;
  }

  Future<void> _completeSetup() async {
    if (!_validatePersonalSettings()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 러닝 이벤트 생성
      final eventId = await _coachService.createRunningEvent(
        name: _eventNameController.text.trim(),
        eventDate: _eventDate,
        targetDistance: double.parse(_targetDistanceController.text),
        targetTime: Duration(
          hours: int.parse(_targetHoursController.text),
          minutes: int.parse(_targetMinutesController.text),
        ),
      );

      if (eventId == null) {
        throw Exception('이벤트 생성 실패');
      }

      // 2. 러닝 코치 설정 저장
      final success = await _coachService.saveCoachSettings(
        averagePace: Duration(
          minutes: int.parse(_paceMinutesController.text),
          seconds: int.parse(_paceSecondsController.text),
        ),
        runningDays: _runningDays,
        lsdDays: _lsdDays,
        weeklyRunningDays: _weeklyRunningDays,
        weeklyLsdDays: _weeklyLsdDays,
        currentWeeklyDistance: double.parse(_weeklyDistanceController.text),
      );

      if (!success) {
        throw Exception('설정 저장 실패');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 러닝 코치 설정이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('설정 저장에 실패했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
