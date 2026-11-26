import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_me_result.dart';
import '../data/services/member_api_service.dart';
import '../data/models/update_member_request.dart';
import '../core/storage/secure_token_storage.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() =>
      _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Future<MemberMeResult> _memberFuture;

  @override
  void initState() {
    super.initState();
    _memberFuture = _loadMember();
  }

  Future<MemberMeResult> _loadMember() async {
    final service =
        context.read<MemberApiService>();

    final response =
        await service.getMyInfo();

    final result = response.result;

    if (!response.isSuccess || result == null) {
      throw Exception(response.message);
    }

    return result;
  }

  Future<void> _retry() async {
    setState(() {
      _memberFuture = _loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: FutureBuilder<MemberMeResult>(
        future: _memberFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            String message =
                '회원 정보를 불러오지 못했습니다.';

            final error = snapshot.error;

            if (error is DioException) {
              final data = error.response?.data;

              if (data is Map<String, dynamic>) {
                final serverMessage =
                    data['message'];

                if (serverMessage is String &&
                    serverMessage.isNotEmpty) {
                  message = serverMessage;
                }
              }
            }

            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child:
                          const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }

          final member = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                const CircleAvatar(
                  radius: 40,
                  child: Icon(
                    Icons.person,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    member.nickname,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    member.email,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                onPressed: () async {
                  String editedNickname = member.nickname;

                  final newNickname = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('닉네임 수정'),
                        content: TextFormField(
                          initialValue: member.nickname,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: '새 닉네임',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            editedNickname = value;
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('취소'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final value =
                                  editedNickname.trim();

                              if (value.isEmpty) {
                                return;
                              }

                              Navigator.pop(
                                dialogContext,
                                value,
                              );
                            },
                            child: const Text('수정'),
                          ),
                        ],
                      );
                    },
                  );

                  if (newNickname == null ||
                      newNickname == member.nickname ||
                      !context.mounted) {
                    return;
                  }

                  try {
                    final service =
                        context.read<MemberApiService>();

                    final response =
                        await service.updateMyInfo(
                      UpdateMemberRequest(
                        nickname: newNickname,
                      ),
                    );

                    if (!context.mounted) return;

                    if (response.isSuccess) {
                      setState(() {
                        _memberFuture = _loadMember();
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            '닉네임이 수정되었습니다.',
                          ),
                        ),
                      );
                    }
                  } on DioException catch (error) {
                    if (!context.mounted) return;

                    final data = error.response?.data;

                    String message =
                        '닉네임 수정에 실패했습니다.';

                    if (data is Map<String, dynamic>) {
                      final serverMessage =
                          data['message'];

                      if (serverMessage is String &&
                          serverMessage.isNotEmpty) {
                        message = serverMessage;
                      }
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(message),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('닉네임 수정'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () async {
                  await SecureTokenStorage.deleteAccessToken();

                  if (!context.mounted) return;

                  context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),

                const SizedBox(height: 32),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.star_outline,
                    ),
                    title: const Text(
                      '내가 등록한 평점',
                    ),
                    subtitle: const Text(
                      '작성한 영화 평점을 확인합니다.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      context.push(
                        '/my/ratings',
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/movies');
              break;
            case 2:
              context.go('/my');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon:
                Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.movie_outlined),
            selectedIcon:
                Icon(Icons.movie),
            label: '영화',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.person_outline),
            selectedIcon:
                Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}