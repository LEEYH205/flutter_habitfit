import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 보안 규칙 테스트 페이지 (수정된 버전)
class TestSecurityPage extends StatefulWidget {
  const TestSecurityPage({super.key});

  @override
  State<TestSecurityPage> createState() => _TestSecurityPageState();
}

class _TestSecurityPageState extends State<TestSecurityPage> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보안 규칙 테스트'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 사용자 정보
            _buildUserInfo(),
            const SizedBox(height: 20),

            // 테스트 버튼
            _buildTestButtons(),
            const SizedBox(height: 20),

            // 테스트 결과
            Expanded(
              child: _buildTestResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 사용자 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('이메일: ${user?.email ?? "로그인되지 않음"}'),
            Text('UID: ${user?.uid ?? "N/A"}'),
            Text('익명: ${user?.isAnonymous ?? false}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '테스트 실행',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runBasicTests,
              child: const Text('기본 테스트'),
            ),
            ElevatedButton(
              onPressed: _isRunning ? null : _runAdminTests,
              child: const Text('관리자 테스트'),
            ),
            ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              child: const Text('전체 테스트'),
            ),
            ElevatedButton(
              onPressed: _clearResults,
              child: const Text('결과 지우기'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '테스트 결과',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isRunning) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  final result = _testResults[index];
                  Color color = Colors.black;
                  if (result.contains('✅')) color = Colors.green;
                  if (result.contains('❌')) color = Colors.red;
                  if (result.contains('⚠️')) color = Colors.orange;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      result,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addResult(String result) {
    setState(() {
      _testResults
          .add('${DateTime.now().toString().substring(11, 19)} - $result');
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _runBasicTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('🔒 기본 보안 규칙 테스트 시작');
    _addResult('=' * 50);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _addResult('❌ 로그인된 사용자가 없습니다. 먼저 로그인하세요.');
      setState(() => _isRunning = false);
      return;
    }

    _addResult('👤 현재 사용자: ${user.email} (${user.uid})');
    _addResult('');

    // 테스트 1: 본인 문서 접근
    await _testOwnDocumentAccess(user.uid);

    // 테스트 2: 다른 사용자 문서 접근 (실패해야 함)
    await _testOtherUserDocumentAccess();

    // 테스트 3: 본인 습관 데이터 접근
    await _testOwnHabitAccess(user.uid);

    _addResult('=' * 50);
    _addResult('✅ 기본 테스트 완료');

    setState(() => _isRunning = false);
  }

  Future<void> _runAdminTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('👑 관리자 권한 테스트 시작');
    _addResult('=' * 50);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _addResult('❌ 로그인된 사용자가 없습니다.');
      setState(() => _isRunning = false);
      return;
    }

    await _testAdminAccess(user.uid);

    _addResult('=' * 50);
    _addResult('✅ 관리자 테스트 완료');

    setState(() => _isRunning = false);
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    await _runBasicTests();
    await _runAdminTests();
    await _testInvalidDataWrite();

    _addResult('🎉 모든 테스트 완료!');

    setState(() => _isRunning = false);
  }

  Future<void> _testOwnDocumentAccess(String uid) async {
    _addResult('📋 테스트 1: 본인 문서 접근');
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _addResult('✅ 성공: 본인 문서 접근 가능');
      } else {
        _addResult('⚠️ 문서가 존재하지 않음 (정상)');
      }
    } catch (e) {
      _addResult('❌ 실패: $e');
    }
    _addResult('');
  }

  Future<void> _testOtherUserDocumentAccess() async {
    _addResult('📋 테스트 2: 다른 사용자 문서 접근 (실패해야 함)');
    try {
      final fakeUid = 'fake_user_id_12345';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fakeUid)
          .get();
      _addResult('⚠️ 예상치 못한 결과: 다른 사용자 문서 접근 가능');
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _addResult('✅ 성공: 다른 사용자 문서 접근 차단됨');
      } else {
        _addResult('❌ 예상과 다른 오류: $e');
      }
    }
    _addResult('');
  }

  Future<void> _testOwnHabitAccess(String uid) async {
    _addResult('📋 테스트 3: 본인 습관 데이터 접근');
    try {
      final query = await FirebaseFirestore.instance
          .collection('user_habits')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      _addResult('✅ 성공: 본인 습관 데이터 접근 가능 (${query.docs.length}개 문서)');
    } catch (e) {
      _addResult('❌ 실패: $e');
    }
    _addResult('');
  }

  Future<void> _testAdminAccess(String uid) async {
    _addResult('📋 테스트 4: 관리자 권한 확인');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addResult('❌ 사용자 로그인 안됨');
        return;
      }

      final idTokenResult = await user.getIdTokenResult(true); // Force refresh
      final claims = idTokenResult.claims;

      final isAdmin = claims?['admin'] == true || claims?['role'] == 'admin';
      final isCoach = claims?['coach'] == true || claims?['role'] == 'coach';

      _addResult('👑 관리자 권한: ${isAdmin ? "✅ 있음" : "❌ 없음"}');
      _addResult('🏃 코치 권한: ${isCoach ? "✅ 있음" : "❌ 없음"}');

      if (isAdmin) {
        try {
          await FirebaseFirestore.instance
              .collection('admin_promotions')
              .limit(1)
              .get();
          _addResult('✅ 관리자 전용 컬렉션 접근 가능');
        } catch (e) {
          _addResult('❌ 관리자 전용 컬렉션 접근 실패: $e');
        }
      }
    } catch (e) {
      _addResult('❌ 권한 확인 실패: $e');
    }
    _addResult('');
  }

  Future<void> _testInvalidDataWrite() async {
    _addResult('📋 테스트 5: 잘못된 데이터 쓰기 시도');
    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('user_habits').add({
        'uid': 'fake_user_id_12345',
        'title': '테스트 습관',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _addResult('⚠️ 예상치 못한 결과: 잘못된 데이터 쓰기 성공');
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _addResult('✅ 성공: 잘못된 데이터 쓰기 차단됨');
      } else {
        _addResult('❌ 예상과 다른 오류: $e');
      }
    }
    _addResult('');
  }
}
