import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: SafeArea(
        child: switch (auth.memberStatus) {
          MemberLoadStatus.idle || MemberLoadStatus.loading => const Center(
            child: CircularProgressIndicator(semanticsLabel: '내 정보 불러오는 중'),
          ),
          MemberLoadStatus.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(auth.memberError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  MovieLogButton(label: '다시 시도', onPressed: auth.loadMember),
                ],
              ),
            ),
          ),
          MemberLoadStatus.success => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person_outline, size: 48),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                member!.nickname,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(member.email, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_joinedDate(member.createdAt), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Center(
                child: MovieLogButton(
                  label: '프로필 수정',
                  onPressed: () => context.push('/my/profile/edit'),
                  width: 180,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                title: const Text('이번 세션에서 등록한 평점'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/ratings'),
              ),
              ListTile(
                title: const Text('내 즐겨찾기'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/favorites'),
              ),
            ],
          ),
        },
      ),
    );
  }

  String _joinedDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day 가입';
  }
}
