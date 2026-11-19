import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/async_state_views.dart';
import '../widgets/common_app_bar.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    // 토큰과 member를 지우고 signedOut이 되면 Router가 /login으로 보냅니다.
    await context.read<AuthViewModel>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        showLogo: true,
        actions: [
          TextButton(
            onPressed: auth.isSignedIn ? () => _logout(context) : null,
            child: const Text('로그아웃'),
          ),
        ],
      ),
      // Challenge: MainScreen이 시작한 내 정보 로딩 상태를 구독합니다.
      body: switch (auth.memberStatus) {
        MemberLoadStatus.error when member == null => ErrorView(
          message: '내 정보를 불러오지 못했어요.',
          onRetry: () => context.read<AuthViewModel>().loadMember(force: true),
        ),
        _ when member == null => const LoadingView(),
        _ => _MyPageContent(member: member),
      },
    );
  }
}

class _MyPageContent extends StatelessWidget {
  const _MyPageContent({required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(member: member),
          const ProfileEditButton(),
          const SizedBox(height: 20),
          const StatsSection(),
          const SizedBox(height: 22),
          const GenreSection(),
          const SizedBox(height: 22),
          const Divider(color: AppColors.border),
          _MyPageMenu(
            icon: Icons.star_outline,
            title: '내가 등록한 평점',
            onTap: () => context.push('/my/ratings'),
          ),
          const Divider(color: AppColors.border),
        ],
      ),
    );
  }
}

class _MyPageMenu extends StatelessWidget {
  const _MyPageMenu({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// GET me로 받은 이메일·닉네임·가입일을 표시합니다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 18),
          ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, size: 48, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(member.nickname, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(member.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          // Challenge: "2026.10.10 가입" 형식
          Text(member.joinedLabel, style: AppTextStyles.caption),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key});

  @override
  Widget build(BuildContext context) {
    final hasMember = context.select<AuthViewModel, bool>(
      (auth) => auth.member != null,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      alignment: Alignment.center,
      child: TextButton(
        // 내 정보가 있어야 수정 화면에 기존 값을 채울 수 있습니다.
        onPressed: hasMember ? () => context.push('/my/profile/edit') : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          '프로필 수정',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class ProfileStat {
  const ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

// 프로필·통계 수치는 디자인 예시 값입니다.
const _profileStats = [
  ProfileStat(label: '본 영화', value: '342'),
  ProfileStat(label: '평점', value: '4.2'),
  ProfileStat(label: '즐겨찾기', value: '58'),
];

const _favoriteGenres = ['드라마', 'SF', '애니메이션'];

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _profileStats.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: StatItem(
              label: _profileStats[i].label,
              value: _profileStats[i].value,
            ),
          ),
        ],
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class GenreSection extends StatelessWidget {
  const GenreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 장르',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _favoriteGenres
              .map((genre) => GenreChip(label: genre))
              .toList(),
        ),
      ],
    );
  }
}

class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
