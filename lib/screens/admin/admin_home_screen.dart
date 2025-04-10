import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/providers/auth_provider.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/screens/admin/create_admin_screen.dart';
import 'package:s_live_document_system/screens/admin/user_list_screen.dart';
import 'package:s_live_document_system/screens/database/database_migration_screen.dart';
import 'package:s_live_document_system/utils/supabase_sql_executor.dart';

/// 관리자용 홈 화면
class AdminHomeScreen extends ConsumerWidget {
  /// 기본 생성자
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 관리자 정보
    final userInfo = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 관리자 환영 메시지
            if (userInfo != null) ...[
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        userInfo.displayName.isNotEmpty
                            ? userInfo.displayName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '환영합니다, ${userInfo.displayName} 관리자님',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '마지막 로그인: ${userInfo.lastSignedIn != null ? '${userInfo.lastSignedIn!.year}년 ${userInfo.lastSignedIn!.month}월 ${userInfo.lastSignedIn!.day}일' : '정보 없음'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 관리 메뉴 섹션
            const Text(
              '관리자 기능',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 관리 메뉴 그리드
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                // 관리자 생성 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: '관리자 생성',
                  description: '새 관리자 계정 생성 및 권한 부여',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateAdminScreen(),
                      ),
                    );
                  },
                ),
                // 데이터베이스 마이그레이션 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.update,
                  title: 'DB 마이그레이션',
                  description: '데이터베이스 테이블 및 정책 구성',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DatabaseMigrationScreen(),
                      ),
                    );
                  },
                ),
                // SQL 실행 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.storage,
                  title: 'SQL 실행',
                  description: '데이터베이스 쿼리 및 스크립트 실행',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SqlExecutorScreen(),
                      ),
                    );
                  },
                ),
                // 사용자 관리 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.people,
                  title: '사용자 관리',
                  description: '사용자 계정 정보 조회 및 관리',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserListScreen(),
                      ),
                    );
                  },
                ),
                // 예약 관리 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.calendar_month,
                  title: '예약 관리',
                  description: '스튜디오 대여 예약 조회 및 관리',
                  onTap: () {
                    // TODO: 예약 관리 화면으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('예약 관리 기능은 아직 구현되지 않았습니다.')),
                    );
                  },
                ),
                // 장비 관리 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.videocam,
                  title: '장비 관리',
                  description: '촬영 장비 정보 및 재고 관리',
                  onTap: () {
                    // TODO: 장비 관리 화면으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('장비 관리 기능은 아직 구현되지 않았습니다.')),
                    );
                  },
                ),
                // 통계 및 보고서 메뉴
                _buildMenuCard(
                  context,
                  icon: Icons.bar_chart,
                  title: '통계 및 보고서',
                  description: '사용 통계 및 보고서 생성',
                  onTap: () {
                    // TODO: 통계 화면으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('통계 기능은 아직 구현되지 않았습니다.')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 시스템 상태 섹션
            const Text(
              '시스템 상태',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 시스템 상태 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Supabase 백엔드 연결 정상'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.storage, color: Colors.blue),
                      title: const Text('등록된 사용자 수'),
                      trailing: FutureBuilder<int>(
                        future: _getUserCount(ref),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          return Text(
                            '${snapshot.data ?? 0}명',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 관리 메뉴 카드 위젯
  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 전체 사용자 수 조회
  Future<int> _getUserCount(WidgetRef ref) async {
    final asyncUsers = await ref.read(allUsersProvider.future);
    return asyncUsers.length;
  }
}
