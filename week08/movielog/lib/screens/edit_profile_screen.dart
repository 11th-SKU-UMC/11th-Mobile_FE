import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_spacing.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

/// 프로필 수정 화면. (`/my/profile/edit`)
///
/// 이메일은 읽기 전용, 닉네임만 수정한다.
/// - 성공: AuthViewModel.member가 이미 교체됨 → Snackbar → 마이페이지로 pop
/// - 길이·중복·형식 오류: 화면에 남아 필드 아래 오류 표시, 입력값 유지
/// - 세션 만료: Router가 /login으로 보낸다. pop하지 않는다.
/// - 네트워크 오류: Snackbar 안내. 로그아웃하지 않고 다시 저장할 수 있다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const String savedMessage = '프로필을 수정했어요.';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _controller = TextEditingController(text: member?.nickname ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    FocusScope.of(context).unfocus();

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(EditProfileScreen.savedMessage)),
        );
      router.pop(); // 마이페이지에는 새 닉네임이 이미 반영되어 있다.
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );
    final textTheme = Theme.of(context).textTheme;

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.isSaving;
        return PopScope(
          canPop: !saving,
          child: Scaffold(
            appBar: const CommonAppBar(title: '프로필 수정', centerTitle: true),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이메일',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      initialValue: email,
                      enabled: false, // 이메일은 읽기 전용이다.
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '닉네임',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: EditProfileViewModel.maxLength,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => viewModel.onNicknameChanged(),
                      onSubmitted: saving ? null : (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: '2~12자로 입력해 주세요',
                        errorText: viewModel.nicknameError,
                      ),
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
