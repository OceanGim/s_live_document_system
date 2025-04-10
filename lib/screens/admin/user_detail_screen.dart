import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/user_model.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자 상세 정보 화면 (관리자용)
class UserDetailScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const UserDetailScreen({super.key, required this.userId});

  /// 표시할 사용자의 ID
  final String userId;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  late UserModel? _userInfo;

  // 편집 모드일 때 사용할 컨트롤러들
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'user';

  // 기업 정보 컨트롤러
  final _companyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  /// 특정 사용자 정보 로드
  Future<void> _loadUserData() async {
    ref.refresh(allUsersProvider);
    // 모든 사용자 목록에서 해당 사용자 찾기
    final asyncUsers = ref.read(allUsersProvider);
    asyncUsers.whenData((users) {
      final user = users.firstWhere(
        (user) => user.id == widget.userId,
        orElse:
            () => UserModel(
              id: '',
              email: '',
              displayName: '',
              phone: '',
              userType: '',
              createdAt: DateTime.now(),
            ),
      );

      if (user.id.isEmpty) {
        // 사용자를 찾을 수 없는 경우
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _userInfo = user;
        _selectedRole = user.role;
        _initializeControllers(user);
      });
    });
  }

  /// 컨트롤러 초기화
  void _initializeControllers(UserModel user) {
    _displayNameController.text = user.displayName;
    _phoneController.text = user.phone;
    _emailController.text = user.email;

    if (user.isCompany) {
      _companyNameController.text = user.companyName ?? '';
    }
  }

  /// 사용자 정보 업데이트
  Future<void> _saveUserData() async {
    if (_userInfo == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 업데이트할 데이터 준비
      Map<String, dynamic> updateData = {
        'display_name': _displayNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
      };

      // 사용자 유형에 따른 추가 정보
      if (_userInfo!.isCompany) {
        updateData['company_name'] = _companyNameController.text.trim();
      }

      Logger.info('사용자 정보 업데이트: $updateData', tag: 'UserDetailScreen');

      // Supabase에 데이터 업데이트
      await Supabase.instance.client
          .from('public_users')
          .update(updateData)
          .eq('user_id', widget.userId);

      // 사용자 목록 갱신
      ref.refresh(allUsersProvider);

      // 수정 완료 메시지
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자 정보가 업데이트되었습니다.')));
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        // 사용자 정보 다시 로드
        _loadUserData();
      }
    } catch (e, stack) {
      Logger.error(
        '사용자 정보 업데이트 실패',
        error: e,
        stackTrace: stack,
        tag: 'UserDetailScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업데이트 실패: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 상세 정보'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '사용자 정보 수정',
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
                  if (_userInfo != null) {
                    _initializeControllers(_userInfo!);
                  }
                });
              },
            ),
        ],
      ),
      floatingActionButton:
          _isEditing
              ? FloatingActionButton(
                onPressed: _isLoading ? null : _saveUserData,
                backgroundColor:
                    _isLoading
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.save),
              )
              : null,
      body: asyncUsers.when(
        data: (users) {
          if (_userInfo == null) {
            return const Center(child: Text('사용자 정보를 불러오는 중...'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 헤더 섹션
                _buildUserHeader(),
                const SizedBox(height: 24),

                // 기본 정보 섹션
                _buildGeneralInfoSection(),
                const SizedBox(height: 24),

                // 역할 관리 섹션 (관리자만 변경 가능)
                _buildRoleManagementSection(),
                const SizedBox(height: 24),

                // 유형별 추가 정보 섹션
                if (_userInfo!.isCompany) _buildCompanyInfoSection(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('에러 발생: $error')),
      ),
    );
  }

  /// 사용자 헤더 섹션 (프로필 이미지, 이름, 역할 등)
  Widget _buildUserHeader() {
    if (_userInfo == null) return const SizedBox.shrink();

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor:
                _userInfo!.isAdmin
                    ? Colors.deepPurple
                    : _userInfo!.isCompany
                    ? Colors.teal
                    : Colors.orange,
            child: Text(
              _userInfo!.displayName.isNotEmpty
                  ? _userInfo!.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userInfo!.displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 역할 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _userInfo!.isAdmin ? Colors.deepPurple : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userInfo!.isAdmin ? '관리자' : '일반 사용자',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              // 유형 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _userInfo!.isCompany ? Colors.teal : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userInfo!.userType,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 기본 정보 섹션 (이름, 이메일, 전화번호 등)
  Widget _buildGeneralInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기본 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: '이름',
            prefixIcon: Icon(Icons.person_outline),
          ),
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: '연락처',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '이메일',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          enabled: false, // 이메일은 변경 불가
        ),
        const SizedBox(height: 16),
        if (_userInfo != null) ...[
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('계정 생성일'),
            subtitle: Text(
              '${_userInfo!.createdAt.year}년 ${_userInfo!.createdAt.month}월 ${_userInfo!.createdAt.day}일',
            ),
          ),
          if (_userInfo!.lastSignedIn != null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('마지막 로그인'),
              subtitle: Text(
                '${_userInfo!.lastSignedIn!.year}년 ${_userInfo!.lastSignedIn!.month}월 ${_userInfo!.lastSignedIn!.day}일',
              ),
            ),
        ],
      ],
    );
  }

  /// 역할 관리 섹션 (관리자/일반 사용자 전환)
  Widget _buildRoleManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '권한 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('사용자 역할:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    onChanged:
                        _isEditing
                            ? (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              }
                            }
                            : null,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('일반 사용자')),
                      DropdownMenuItem(value: 'admin', child: Text('관리자')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 기업 정보 섹션
  Widget _buildCompanyInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기업 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: '기업명',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          enabled: _isEditing,
        ),
      ],
    );
  }
}
