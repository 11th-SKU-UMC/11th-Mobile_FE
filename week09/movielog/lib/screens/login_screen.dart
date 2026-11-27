import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movielog_text_form_field.dart';

/// 로그인 화면. (`/login`)
///
/// 이 화면은 [AuthViewModel.login]만 호출하고 직접 화면을 이동하지 않는다.
/// signedIn이 되면 Router의 redirect가 /home으로 보낸다.
/// 세션 만료로 들어온 경우에만 Snackbar로 한 번 안내한다.
/// 비밀번호는 Controller에만 있고 저장·출력하지 않는다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String sessionExpiredMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    // 화면이 열려 있는 동안 만료되는 경우와, 이미 만료된 상태로 열리는 경우를 모두 처리한다.
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 반복 표시를 막는다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(LoginScreen.sessionExpiredMessage)),
      );
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _auth.login(_email.text.trim(), _password.text);
  }

  static String? _validateEmail(String? value) =>
      (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null;

  static String? _validatePassword(String? value) =>
      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;
    final message = auth.message;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('로그인'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 72,
                    height: 72,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'MovieLog에 로그인',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                MovieLogTextFormField(
                  label: '이메일',
                  hintText: 'example@movielog.com',
                  controller: _email,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.lg),
                MovieLogTextFormField(
                  label: '비밀번호',
                  hintText: '비밀번호를 입력해 주세요',
                  controller: _password,
                  enabled: enabled,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  onFieldSubmitted: enabled ? (_) => _submit() : null,
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm + 4),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(color: colors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: loading,
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: enabled
                        ? () => context.push(AppRoutes.register)
                        : null,
                    child: const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
