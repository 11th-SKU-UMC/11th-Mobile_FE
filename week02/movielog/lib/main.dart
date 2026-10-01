import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      home: const SignUpPage(),
    );
  }
}

// ============================================================
// Week02 - 회원가입 화면
// ============================================================

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nicknameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  bool _isTermsAgreed = false;

  bool get _isNicknameValid {
    return _nicknameController.text.trim().length >= 2;
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(email);
  }

  bool get _isPasswordValid {
    return _passwordController.text.length >= 8;
  }

  bool get _canSubmit {
    return _isNicknameValid &&
        _isEmailValid &&
        _isPasswordValid &&
        _isTermsAgreed;
  }

  String? _validateNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    if (value.trim().length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return '올바른 이메일 형식이 아닙니다.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || !_isTermsAgreed) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('회원가입 정보가 올바르게 입력되었습니다.')));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpHeader(),

                const SizedBox(height: 32),

                SignUpTextField(
                  label: '닉네임',
                  hint: '닉네임을 입력해주세요',
                  controller: _nicknameController,
                  validator: _validateNickname,
                  textInputAction: TextInputAction.next,
                  isValid: _isNicknameValid,
                  onChanged: (_) {
                    setState(() {});
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).nextFocus();
                  },
                ),

                const SizedBox(height: 18),

                SignUpTextField(
                  label: '이메일',
                  hint: '이메일 주소를 입력해주세요',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  isValid: _isEmailValid,
                  onChanged: (_) {
                    setState(() {});
                  },
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                ),

                const SizedBox(height: 18),

                SignUpTextField(
                  label: '비밀번호',
                  hint: '비밀번호를 입력해주세요',
                  controller: _passwordController,
                  validator: _validatePassword,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  isValid: _isPasswordValid,
                  onChanged: (_) {
                    setState(() {});
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),

                const SizedBox(height: 40),

                TermsAgreement(
                  value: _isTermsAgreed,
                  onChanged: (value) {
                    setState(() {
                      _isTermsAgreed = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                SignUpButton(enabled: _canSubmit, onPressed: _submit),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 의미 단위 Widget 1
// ============================================================

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// ============================================================
// 의미 단위 Widget 2
// ============================================================

class SignUpTextField extends StatelessWidget {
  const SignUpTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    required this.onChanged,
    required this.onFieldSubmitted,
    required this.isValid,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
  });

  final String label;
  final String hint;

  final TextEditingController controller;

  final String? Function(String?) validator;

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onFieldSubmitted;

  final bool isValid;
  final bool obscureText;

  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixIcon: isValid
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 의미 단위 Widget 3
// ============================================================

class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (checked) {
            onChanged(checked ?? false);
          },
        ),
        const Expanded(
          child: Text('필수 약관에 동의합니다', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

// ============================================================
// 의미 단위 Widget 4
// ============================================================

class SignUpButton extends StatelessWidget {
  const SignUpButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          '가입하기',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ============================================================
// Week01 - 기존 프로필 화면
// 삭제하지 않고 그대로 보존
// ============================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(),
                ProfileEditButton(),
                SizedBox(height: 20),
                StatsSection(),
                SizedBox(height: 22),
                GenreSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 18),

          ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 8),

          Text('무비러버', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 6),

          Text(
            '매주 주말엔 영화관으로 출근하는 프로 관람객.\n'
            '좋은 영화를 보고 기록하는 것을 좋아합니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.5),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          '프로필 수정',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: 6),
        Expanded(
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: 6),
        Expanded(
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class GenreSection extends StatelessWidget {
  const GenreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 장르',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 10),
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
    );
  }
}

class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 12,
      title: Row(
        children: [
          const Text(
            '내 프로필',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 8),

          SvgPicture.asset(
            'assets/logos/movielog_logo.svg',
            width: 18,
            height: 18,
            semanticsLabel: 'MovieLog 로고',
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
