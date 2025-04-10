import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s_live_document_system/models/user_model.dart';
import 'package:s_live_document_system/providers/user_provider.dart';
import 'package:s_live_document_system/screens/admin/user_detail_screen.dart';

/// 관리자용 사용자 목록 화면
class UserListScreen extends ConsumerStatefulWidget {
  /// 기본 생성자
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String _filterType = ''; // 빈 문자열은 모든 사용자 표시
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 검색 조건에 맞게 사용자 필터링
  List<UserModel> _filterUsersBySearch(List<UserModel> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          (user.companyName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 유형에 따라 필터링된 목록
    final filteredUsers = ref.watch(filteredUsersProvider(_filterType));

    // 검색 쿼리에 따라 추가 필터링
    final searchFilteredUsers = _filterUsersBySearch(filteredUsers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 관리'),
        actions: [
          // 필터 버튼
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '사용자 유형 필터',
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: '', child: Text('모든 사용자')),
                  const PopupMenuItem(value: '기업', child: Text('기업 사용자')),
                  const PopupMenuItem(value: '인플루언서', child: Text('인플루언서 사용자')),
                ],
          ),
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () {
              ref.refresh(allUsersProvider);
            },
          ),
        ],
      ),
      // 새 사용자 추가 FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 새 사용자 추가 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 추가 기능은 아직 구현되지 않았습니다.')),
          );
        },
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름, 이메일, 전화번호로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 필터 정보 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('현재 필터: ${_filterType.isEmpty ? '모든 사용자' : _filterType}'),
                const Spacer(),
                Text('총 ${searchFilteredUsers.length}명'),
              ],
            ),
          ),

          // 사용자 목록
          Expanded(
            child: ref
                .watch(allUsersProvider)
                .when(
                  data: (users) {
                    if (searchFilteredUsers.isEmpty) {
                      return const Center(child: Text('표시할 사용자가 없습니다.'));
                    }

                    return ListView.builder(
                      itemCount: searchFilteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = searchFilteredUsers[index];
                        return UserListTile(user: user);
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('에러 발생: $error')),
                ),
          ),
        ],
      ),
    );
  }
}

/// 사용자 목록 아이템
class UserListTile extends StatelessWidget {
  /// 기본 생성자
  const UserListTile({super.key, required this.user});

  /// 표시할 사용자 정보
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor:
              user.isAdmin
                  ? Colors.deepPurple
                  : user.isCompany
                  ? Colors.teal
                  : Colors.orange,
          radius: 24,
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            // 관리자 배지
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '관리자',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 4),
            Text(user.phone),
            const SizedBox(height: 4),
            Row(
              children: [
                // 사용자 유형 표시
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user.isCompany ? Colors.teal : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.userType,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // 기업인 경우 기업명 표시
                if (user.isCompany && user.companyName != null)
                  Expanded(
                    child: Text(
                      '${user.companyName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // 인플루언서인 경우에 대한 처리는 제거
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(userId: user.id),
            ),
          );
        },
      ),
    );
  }
}
