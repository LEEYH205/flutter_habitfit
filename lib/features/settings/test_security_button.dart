import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 설정 페이지에 추가할 보안 테스트 버튼
class TestSecurityButton extends StatelessWidget {
  const TestSecurityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.security,
          color: Colors.red.shade700,
        ),
        title: const Text('보안 규칙 테스트'),
        subtitle: const Text('Firebase 보안 규칙 동작 확인'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('/test-security');
        },
      ),
    );
  }
}
