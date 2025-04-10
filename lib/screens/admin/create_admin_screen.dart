import 'package:flutter/material.dart';
import 'package:s_live_document_system/utils/admin_creator.dart';

/// 관리자 계정 생성 화면
class CreateAdminScreen extends StatefulWidget {
  /// 기본 생성자
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 기본값 설정
    _emailController.text = 'admin@slive.com';
    _passwordController.text = 'S-livestudio';
    _nameController.text = 'S-Live 관리자';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 관리자 계정 생성
  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AdminCreator.createAdminAccount(
        context,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 계정 생성')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 설명 카드
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '관리자 계정 생성',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '새 관리자 계정을 생성하거나 기존 계정에 관리자 권한을 부여합니다. '
                        '이 기능은 보안에 영향을 미치므로 신중하게 사용하세요.',
                      ),
                    ],
                  ),
                ),
              ),

              // 이메일 입력
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'admin@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력하세요';
                  }
                  if (!value.contains('@')) {
                    return '유효한 이메일을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  hintText: '8자 이상 입력',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력하세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 이름 입력
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '표시 이름',
                  hintText: '관리자 이름 입력',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 생성 버튼
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createAdmin,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.admin_panel_settings),
                label: const Text('관리자 계정 생성/권한 부여'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
