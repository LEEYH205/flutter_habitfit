import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/bug_report_service.dart';

/// 버그 리포트 페이지
class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key});

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  final BugReportService _bugReportService = BugReportService();
  final _formKey = GlobalKey<FormState>();

  // 폼 컨트롤러
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _emailController = TextEditingController();

  // 상태
  bool _isLoading = false;
  String _reportType = 'bug';
  int _rating = 5;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      switch (_reportType) {
        case 'bug':
          success = await _bugReportService.sendBugReport(
            title: _titleController.text,
            description: _descriptionController.text,
            stepsToReproduce:
                _stepsController.text.isNotEmpty ? _stepsController.text : null,
            expectedBehavior: _expectedController.text.isNotEmpty
                ? _expectedController.text
                : null,
            actualBehavior: _actualController.text.isNotEmpty
                ? _actualController.text
                : null,
            userEmail:
                _emailController.text.isNotEmpty ? _emailController.text : null,
          );
          break;
        case 'feedback':
          success = await _bugReportService.sendFeedback(
            feedback: _descriptionController.text,
            type: 'general',
            userEmail:
                _emailController.text.isNotEmpty ? _emailController.text : null,
            rating: _rating,
          );
          break;
        case 'feature':
          success = await _bugReportService.sendFeedback(
            feedback: _descriptionController.text,
            type: 'feature',
            userEmail:
                _emailController.text.isNotEmpty ? _emailController.text : null,
          );
          break;
      }

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('전송에 실패했습니다. 나중에 다시 시도해주세요.');
      }
    } catch (e) {
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('전송 완료'),
          ],
        ),
        content: const Text('보고서가 성공적으로 전송되었습니다.\n개발팀에서 검토 후 답변드리겠습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그만 닫기
              _clearForm(); // 폼 초기화
            },
            child: const Text('새 보고서 작성'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              context.go('/settings'); // 설정 페이지로 직접 이동
            },
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('전송 실패'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _stepsController.clear();
    _expectedController.clear();
    _actualController.clear();
    _emailController.clear();
    setState(() {
      _rating = 5;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _bugReportService.sendTestMessage();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 테스트 메시지가 성공적으로 전송되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 테스트 메시지 전송에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('테스트 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildWebhookStatus() {
    final isConfigured = _bugReportService.isWebhookConfigured();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConfigured ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isConfigured ? Colors.green : Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error,
            color: isConfigured ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConfigured
                  ? '✅ Discord 웹훅 연결됨 - 버그 리포트 시스템 활성화'
                  : '❌ Discord 웹훅 미설정 - 버그 리포트 시스템 비활성화',
              style: TextStyle(
                color:
                    isConfigured ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 버그 리포트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: const Icon(Icons.bug_report),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _testConnection,
            tooltip: '연결 테스트',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 웹훅 상태 표시
              _buildWebhookStatus(),
              const SizedBox(height: 16),
              // 보고서 타입 선택
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '보고서 타입',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildReportTypeChip('bug', '🐛 버그 리포트', Colors.red),
                          _buildReportTypeChip(
                              'feedback', '💬 피드백', Colors.blue),
                          _buildReportTypeChip(
                              'feature', '✨ 기능 요청', Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 제목
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목 *',
                  hintText: '문제를 간단히 설명해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 설명
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '상세 설명 *',
                  hintText: '문제나 제안사항을 자세히 설명해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '설명을 입력해주세요';
                  }
                  return null;
                },
              ),

              // 버그 리포트인 경우 추가 필드
              if (_reportType == 'bug') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stepsController,
                  decoration: const InputDecoration(
                    labelText: '재현 단계',
                    hintText: '문제를 재현하는 단계를 설명해주세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expectedController,
                  decoration: const InputDecoration(
                    labelText: '예상 동작',
                    hintText: '정상적으로 동작했을 때 어떻게 되어야 하는지 설명해주세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actualController,
                  decoration: const InputDecoration(
                    labelText: '실제 동작',
                    hintText: '실제로 어떻게 동작하는지 설명해주세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.error),
                  ),
                  maxLines: 2,
                ),
              ],

              // 피드백인 경우 평점
              if (_reportType == 'feedback') ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '앱 만족도',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                              child: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text('$_rating/5 점'),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 이메일 (선택사항)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일 (선택사항)',
                  hintText: '답변을 받을 이메일 주소',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 제출 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('전송 중...'),
                          ],
                        )
                      : const Text(
                          '보고서 전송',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 안내 메시지
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '안내사항',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 보고서는 개발팀의 디스코드 채널로 전송됩니다\n'
                        '• 개인정보는 보호되며 개발 목적으로만 사용됩니다\n'
                        '• 가능한 한 자세한 정보를 제공해주시면 도움이 됩니다\n'
                        '• 긴급한 문제는 별도로 연락해주세요',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if (!_bugReportService.isWebhookConfigured())
                        const Text(
                          '⚠️ 디스코드 웹훅이 설정되지 않았습니다. 개발자에게 문의하세요.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeChip(String value, String label, Color color) {
    final isSelected = _reportType == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _reportType = value;
          });
        }
      },
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      backgroundColor: Colors.grey.withOpacity(0.1),
    );
  }
}
