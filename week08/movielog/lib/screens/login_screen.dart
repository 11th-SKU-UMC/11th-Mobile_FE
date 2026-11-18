import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sign_up_validation.dart';
import '../data/models/login_models.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _emailKey = 'movielog.saved_email';
  late final _preferences = SharedPreferences.getInstance();
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberEmail = false;
  bool _ready = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _loadEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<AuthViewModel>().consumeSessionExpired()) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
    });
  }

  Future<void> _loadEmail() async {
    String? savedEmail;
    try {
      savedEmail = (await _preferences).getString(_emailKey);
    } catch (_) {
      // Remembering the email is optional and must not block sign-in.
    }
    if (!mounted) return;
    setState(() {
      if (savedEmail != null) {
        _email.text = savedEmail;
        _rememberEmail = true;
      }
      _ready = true;
    });
  }

  Future<void> _submit() async {
    if (!_ready || !_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final email = _email.text.trim();
    final remember = _rememberEmail;
    FocusScope.of(context).unfocus();
    final signedIn = await auth.login(
      LoginRequest(email: email, password: _password.text),
    );
    if (!signedIn) return;
    try {
      if (remember) await (await _preferences).setString(_emailKey, email);
    } catch (_) {
      // Preferences are independent of the authenticated session.
    }
  }

  Future<void> _setRememberEmail(bool value) async {
    setState(() => _rememberEmail = value);
    if (value) return;
    try {
      await (await _preferences).remove(_emailKey);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장한 이메일을 지우지 못했어요. 다시 시도해 주세요.')),
      );
      setState(() => _rememberEmail = true);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final submitting = auth.status == AuthStatus.authenticating;
    final enabled = _ready && !submitting;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgPicture.asset(
                        'assets/logos/movielog_logo.svg',
                        width: 72,
                        height: 72,
                        semanticsLabel: 'MovieLog 로고',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'MovieLog 로그인',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _email,
                        enabled: enabled,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: '이메일'),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        enabled: enabled,
                        obscureText: _hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: enabled ? (_) => _submit() : null,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                            onPressed: enabled
                                ? () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  )
                                : null,
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? '비밀번호를 입력해 주세요.'
                            : null,
                      ),
                      CheckboxListTile(
                        value: _rememberEmail,
                        onChanged: enabled
                            ? (value) => _setRememberEmail(value ?? false)
                            : null,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('이메일 저장'),
                      ),
                      if (auth.message case final message?) ...[
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      MovieLogButton(
                        label: '로그인',
                        isLoading: submitting,
                        onPressed: enabled ? _submit : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: submitting
                            ? null
                            : () => context.push('/register'),
                        child: const Text('회원가입'),
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
}
