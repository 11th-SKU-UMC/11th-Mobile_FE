import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';

/// 이메일은 읽기 전용, 닉네임만 수정합니다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;
  late final String _originalNickname;

  /// 저장 성공 뒤에는 변경 확인 Dialog 없이 나갑니다.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _originalNickname = context.read<AuthViewModel>().member?.nickname ?? '';
    _controller = TextEditingController(text: _originalNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasChanges => _controller.text.trim() != _originalNickname;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      setState(() => _leaving = true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('프로필을 수정했어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있습니다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(viewModel.message!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    // 401이면 AuthViewModel이 signedOut이 되고 Router가 /login으로 보냅니다.
  }

  /// Challenge: 변경 내용이 있으면 나가기 전에 확인합니다.
  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('수정을 취소할까요?'),
        content: const Text('변경한 내용이 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 수정'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.isSaving;
        return PopScope(
          // 저장 중에는 나갈 수 없고, 변경 내용이 있으면 확인 Dialog를 거칩니다.
          canPop: _leaving || (!saving && !_hasChanges),
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || saving) return;
            _confirmLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text(
                '프로필 수정',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: email,
                      enabled: false, // 이메일은 읽기 전용입니다.
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        viewModel.onNicknameChanged();
                        setState(() {}); // 변경 여부를 PopScope에 반영합니다.
                      },
                      onSubmitted: (_) {
                        if (!saving) _submit();
                      },
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        helperText: '2~12자',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        errorText: viewModel.nicknameError,
                      ),
                    ),
                    const Spacer(),
                    if (!_hasChanges)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '바뀐 내용이 없어요.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      height: 48,
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
