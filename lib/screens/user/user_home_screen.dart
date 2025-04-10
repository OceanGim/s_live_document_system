import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/screens/document/document_workflow_screen.dart';
import 'package:s_live_document_system/screens/document/document_list_screen.dart';
import 'package:s_live_document_system/screens/user/profile_screen.dart';

/// 일반 사용자용 홈 화면
class UserHomeScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _currentIndex = 0;

  // 네비게이션 탭에 표시할 화면들
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DocumentWorkflowScreen(), // 메인 화면으로 문서 작성 워크플로우 화면 사용
      const DocumentListScreen(), // 작성한 문서 목록
      const ProfileScreen(), // 사용자 프로필
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 정보 조회
    final userInfo = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('스튜디오 대관 서류 시스템'),
        actions: [
          // 로그아웃 버튼
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: '대관 서류 작성',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '내 서류 목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 프로필'),
        ],
      ),
    );
  }
}
