import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/sign_up_validation.dart';
import '../data/models/member_info.dart';
import '../data/services/api_error.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    if (member != null) return _EditProfileForm(member: member);
    return Scaffold(
      appBar: CommonAppBar(title: '프로필 수정', onBack: () => context.go('/my')),
      body: Center(
        child: auth.memberStatus == MemberLoadStatus.error
            ? MovieLogButton(label: '다시 시도', onPressed: auth.loadMember)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.member});
  final MemberInfo member;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _nickname = TextEditingController(text: widget.member.nickname);
  late final _originalNickname = widget.member.nickname;
  String? _nicknameError;
  bool _saving = false;
  bool _confirming = false;
  bool get _dirty => _nickname.text.trim() != _originalNickname;

  Future<void> _leave() async {
    if (_saving || _confirming) return;
    if (!_dirty) {
      context.go('/my');
      return;
    }

    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('편집을 그만할까요?'),
        content: const Text('저장하지 않은 변경사항이 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 편집'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (mounted && discard == true) context.go('/my');
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _nicknameError = null;
    });
    try {
      final updated = await auth.updateNickname(_nickname.text.trim());
      if (!mounted || !updated) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      context.go('/my');
    } catch (error) {
      if (!mounted || !auth.isSignedInSession(version)) return;
      final code = apiErrorCode(error);
      switch (code) {
        case 'MEMBER409_1':
          setState(() => _nicknameError = '이미 사용 중인 닉네임이에요.');
        case 'COMMON400':
          setState(() => _nicknameError = apiErrorMessage(error));
        default:
          final message = code == 'MEMBER404_1'
              ? '회원 정보를 찾을 수 없습니다.'
              : '프로필을 수정하지 못했어요. 다시 시도해 주세요.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
          if (code == 'MEMBER404_1') await auth.loadMember(force: true);
      }
    } finally {
      if (mounted && auth.isSignedInSession(version)) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: CommonAppBar(title: '프로필 수정', centerTitle: true, onBack: _leave),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: widget.member.email,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: '이메일'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nickname,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        errorText: _nicknameError,
                      ),
                      validator: validateNickname,
                      onChanged: (_) => setState(() => _nicknameError = null),
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 24),
                    MovieLogButton(
                      label: '저장',
                      onPressed: _save,
                      isLoading: _saving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
