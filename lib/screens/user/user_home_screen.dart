import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/screens/user/profile_screen.dart';

/// 일반 사용자용 홈 화면
class UserHomeScreen extends ConsumerWidget {
  /// 기본 생성자
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 사용자 정보 조회
    final userInfo = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('스튜디오 대관 시스템'),
        actions: [
          // 프로필 버튼
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '내 프로필',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userInfo != null)
              Text(
                '${userInfo.displayName}님 환영합니다',
                style: Theme.of(context).textTheme.titleLarge,
              )
            else
              const Text('사용자 정보를 불러오는 중...'),
            const SizedBox(height: 32),
            const Text('일반 사용자용 홈 화면 (임시)', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 32),

            // 빠른 접근 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('내 프로필 관리'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 대여 요청 화면으로 이동
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('스튜디오 대여 신청'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 내 예약 목록 화면으로 이동
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('내 예약 관리'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
