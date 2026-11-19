import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/services/email_preference.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

// 로그인 화면은 AuthViewModel.login()만 호출합니다.
// 성공 후 화면 이동은 Router(redirect)가 담당하므로 context.go('/home')를 쓰지 않습니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailPreference = EmailPreference();
  late final AuthViewModel _auth;
  bool _rememberEmail = false; // Challenge: 이메일 저장

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showSessionExpired);
    // 이미 만료된 상태로 화면이 처음 열리는 경우도 처리합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final saved = await _emailPreference.read();
      if (!mounted || saved == null || saved.isEmpty) return;
      setState(() {
        _email.text = saved;
        _rememberEmail = true;
      });
    } catch (_) {
      // 저장된 이메일을 못 읽어도 로그인은 계속할 수 있습니다.
    }
  }

  // ViewModel은 '만료로 로그아웃됐다'는 사실만 보관하고, Snackbar는 화면이 띄웁니다.
  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 반복 표시를 막습니다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
      );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final remember = _rememberEmail;
    await _auth.login(email, _password.text);
    if (_auth.status != AuthStatus.signedIn) return;
    // 로그인 성공 뒤에만 이메일 저장 여부를 반영합니다. (비밀번호·토큰은 저장 안 함)
    try {
      if (remember) {
        await _emailPreference.save(email);
      } else {
        await _emailPreference.clear();
      }
    } catch (_) {
      // 이메일 저장 실패는 로그인 결과에 영향을 주지 않습니다.
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _decoration({String? errorText}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorText: errorText,
      enabledBorder: _border(AppColors.SecondaryScale300),
      disabledBorder: _border(AppColors.SecondaryScale300),
      focusedBorder: _border(AppColors.primary, width: 1.5),
      errorBorder: _border(Colors.red.shade700),
      focusedErrorBorder: _border(Colors.red.shade700, width: 1.5),
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
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          '로그인',
          style: AppTextStyles.titleAppBar.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
                Center(
                  child: SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 56,
                    height: 56,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MovieLog에 로그인',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                _label('이메일'),
                TextFormField(
                  controller: _email,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(),
                  onChanged: (_) => auth.clearMessage(),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                _label('비밀번호'),
                TextFormField(
                  controller: _password,
                  enabled: enabled,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  // 로그인 실패(AUTH401_1)·저장 실패 문구를 비밀번호 칸 아래에 보여줍니다.
                  decoration: _decoration(errorText: auth.message),
                  onChanged: (_) => auth.clearMessage(),
                  onFieldSubmitted: (_) => enabled ? _submit() : null,
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),
                // Challenge: 이메일 저장 체크박스
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberEmail,
                        onChanged: enabled
                            ? (value) =>
                                  setState(() => _rememberEmail = value ?? false)
                            : null,
                        activeColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.SecondaryScale300),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: enabled
                          ? () => setState(() => _rememberEmail = !_rememberEmail)
                          : null,
                      child: const Text('이메일 저장'),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: loading, // 통신 중 비활성화 + 로딩
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '계정이 없나요?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary80,
                      ),
                    ),
                    TextButton(
                      onPressed: enabled ? () => context.push('/register') : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(left: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '회원가입',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
