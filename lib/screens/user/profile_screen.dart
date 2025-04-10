import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/user_model.dart';
import 'package:s_live_document_system/providers/user_provider.dart';

/// 사용자 프로필 화면
class ProfileScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // 텍스트 컨트롤러
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _companyNameController;

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기화
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _companyNameController = TextEditingController();

    // 데이터 로드
    _loadUserData();
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  // 사용자 데이터 로드
  void _loadUserData() {
    final userInfo = ref.read(userInfoProvider);
    if (userInfo != null) {
      _displayNameController.text = userInfo.displayName;
      _phoneController.text = userInfo.phone;
      _emailController.text = userInfo.email;

      if (userInfo.isCompany) {
        _companyNameController.text = userInfo.companyName ?? '';
      }
    }
  }

  // 프로필 정보 저장
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userInfo = ref.read(userInfoProvider);
      if (userInfo == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final updatedUser = userInfo.copyWith(
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName:
            userInfo.isCompany ? _companyNameController.text.trim() : null,
      );

      // UserInfoProvider를 통해 사용자 정보 업데이트
      Map<String, dynamic> updateData = {
        'display_name': updatedUser.displayName,
        'phone': updatedUser.phone,
      };

      // 사용자 유형에 따른 추가 정보
      if (userInfo.isCompany) {
        updateData['company_name'] = updatedUser.companyName;
      }

      final success = await ref
          .read(userInfoProvider.notifier)
          .updateUserInfo(updateData);

      if (!success) {
        throw Exception('프로필 업데이트 실패');
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 업데이트되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('프로필 업데이트 실패: ${e.toString()}')));
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
    final userInfo = ref.watch(userInfoProvider);

    if (userInfo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '프로필 수정',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: '수정 취소',
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // 원래 데이터 복원
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 헤더
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        userInfo.displayName.isNotEmpty
                            ? userInfo.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userInfo.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      userInfo.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        userInfo.isAdmin ? '관리자' : '일반 사용자',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          userInfo.isAdmin ? Colors.deepPurple : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        userInfo.userType,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          userInfo.isCompany ? Colors.teal : Colors.orange,
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),

              // 기본 정보 섹션
              const Text(
                '기본 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 이름 필드
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 연락처 필드
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '연락처',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '연락처를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 이메일 필드 (변경 불가)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                enabled: false, // 이메일은 변경 불가
              ),
              const SizedBox(height: 24),

              // 계정 생성일 정보
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('계정 생성일'),
                subtitle: Text(
                  '${userInfo.createdAt.year}년 ${userInfo.createdAt.month}월 ${userInfo.createdAt.day}일',
                ),
              ),

              // 마지막 로그인 정보
              if (userInfo.lastSignedIn != null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('마지막 로그인'),
                  subtitle: Text(
                    '${userInfo.lastSignedIn!.year}년 ${userInfo.lastSignedIn!.month}월 ${userInfo.lastSignedIn!.day}일',
                  ),
                ),

              const Divider(height: 32),

              // 기업 정보 섹션 (기업인 경우)
              if (userInfo.isCompany) ...[
                const Text(
                  '기업 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 기업명
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: '기업명',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '기업명을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // 저장 버튼 (편집 모드일 때만 표시)
              if (_isEditing)
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('프로필 저장'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
