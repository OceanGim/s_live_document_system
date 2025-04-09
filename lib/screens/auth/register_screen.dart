import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // 기업 관련 컨트롤러
  final _companyNameController = TextEditingController();
  final _businessNumberController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _representativePhoneController = TextEditingController();

  // 인플루언서 관련 컨트롤러
  final _platformController = TextEditingController();
  final _platformIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 사용자 유형 (기업/인플루언서)
  String _userType = '기업';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _businessNumberController.dispose();
    _representativeNameController.dispose();
    _representativePhoneController.dispose();
    _platformController.dispose();
    _platformIdController.dispose();
    super.dispose();
  }

  // 회원가입 처리
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 상태 시작
    });

    try {
      // 사용자 정보 준비
      final userData = {
        'display_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'user_type': _userType,
        'created_at': DateTime.now().toIso8601String(),
      };

      // 사용자 유형에 따른 추가 정보
      if (_userType == '기업') {
        userData['company_name'] = _companyNameController.text.trim();
        userData['business_number'] = _businessNumberController.text.trim();
        userData['representative_name'] =
            _representativeNameController.text.trim();
        userData['representative_phone'] =
            _representativePhoneController.text.trim();
      } else {
        userData['platform'] = _platformController.text.trim();
        userData['platform_id'] = _platformIdController.text.trim();
      }

      // 기본적으로 user 역할 부여
      const role = 'user';

      // AuthProvider를 통한 회원가입 요청
      await ref
          .read(authProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: role,
            userData: userData,
          );

      // 에러 메시지 확인
      final errorMessage = ref.read(authProvider).errorMessage;
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } else if (mounted) {
        // 회원가입 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다! 이메일 인증을 진행해주세요.')),
        );
        // 로그인 화면으로 돌아가기
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('회원가입 실패: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 상태 종료
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(authProvider).errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 기본 사용자 정보 섹션
                const Text(
                  '기본 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 이름 입력
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 연락처 입력
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '연락처',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '010-0000-0000',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '연락처를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return '유효한 이메일 주소를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 최소 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 확인
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 사용자 유형 선택 섹션
                const Text(
                  '사용자 유형',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 사용자 유형 라디오 버튼
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('기업'),
                        value: '기업',
                        groupValue: _userType,
                        onChanged: (value) {
                          setState(() {
                            _userType = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('인플루언서'),
                        value: '인플루언서',
                        groupValue: _userType,
                        onChanged: (value) {
                          setState(() {
                            _userType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 기업 또는 인플루언서 관련 추가 정보
                if (_userType == '기업') ...[
                  // 기업 관련 추가 정보
                  const Text(
                    '기업 정보',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 기업명
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: '기업명',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '기업명을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 사업자등록번호
                  TextFormField(
                    controller: _businessNumberController,
                    decoration: const InputDecoration(
                      labelText: '사업자등록번호',
                      prefixIcon: Icon(Icons.numbers_outlined),
                      hintText: '000-00-00000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '사업자등록번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 대표자명
                  TextFormField(
                    controller: _representativeNameController,
                    decoration: const InputDecoration(
                      labelText: '대표자명',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '대표자명을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 대표 연락처
                  TextFormField(
                    controller: _representativePhoneController,
                    decoration: const InputDecoration(
                      labelText: '대표 연락처',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '010-0000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '대표 연락처를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // 인플루언서 관련 추가 정보
                  const Text(
                    '인플루언서 정보',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 송출 플랫폼
                  TextFormField(
                    controller: _platformController,
                    decoration: const InputDecoration(
                      labelText: '송출 플랫폼',
                      prefixIcon: Icon(Icons.stream_outlined),
                      hintText: '예: YouTube, Twitch, AfreecaTV 등',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '송출 플랫폼을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 플랫폼 ID
                  TextFormField(
                    controller: _platformIdController,
                    decoration: const InputDecoration(
                      labelText: '플랫폼 ID/채널명',
                      prefixIcon: Icon(Icons.account_box_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '플랫폼 ID 또는 채널명을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // 에러 메시지 표시
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 회원가입 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.6),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('회원가입'),
                ),
                const SizedBox(height: 16),

                // 로그인 화면으로 돌아가기
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('이미 계정이 있으신가요? 로그인하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
