import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;
  late final String _originalNickname;
  bool _leaving = false; // 저장 성공·'나가기' 선택 뒤에는 확인 없이 닫습니다.

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

  bool get _isDirty => _controller.text.trim() != _originalNickname;

  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    FocusScope.of(context).unfocus();
    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      _leave(); // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있습니다.
    } else if (viewModel.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
    // 401이면 expireSession()으로 signedOut → Router가 /login으로 보냅니다.
  }

  // Challenge: 변경 내용이 있을 때 뒤로가기 확인 Dialog
  Future<void> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => const _DiscardChangesDialog(),
    );
    if (leave == true && mounted) _leave();
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary80),
      ),
    );
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
          canPop: _leaving || (!saving && !_isDirty),
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || saving) return; // 저장 중에는 나가지 않습니다.
            _confirmDiscard();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                '프로필 수정',
                style: AppTextStyles.titleAppBar.copyWith(fontSize: 20),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('이메일 (변경할 수 없습니다)'),
                    TextFormField(
                      initialValue: email,
                      enabled: false, // email은 읽기 전용입니다.
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary80,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.NeutralScale400,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        disabledBorder: _border(AppColors.SecondaryScale300),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _label('닉네임'),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      onChanged: (_) {
                        viewModel.onNicknameChanged();
                        setState(() {}); // 글자 수·변경 여부 갱신
                      },
                      onSubmitted: (_) => saving ? null : _submit(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        errorText: viewModel.nicknameError,
                        enabledBorder: _border(AppColors.SecondaryScale300),
                        disabledBorder: _border(AppColors.SecondaryScale300),
                        focusedBorder: _border(AppColors.primary, width: 1.5),
                        errorBorder: _border(Colors.red.shade700),
                        focusedErrorBorder: _border(
                          Colors.red.shade700,
                          width: 1.5,
                        ),
                      ),
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => Text(
                            '$currentLength / $maxLength',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.primary80,
                            ),
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

class _DiscardChangesDialog extends StatelessWidget {
  const _DiscardChangesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '변경 내용을 버릴까요?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              '저장하지 않은 내용은 사라집니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary80,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryScale100,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('계속 수정'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MovieLogButton(
                    label: '나가기',
                    width: double.infinity,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
