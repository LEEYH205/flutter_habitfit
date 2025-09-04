# 🚀 Flutter 고급 개념 가이드

## 📋 목차
1. [딥링크 라우팅 (Deep Link Routing)](#딥링크-라우팅-deep-link-routing)
2. [캐싱 시스템 (Caching System)](#캐싱-시스템-caching-system)
3. [Debounce 최적화](#debounce-최적화)

---

## 🔗 딥링크 라우팅 (Deep Link Routing)

### 📖 개념 설명

**딥링크(Deep Link)**는 앱의 특정 페이지나 기능으로 직접 이동할 수 있는 URL입니다. 웹의 링크와 유사하게, 앱 내부의 특정 화면으로 바로 접근할 수 있게 해줍니다.

### 🎯 주요 장점

- **직접 접근**: 앱의 특정 페이지로 바로 이동
- **공유 가능**: URL을 통해 특정 화면 공유
- **SEO 친화적**: 웹과 앱 간의 일관된 경험
- **사용자 경험 향상**: 빠른 네비게이션

### 🛠️ 구현 방법

#### 1. GoRouter 설정

```dart
// lib/router/app_router.dart
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/today',
    routes: [
      // 메인 셸 (하단 탭 네비게이션)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          // Today 페이지
          GoRoute(
            path: '/today',
            name: 'today',
            builder: (context, state) {
              final action = state.uri.queryParameters['action'];
              return TodayPage(action: action);
            },
          ),
          
          // Journal 페이지
          GoRoute(
            path: '/journal',
            name: 'journal',
            builder: (context, state) => const JournalPage(),
            routes: [
              // 특정 날짜의 Journal 페이지
              GoRoute(
                path: '/:date',
                name: 'journal-date',
                builder: (context, state) {
                  final dateString = state.pathParameters['date']!;
                  final date = _parseDate(dateString);
                  return JournalPage(initialDate: date);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
```

#### 2. 라우트 파라미터 처리

```dart
// Today 페이지에서 액션 파라미터 처리
class TodayPage extends ConsumerStatefulWidget {
  final String? action; // 빠른 액션 파라미터
  
  const TodayPage({super.key, this.action});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  @override
  void initState() {
    super.initState();
    // 액션 파라미터가 있으면 해당 액션 실행
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAction(widget.action!);
      });
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case 'habits':
        _navigateToHabits();
        break;
      case 'workout':
        _navigateToWorkout();
        break;
      case 'meals':
        _navigateToMeals();
        break;
      default:
        break;
    }
  }
}
```

#### 3. 네비게이션 서비스

```dart
// lib/services/navigation_service.dart
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Today 페이지로 이동
  static void goToToday() {
    navigatorKey.currentContext?.go('/today');
  }

  /// 특정 날짜의 Journal 페이지로 이동
  static void goToJournalDate(DateTime date) {
    final dateString = _formatDateForRoute(date);
    navigatorKey.currentContext?.go('/journal/$dateString');
  }

  /// 특정 범위의 Insights 페이지로 이동
  static void goToInsightsWithRange(String range) {
    navigatorKey.currentContext?.go('/insights?range=$range');
  }
}
```

### 📱 사용 예시

```dart
// 1. 기본 페이지 이동
NavigationService.goToToday();

// 2. 파라미터와 함께 이동
NavigationService.goToJournalDate(DateTime(2024, 1, 15));

// 3. 쿼리 파라미터와 함께 이동
NavigationService.goToInsightsWithRange('30d');

// 4. 외부에서 딥링크로 접근
// habitfit://today?action=habits
// habitfit://journal/20240115
// habitfit://insights?range=7d
```

### 🔧 고급 기능

#### 1. 라우트 가드 (Route Guards)

```dart
// 인증 상태에 따른 접근 제어
redirect: (context, state) {
  final isLoggedIn = true; // TODO: 실제 인증 상태 확인
  
  // 로그인되지 않은 경우 로그인 페이지로
  if (!isLoggedIn && state.uri.toString() != '/login') {
    return '/login';
  }
  
  // 로그인된 경우 로그인 페이지에서 메인으로
  if (isLoggedIn && state.uri.toString() == '/login') {
    return '/today';
  }
  
  return null;
},
```

#### 2. 에러 페이지 처리

```dart
errorBuilder: (context, state) => Scaffold(
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text('페이지를 찾을 수 없습니다'),
        const SizedBox(height: 8),
        Text(state.uri.toString()),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.go('/today'),
          child: const Text('홈으로 돌아가기'),
        ),
      ],
    ),
  ),
),
```

---

## 💾 캐싱 시스템 (Caching System)

### 📖 개념 설명

**캐싱(Caching)**은 자주 사용되는 데이터를 임시 저장소에 보관하여 빠른 접근을 가능하게 하는 기술입니다. 네트워크 요청을 줄이고 앱의 성능을 향상시킵니다.

### 🎯 주요 장점

- **빠른 데이터 로딩**: 네트워크 요청 없이 즉시 데이터 제공
- **네트워크 사용량 감소**: 데이터 요청 횟수 최소화
- **오프라인 지원**: 네트워크 없이도 캐시된 데이터 사용
- **배터리 절약**: 네트워크 활동 감소로 전력 소비 최적화

### 🛠️ 구현 방법

#### 1. 캐시 서비스 구현

```dart
// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'habitfit_cache_';
  static const Duration _defaultExpiry = Duration(hours: 1);
  
  /// 데이터 캐시 저장
  static Future<void> setCache(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': (expiry ?? _defaultExpiry).inMilliseconds,
      };
      
      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      print('❌ 캐시 저장 실패: $e');
    }
  }
  
  /// 데이터 캐시 조회
  static Future<T?> getCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_cachePrefix$key');
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiry = cacheData['expiry'] as int;
      
      // 만료 시간 확인
      if (DateTime.now().millisecondsSinceEpoch - timestamp > expiry) {
        await removeCache(key);
        return null;
      }
      
      return cacheData['data'] as T?;
    } catch (e) {
      print('❌ 캐시 조회 실패: $e');
      return null;
    }
  }
}
```

#### 2. 캐시 키 관리

```dart
/// 캐시 키 상수
class CacheKeys {
  // Today 페이지 관련
  static const String todaySummary = 'today_summary';
  static const String todayHabits = 'today_habits';
  static const String todayWorkouts = 'today_workouts';
  
  // Journal 페이지 관련
  static const String dayLog = 'day_log';
  static const String dayHabits = 'day_habits';
  
  // Insights 페이지 관련
  static const String trendData = 'trend_data';
  static const String weeklyTrend = 'weekly_trend';
}

/// 캐시 만료 시간 상수
class CacheExpiry {
  static const Duration short = Duration(minutes: 5);      // 5분
  static const Duration medium = Duration(minutes: 30);    // 30분
  static const Duration long = Duration(hours: 1);         // 1시간
  static const Duration veryLong = Duration(hours: 6);     // 6시간
  static const Duration daily = Duration(days: 1);         // 1일
}
```

#### 3. Provider에 캐싱 적용

```dart
// lib/providers/today_summary_provider.dart
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  const cacheKey = CacheKeys.todaySummary;
  
  // 캐시에서 먼저 확인
  final cachedData = await CacheService.getCache<TodaySummary>(cacheKey);
  if (cachedData != null) {
    print('📦 Today 요약 데이터 캐시에서 로드');
    return cachedData;
  }
  
  // 캐시에 없으면 새로 로드
  print('🔄 Today 요약 데이터 새로 로드');
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('사용자가 로그인되지 않았습니다.');
  }

  // ... 데이터 로딩 로직 ...
  
  final summary = TodaySummary(/* ... */);
  
  // 캐시에 저장 (5분간 유효)
  await CacheService.setCache(cacheKey, summary, expiry: CacheExpiry.short);
  
  return summary;
});
```

### 📱 사용 예시

```dart
// 1. 데이터 캐시 저장
await CacheService.setCache(
  CacheKeys.todaySummary, 
  todayData, 
  expiry: CacheExpiry.short
);

// 2. 캐시에서 데이터 조회
final cachedData = await CacheService.getCache<TodaySummary>(CacheKeys.todaySummary);

// 3. 캐시 삭제
await CacheService.removeCache(CacheKeys.todaySummary);

// 4. 모든 캐시 삭제
await CacheService.clearAllCache();

// 5. 캐시 상태 확인
final hasCache = await CacheService.hasValidCache(CacheKeys.todaySummary);
```

### 🔧 고급 기능

#### 1. 캐시 무효화 전략

```dart
/// 오늘 요약 데이터 새로고침 Provider (캐시 무효화)
final todaySummaryRefreshProvider = Provider<void Function()>((ref) {
  return () async {
    // 캐시 삭제
    await CacheService.removeCache(CacheKeys.todaySummary);
    // Provider 무효화
    ref.invalidate(todaySummaryProvider);
  };
});
```

#### 2. 캐시 크기 관리

```dart
/// 캐시 크기 확인
static Future<int> getCacheSize() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
    return keys.length;
  } catch (e) {
    return 0;
  }
}
```

---

## ⚡ Debounce 최적화

### 📖 개념 설명

**Debounce**는 연속된 이벤트 중에서 마지막 이벤트만 처리하는 기술입니다. 사용자가 빠르게 입력하거나 버튼을 연속으로 클릭할 때, 불필요한 처리를 방지하고 성능을 최적화합니다.

### 🎯 주요 장점

- **성능 최적화**: 불필요한 함수 호출 방지
- **배터리 절약**: CPU 사용량 감소
- **사용자 경험 향상**: 부드러운 인터랙션
- **서버 부하 감소**: API 호출 횟수 최소화

### 🛠️ 구현 방법

#### 1. 기본 Debounce 클래스

```dart
// lib/utils/debounce.dart
import 'dart:async';

class Debounce {
  final int milliseconds;
  Timer? _timer;

  Debounce({required this.milliseconds});

  /// 함수 실행을 지연시킴
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// 타이머 취소
  void cancel() {
    _timer?.cancel();
  }

  /// 타이머가 활성화되어 있는지 확인
  bool get isActive => _timer?.isActive ?? false;
}
```

#### 2. 전역 Debounce 인스턴스

```dart
/// 전역 Debounce 인스턴스들
class GlobalDebounce {
  // 검색용 (300ms)
  static final Debounce search = Debounce(milliseconds: 300);
  
  // 필터링용 (200ms)
  static final Debounce filter = Debounce(milliseconds: 200);
  
  // API 호출용 (500ms)
  static final Debounce api = Debounce(milliseconds: 500);
  
  // UI 업데이트용 (100ms)
  static final Debounce ui = Debounce(milliseconds: 100);
}
```

#### 3. Debounced 검색 필드

```dart
class DebouncedSearchField extends StatefulWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;
  final Widget? prefixIcon;

  const DebouncedSearchField({
    super.key,
    this.initialValue,
    required this.hintText,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.prefixIcon,
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late TextEditingController _controller;
  late Debounce _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _debounce = Debounce(milliseconds: widget.debounceDuration.inMilliseconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        _debounce.run(() {
          widget.onChanged(value);
        });
      },
    );
  }
}
```

### 📱 사용 예시

#### 1. 기본 사용법

```dart
// Debounce 인스턴스 생성
final debounce = Debounce(milliseconds: 300);

// 함수 실행 (이전 타이머가 있으면 취소하고 새로 시작)
debounce.run(() {
  print('검색 실행: $searchQuery');
  performSearch(searchQuery);
});

// 타이머 취소
debounce.cancel();
```

#### 2. 검색 필드에서 사용

```dart
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Debounce _searchDebounce = Debounce(milliseconds: 300);
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _searchDebounce.run(() {
                _performSearch(_searchQuery);
              });
            },
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
            ),
          ),
          // 검색 결과 표시
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      // 실제 검색 로직
      print('검색 실행: $query');
    }
  }
}
```

#### 3. 전역 Debounce 사용

```dart
// 검색 기능
void searchHabits(String query) {
  GlobalDebounce.search.run(() {
    // 검색 로직 실행
    _performHabitSearch(query);
  });
}

// 필터 기능
void filterWorkouts(String filter) {
  GlobalDebounce.filter.run(() {
    // 필터 로직 실행
    _applyWorkoutFilter(filter);
  });
}

// API 호출
void fetchUserData() {
  GlobalDebounce.api.run(() {
    // API 호출 로직 실행
    _callUserDataAPI();
  });
}
```

### 🔧 고급 기능

#### 1. Debounced 필터 칩

```dart
class DebouncedFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final Duration debounceDuration;

  const DebouncedFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 200),
  });

  @override
  State<DebouncedFilterChip> createState() => _DebouncedFilterChipState();
}

class _DebouncedFilterChipState extends State<DebouncedFilterChip> {
  late Debounce _debounce;

  @override
  void initState() {
    super.initState();
    _debounce = Debounce(milliseconds: widget.debounceDuration.inMilliseconds);
  }

  @override
  void dispose() {
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: widget.selected,
      onSelected: (selected) {
        _debounce.run(() {
          widget.onChanged(selected);
        });
      },
    );
  }
}
```

#### 2. 조건부 Debounce

```dart
class ConditionalDebounce {
  final Debounce _debounce;
  final bool Function() _condition;

  ConditionalDebounce({
    required int milliseconds,
    required bool Function() condition,
  }) : _debounce = Debounce(milliseconds: milliseconds),
       _condition = condition;

  void run(VoidCallback action) {
    if (_condition()) {
      _debounce.run(action);
    } else {
      action(); // 조건이 맞지 않으면 즉시 실행
    }
  }
}

// 사용 예시
final conditionalDebounce = ConditionalDebounce(
  milliseconds: 300,
  condition: () => _isOnline, // 온라인일 때만 debounce 적용
);
```

---

## 🎯 실제 적용 사례

### 1. 검색 기능 최적화

```dart
class HabitSearchPage extends StatefulWidget {
  @override
  _HabitSearchPageState createState() => _HabitSearchPageState();
}

class _HabitSearchPageState extends State<HabitSearchPage> {
  final Debounce _searchDebounce = Debounce(milliseconds: 300);
  List<Habit> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('습관 검색')),
      body: Column(
        children: [
          // 검색 필드
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: '습관을 검색하세요',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          
          // 검색 결과
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_searchResults[index].name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebounce.run(() {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    try {
      final results = await HabitService.searchHabits(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다')),
      );
    }
  }
}
```

### 2. 캐시를 활용한 데이터 로딩

```dart
class TodaySummaryWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySummaryAsync = ref.watch(todaySummaryProvider);

    return todaySummaryAsync.when(
      data: (summary) => _buildSummaryCard(summary),
      loading: () => _buildLoadingCard(),
      error: (error, stack) => _buildErrorCard(error),
    );
  }

  Widget _buildSummaryCard(TodaySummary summary) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘의 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('습관', '${summary.completedHabits}/${summary.totalHabits}'),
                _buildStatItem('운동', '${summary.completedWorkouts}개'),
                _buildStatItem('칼로리', '${summary.calories.toInt()}kcal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
```

---

## 📚 추가 학습 자료

### 🔗 관련 문서
- [GoRouter 공식 문서](https://pub.dev/packages/go_router)
- [SharedPreferences 공식 문서](https://pub.dev/packages/shared_preferences)
- [Flutter 성능 최적화 가이드](https://docs.flutter.dev/perf)

### 🎯 실습 과제
1. **딥링크 구현**: 앱에 새로운 페이지를 추가하고 딥링크로 접근 가능하게 만들기
2. **캐싱 시스템**: 사용자 설정 데이터를 캐싱하여 앱 시작 속도 향상
3. **Debounce 적용**: 검색 기능에 Debounce를 적용하여 성능 최적화

### 💡 팁과 주의사항

#### 딥링크
- URL 구조를 일관성 있게 설계
- 파라미터 검증 로직 추가
- 에러 처리 및 폴백 페이지 구현

#### 캐싱
- 적절한 만료 시간 설정
- 메모리 사용량 모니터링
- 캐시 무효화 전략 수립

#### Debounce
- 사용 사례에 맞는 지연 시간 설정
- 메모리 누수 방지를 위한 dispose 처리
- 조건부 Debounce 적용 고려

---

이 가이드를 통해 Flutter 앱의 성능과 사용자 경험을 크게 향상시킬 수 있습니다! 🚀
