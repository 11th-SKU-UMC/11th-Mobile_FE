import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const SignUpScreen(),
  );
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 32),
                  const Text('FLUTTER 1주차'),
                  const SizedBox(height: 64),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 72,
                    height: 72,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {}, // 1주차에는 화면 이동을 연결하지 않습니다.
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall
            ),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style:
            titleStyle ??
            AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: colors.primary,
                  child: const CircleAvatar(
                    radius: 61,
                    backgroundImage: AssetImage(
                      'assets/images/profile/profile_movielog.jpg',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '무비러버',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '매주 주말엔 영화관으로 출근하는 프로 관람객.\n'
                  '좋은 영화를 보고 기록하는 것을 좋아합니다.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('프로필 수정'),
                ),
              ),
              const SizedBox(height: 32),
              const Row(
                children: [
                  Expanded(
                    child: StatItem(label: '본 영화', value: '342'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatItem(label: '평점', value: '4.2'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatItem(label: '즐겨찾기', value: '58'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '선호하는 장르',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GenreChip(label: '드라마'),
                  GenreChip(label: 'SF'),
                  GenreChip(label: '애니메이션'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // 입력 전 참고 화면도 약관 체크 상태로 표시되어 있습니다.
  bool _agreedToTerms = true;

  bool get _canSubmit {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    return nickname.length >= 2 &&
        emailPattern.hasMatch(email) &&
        password.length >= 8 &&
        _agreedToTerms;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('입력값 확인 완료!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth >= 700
                      ? 560
                      : double.infinity,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SignUpWelcome(),
                                const SizedBox(height: 48),
                                _SignUpFields(
                                  nicknameController: _nicknameController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  emailFocusNode: _emailFocusNode,
                                  passwordFocusNode: _passwordFocusNode,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TermsAgreement(
                                  value: _agreedToTerms,
                                  onChanged: (value) {
                                    setState(() => _agreedToTerms = value);
                                  },
                                ),
                                const SizedBox(height: 24),
                                _SignUpButton(
                                  enabled: _canSubmit,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 36),
                                const _LoginPrompt(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignUpWelcome extends StatelessWidget {
  const _SignUpWelcome();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.black),
    );
  }
}

class _SignUpFields extends StatelessWidget {
  const _SignUpFields({
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.onChanged,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final ValueChanged<String> onChanged;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  InputDecoration _decoration({
    required String hint,
    required String value,
    required bool isValid,
  }) {
    final hasInput = value.isNotEmpty;
    final hasError = hasInput && !isValid;
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCAC4D0)),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFB3261E)),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 16, color: AppColors.black),
      filled: true,
      fillColor: hasError
          ? const Color(0xFFFFDAD7)
          : const Color(0xFFF5F4F0),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      enabledBorder: hasError ? errorBorder : normalBorder,
      focusedBorder: hasError
          ? errorBorder
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.violet, width: 2),
            ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
      suffixIcon: !hasInput
          ? null
          : Icon(
              hasError ? Icons.error_outline : Icons.check_circle,
              color: hasError ? const Color(0xFFB3261E) : AppColors.violet,
              size: 24,
            ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('닉네임'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nicknameController,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '닉네임을 입력해주세요',
            value: nicknameController.text,
            isValid: nicknameController.text.trim().length >= 2,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
          validator: (value) {
            final nickname = value?.trim() ?? '';
            if (nickname.isEmpty) return '닉네임을 입력해주세요.';
            if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
            return null;
          },
        ),
        const SizedBox(height: 18),
        _label('이메일'),
        const SizedBox(height: 8),
        TextFormField(
          controller: emailController,
          focusNode: emailFocusNode,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '이메일 주소를 입력해주세요',
            value: emailController.text,
            isValid: _emailPattern.hasMatch(emailController.text.trim()),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return '이메일을 입력해주세요.';
            if (!_emailPattern.hasMatch(email)) {
              return '올바른 이메일 형식이 아닙니다.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        _label('비밀번호'),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
          decoration: _decoration(
            hint: '비밀번호를 입력해주세요',
            value: passwordController.text,
            isValid: passwordController.text.length >= 8,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          validator: (value) {
            final password = value ?? '';
            if (password.isEmpty) return '비밀번호를 입력해주세요.';
            if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
            return null;
          },
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      title: const Text(
        '필수 약관에 동의합니다',
        style: TextStyle(fontSize: 16, color: AppColors.black),
      ),
      activeColor: AppColors.violet,
      checkColor: AppColors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SignUpButton extends StatelessWidget {
  const _SignUpButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.violet,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: const Color(0xFFCCC2DB),
        disabledForegroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: const Text('가입하기'),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: '이미 계정이 있나요?  ',
        style: TextStyle(fontSize: 16, color: AppColors.gray),
        children: [
          TextSpan(
            text: '로그인',
            style: TextStyle(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}


class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
      backgroundColor: colors.primary.withValues(alpha: 0.12),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }
}
