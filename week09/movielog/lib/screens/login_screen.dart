import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/email_preference.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_text_form_field.dart';

/// 로그인 화면은 AuthViewModel.login()만 호출하고 직접 이동하지 않습니다.
/// signedIn이 되면 Router의 redirect가 /home으로 보냅니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  /// 회원가입 직후 넘겨받은 이메일입니다.
  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _password = TextEditingController();
  final _passwordFocusNode = FocusNode();
  late final AuthViewModel _auth;
  late final EmailPreference _emailPreference;

  bool _obscurePassword = true;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _emailPreference = context.read<EmailPreference>();
    // 로그인 화면이 열려 있는 중에 만료되는 경우와, 이미 만료된 상태로 열리는 경우를 모두 처리합니다.
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _restoreSavedEmail();
  }

  Future<void> _restoreSavedEmail() async {
    try {
      final saved = await _emailPreference.read();
      if (!mounted || saved == null || saved.isEmpty) return;
      setState(() {
        _rememberEmail = true;
        // 회원가입 직후 넘겨받은 이메일이 있으면 그 값을 우선합니다.
        if ((widget.initialEmail ?? '').isEmpty) _email.text = saved;
      });
    } catch (_) {
      // 이메일 저장은 편의 기능이므로 실패해도 로그인을 막지 않습니다.
    }
  }

  /// 로그인 → 회원가입 → 로그인으로 돌아오면 GoRouter가 이 State를 재사용하므로
  /// 새로 넘겨받은 이메일을 여기서 반영합니다.
  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final email = widget.initialEmail;
    if (email != null && email.isNotEmpty && email != oldWidget.initialEmail) {
      _email.text = email;
      _password.clear();
    }
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 같은 Snackbar가 반복되지 않게 합니다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    await _auth.login(email, _password.text);
    if (!mounted || !_auth.isSignedIn) return;
    // 비밀번호와 토큰은 저장하지 않고, 체크한 경우 이메일만 저장합니다.
    try {
      if (_rememberEmail) {
        await _emailPreference.save(email);
      } else {
        await _emailPreference.clear();
      }
    } catch (_) {
      // 편의 기능 실패는 무시합니다.
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          '로그인',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: SvgPicture.asset(
                        'assets/logos/movielog_logo.svg',
                        width: 72,
                        height: 72,
                        semanticsLabel: 'MovieLog 로고',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MovieLog에 로그인',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 40),
                    MovieLogTextFormField(
                      controller: _email,
                      label: '이메일',
                      hint: 'example@umc.com',
                      prefixIcon: Icons.mail_outline,
                      enabled: enabled,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? '이메일을 입력해 주세요.'
                          : null,
                      onFieldSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    MovieLogTextFormField(
                      controller: _password,
                      focusNode: _passwordFocusNode,
                      label: '비밀번호',
                      hint: '비밀번호 입력',
                      prefixIcon: Icons.lock_outline,
                      enabled: enabled,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                      onFieldSubmitted: (_) {
                        if (enabled) _submit();
                      },
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    // Challenge: 이메일만 저장합니다.
                    CheckboxListTile(
                      value: _rememberEmail,
                      onChanged: enabled
                          ? (value) =>
                                setState(() => _rememberEmail = value ?? false)
                          : null,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: const Text(
                        '이메일 저장',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    if (auth.message != null && !auth.isSignedIn) ...[
                      const SizedBox(height: 4),
                      Text(
                        auth.message!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    MovieLogButton(
                      label: '로그인',
                      width: double.infinity,
                      height: 48,
                      isLoading: loading,
                      onPressed: enabled ? _submit : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: enabled
                          ? () => context.push('/register')
                          : null,
                      child: const Text('아직 계정이 없으신가요? 회원가입'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
