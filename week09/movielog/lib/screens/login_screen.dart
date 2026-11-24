import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _savedEmailKey = 'movielog.saved_email';

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthViewModel _auth;
  bool _saveEmail = false; // Challenge: 이메일만 저장합니다. 비밀번호·토큰은 저장하지 않습니다.

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final saved = await SharedPreferencesAsync().getString(_savedEmailKey);
      if (!mounted || saved == null || saved.isEmpty) return;
      setState(() {
        _email.text = saved;
        _saveEmail = true;
      });
    } catch (_) {
      // 저장된 이메일을 못 읽어도 로그인은 계속할 수 있습니다.
    }
  }

  Future<void> _persistEmail() async {
    try {
      final prefs = SharedPreferencesAsync();
      if (_saveEmail) {
        await prefs.setString(_savedEmailKey, _email.text.trim());
      } else {
        await prefs.remove(_savedEmailKey);
      }
    } catch (_) {}
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 표시를 먼저 꺼서 같은 Snackbar가 반복되지 않게 합니다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _persistEmail();
    await _auth.login(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('로그인'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 64),
              SvgPicture.asset('assets/logos/movielog_logo.svg', width: 84, height: 84),
              const SizedBox(height: 24),
              const Text('MovieLog에 로그인'),
              const SizedBox(height: 48),
              TextFormField(
                controller: _email,
                enabled: enabled,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '이메일'),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _password,
                enabled: enabled,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _saveEmail,
                onChanged: enabled ? (v) => setState(() => _saveEmail = v ?? false) : null,
                title: const Text('이메일 저장'),
              ),
              if (auth.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    auth.message!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 32),
              MovieLogButton(
                label: '로그인',
                width: double.infinity,
                isLoading: loading,
                onPressed: enabled ? _submit : null,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: enabled ? () => context.push('/signup') : null,
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
