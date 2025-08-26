import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Channel Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlatformChannelTestPage(),
    );
  }
}

class PlatformChannelTestPage extends StatefulWidget {
  const PlatformChannelTestPage({super.key});

  @override
  _PlatformChannelTestPageState createState() =>
      _PlatformChannelTestPageState();
}

class _PlatformChannelTestPageState extends State<PlatformChannelTestPage> {
  static const platform = MethodChannel('healthkit_route_channel');

  String _result = '아직 테스트하지 않음';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Platform Channel 테스트'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testBasicCommunication,
              child: Text('1. 기본 통신 테스트'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testHealthKitPermission,
              child: Text('2. HealthKit 권한 테스트'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testLogging,
              child: Text('3. 로깅 테스트'),
            ),
            SizedBox(height: 32),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테스트 결과:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_result),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testBasicCommunication() async {
    setState(() {
      _isLoading = true;
      _result = '기본 통신 테스트 중...';
    });

    try {
      print('🔍 Flutter: 기본 통신 테스트 시작');

      final String result =
          await platform.invokeMethod('testBasicCommunication');

      print('🔍 Flutter: iOS 응답 받음: $result');

      setState(() {
        _result = '✅ 기본 통신 성공!\n\niOS 응답: $result';
      });
    } on PlatformException catch (e) {
      print('❌ Flutter: PlatformException 발생: ${e.message}');
      setState(() {
        _result = '❌ 기본 통신 실패\n\n오류: ${e.message}\n코드: ${e.code}';
      });
    } catch (e) {
      print('❌ Flutter: 예상치 못한 오류: $e');
      setState(() {
        _result = '❌ 예상치 못한 오류\n\n오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testHealthKitPermission() async {
    setState(() {
      _isLoading = true;
      _result = 'HealthKit 권한 테스트 중...';
    });

    try {
      print('🔍 Flutter: HealthKit 권한 테스트 시작');

      final bool result =
          await platform.invokeMethod('requestHealthKitPermissions');

      print('🔍 Flutter: HealthKit 권한 결과: $result');

      setState(() {
        _result = '✅ HealthKit 권한 테스트 완료!\n\n권한 승인: $result';
      });
    } on PlatformException catch (e) {
      print('❌ Flutter: PlatformException 발생: ${e.message}');
      setState(() {
        _result = '❌ HealthKit 권한 테스트 실패\n\n오류: ${e.message}\n코드: ${e.code}';
      });
    } catch (e) {
      print('❌ Flutter: 예상치 못한 오류: $e');
      setState(() {
        _result = '❌ 예상치 못한 오류\n\n오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogging() async {
    setState(() {
      _isLoading = true;
      _result = '로깅 테스트 중...';
    });

    try {
      print('🔍 Flutter: 로깅 테스트 시작');

      final String result = await platform.invokeMethod('testLogging');

      print('🔍 Flutter: 로깅 테스트 결과: $result');

      setState(() {
        _result = '✅ 로깅 테스트 완료!\n\niOS 응답: $result';
      });
    } on PlatformException catch (e) {
      print('❌ Flutter: PlatformException 발생: ${e.message}');
      setState(() {
        _result = '❌ 로깅 테스트 실패\n\n오류: ${e.message}\n코드: ${e.code}';
      });
    } catch (e) {
      print('❌ Flutter: 예상치 못한 오류: $e');
      setState(() {
        _result = '❌ 예상치 못한 오류\n\n오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
