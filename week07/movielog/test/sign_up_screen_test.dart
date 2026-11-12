import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/login_prompt.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

import 'support/fake_services.dart';

const _phone = Size(390, 844);
const _wide = Size(1280, 800);
const _moviesMarker = '테스트용 영화 화면';
const _previousMarker = '이전 화면';

/// 테스트마다 새로 만드는 학습용 세션. 가입 성공 시 memberId가 저장되는지 확인한다.
late LearningMemberSession _session;

Future<FakeSignUpService> _pumpSignUp(
  WidgetTester tester, {
  Size size = _phone,
  double keyboardHeight = 0,
  FakeSignUpService? service,
  bool pushedFromAnotherScreen = false,
}) async {
  final checkService = service ?? FakeSignUpService();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.reset);

  // SignUpScreen은 가입 성공 후 context.go('/movies')를 호출하므로
  // 테스트에서도 GoRouter 아래에 띄워야 한다. 영화 탭은 이동 여부만 확인할 가짜 화면.
  _session = LearningMemberSession();
  final router = GoRouter(
    initialLocation: pushedFromAnotherScreen ? '/previous' : '/register',
    routes: [
      GoRoute(
        path: '/previous',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/register'),
            child: const Text(_previousMarker),
          ),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => SignUpViewModel(checkService),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const Scaffold(body: Text(_moviesMarker)),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: _session,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  if (pushedFromAnotherScreen) {
    await tester.tap(find.text(_previousMarker));
    await tester.pumpAndSettle();
  }
  return checkService;
}

Finder get _nicknameField => find.byType(TextFormField).at(0);
Finder get _emailField => find.byType(TextFormField).at(1);
Finder get _passwordField => find.byType(TextFormField).at(2);

Finder get _submitFinder => find.widgetWithText(ElevatedButton, '가입하기');
Finder get _nicknameCheck => find.byType(MovieLogButton).at(0);
Finder get _emailCheck => find.byType(MovieLogButton).at(1);

ElevatedButton _submitButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(_submitFinder);

ElevatedButton _checkButton(WidgetTester tester, Finder button) =>
    tester.widget<ElevatedButton>(
      find.descendant(of: button, matching: find.byType(ElevatedButton)),
    );

/// 닉네임·이메일 중복 확인 버튼을 차례로 누른다.
Future<void> _checkBoth(WidgetTester tester) async {
  await tester.tap(_nicknameCheck);
  await tester.pump();
  await tester.tap(_emailCheck);
  await tester.pump();
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(_nicknameField, '무비러버');
  await tester.enterText(_emailField, 'movie@example.com');
  await tester.enterText(_passwordField, 'movie1234');
  await tester.pump();
}

void main() {
  group('휴대폰 화면', () {
    testWidgets('입력 전에는 안내 문구와 세 입력창이 보이고 가입 버튼이 비활성화된다', (tester) async {
      await _pumpSignUp(tester);

      expect(find.text('회원가입'), findsOneWidget); // 앱바 제목
      expect(find.textContaining('환영합니다!'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('필수 약관에 동의합니다'), findsOneWidget);
      expect(_submitButton(tester).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('잘못된 값을 입력하면 각 입력창에 한국어 오류 메시지가 보인다', (tester) async {
      await _pumpSignUp(tester);

      await tester.enterText(_nicknameField, 'a');
      await tester.enterText(_emailField, 'test@');
      await tester.enterText(_passwordField, 'abc');
      await tester.pump();

      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
      expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
      expect(_submitButton(tester).onPressed, isNull);
    });

    testWidgets('모든 입력이 유효해도 약관에 동의해야 버튼이 활성화된다', (tester) async {
      await _pumpSignUp(tester);

      await _fillValidForm(tester);
      await _checkBoth(tester);
      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsNothing);
      expect(_submitButton(tester).onPressed, isNull);

      await tester.tap(find.text('필수 약관에 동의합니다'));
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull);

      // 약관 동의를 다시 해제하면 버튼도 다시 비활성화된다.
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNull);
    });

    testWidgets('입력값을 다시 잘못 고치면 버튼이 다시 비활성화된다', (tester) async {
      await _pumpSignUp(tester);
      await _fillValidForm(tester);
      await _checkBoth(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull);

      await tester.enterText(_emailField, 'movie@');
      await tester.pump();

      expect(_submitButton(tester).onPressed, isNull);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    });

    testWidgets('가입에 성공하면 memberId를 세션에 저장하고 영화 탭으로 이동한다', (tester) async {
      final service = await _pumpSignUp(tester);
      await _fillValidForm(tester);
      await _checkBoth(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(_submitFinder);
      await tester.pumpAndSettle();

      expect(service.signUpCalls, 1);
      expect(_session.memberId, 42);
      expect(find.text(_moviesMarker), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
    });

    testWidgets('입력이 유효하지 않으면 가입 버튼을 눌러도 홈으로 이동하지 않는다', (tester) async {
      await _pumpSignUp(tester);
      await tester.enterText(_nicknameField, 'a');
      await tester.pump();

      // 버튼이 비활성화라 탭해도 아무 일도 일어나지 않아야 한다.
      await tester.tap(_submitFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(find.text(_moviesMarker), findsNothing);
    });

    testWidgets('시작 화면에서 go로 들어오면 돌아갈 곳이 없어 뒤로 가기 버튼이 없다', (tester) async {
      await _pumpSignUp(tester);

      expect(find.byType(BackButton), findsNothing);
      expect(find.byTooltip('뒤로 가기'), findsNothing);
    });

    testWidgets('키보드의 다음 버튼으로 닉네임 → 이메일 → 비밀번호 순서로 포커스가 이동한다', (tester) async {
      await _pumpSignUp(tester);

      EditableText editable(int index) =>
          tester.widget<EditableText>(find.byType(EditableText).at(index));

      await tester.tap(_nicknameField);
      await tester.pump();
      expect(editable(0).focusNode.hasFocus, isTrue);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(editable(1).focusNode.hasFocus, isTrue);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(editable(2).focusNode.hasFocus, isTrue);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(editable(2).focusNode.hasFocus, isFalse);
    });

    testWidgets('내용이 짧아도 체크박스와 버튼, 로그인 안내가 화면 아래쪽에 붙는다', (tester) async {
      await _pumpSignUp(tester);

      final loginBottom = tester.getBottomLeft(find.byType(LoginPrompt)).dy;
      final passwordBottom = tester.getBottomLeft(_passwordField).dy;

      expect(loginBottom, greaterThan(_phone.height - 80));
      expect(loginBottom, lessThanOrEqualTo(_phone.height));
      expect(
        tester.getTopLeft(find.byType(Checkbox)).dy - passwordBottom,
        greaterThan(100),
      );
    });

    testWidgets('키보드가 열린 작은 화면에서도 Overflow 없이 스크롤로 버튼에 접근할 수 있다', (
      tester,
    ) async {
      await _pumpSignUp(
        tester,
        size: const Size(390, 500),
        keyboardHeight: 300,
      );

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        _submitFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_submitFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('화면이 제거되어도 Controller와 FocusNode 정리 중 오류가 나지 않는다', (
      tester,
    ) async {
      await _pumpSignUp(tester);
      await _fillValidForm(tester);

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });

  group('넓은 화면', () {
    testWidgets('앱바 없이 제목을 본문에 보여주고 폼을 가운데 정렬한다', (tester) async {
      await _pumpSignUp(tester, size: _wide);

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('회원가입'), findsOneWidget);
      expect(find.text('MovieLog에 오신 것을 환영합니다!'), findsOneWidget);

      final formRect = tester.getRect(find.byType(Form));
      expect(formRect.center.dx, closeTo(_wide.width / 2, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('폼 너비는 최대 560에서 좌우 여백 32를 뺀 496으로 제한된다', (tester) async {
      await _pumpSignUp(tester, size: _wide);

      expect(tester.getSize(find.byType(Form)).width, 496);
    });

    testWidgets('700 미만이면 휴대폰 레이아웃, 700 이상이면 넓은 레이아웃이다', (tester) async {
      await _pumpSignUp(tester, size: const Size(699, 900));
      expect(find.byType(AppBar), findsOneWidget);

      await _pumpSignUp(tester, size: const Size(700, 900));
      await tester.pump();
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('휴대폰과 같은 Validator와 버튼 조건을 사용한다', (tester) async {
      await _pumpSignUp(tester, size: _wide);

      await tester.enterText(_nicknameField, 'a');
      await tester.pump();
      expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);

      await _fillValidForm(tester);
      await _checkBoth(tester);
      expect(_submitButton(tester).onPressed, isNull);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('비밀번호 표시 버튼으로 입력값을 보이거나 숨길 수 있다', (tester) async {
      await _pumpSignUp(tester, size: _wide);

      bool obscured() => tester
          .widget<EditableText>(find.byType(EditableText).at(2))
          .obscureText;

      expect(obscured(), isTrue);

      await tester.tap(find.byTooltip('비밀번호 표시'));
      await tester.pump();
      expect(obscured(), isFalse);

      await tester.tap(find.byTooltip('비밀번호 숨기기'));
      await tester.pump();
      expect(obscured(), isTrue);
    });

    testWidgets('휴대폰 화면에는 비밀번호 표시 버튼이 없다', (tester) async {
      await _pumpSignUp(tester);

      expect(find.byTooltip('비밀번호 표시'), findsNothing);
    });
  });

  group('중복 확인', () {
    testWidgets('형식이 맞아야 중복 확인 버튼이 활성화된다', (tester) async {
      await _pumpSignUp(tester);
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNull);

      await tester.enterText(_nicknameField, 'a');
      await tester.pump();
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNull);

      await tester.enterText(_nicknameField, '무비러버');
      await tester.pump();
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNotNull);
    });

    testWidgets('형식·약관이 맞아도 닉네임·이메일 둘 다 확인해야 가입하기가 활성화된다', (tester) async {
      await _pumpSignUp(tester);
      await _fillValidForm(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNull);

      await tester.tap(_nicknameCheck);
      await tester.pump();
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);
      expect(_submitButton(tester).onPressed, isNull);

      await tester.tap(_emailCheck);
      await tester.pump();
      expect(find.text('사용할 수 있는 이메일입니다.'), findsOneWidget);
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('통신 중에는 버튼이 비활성화되고 가운데 인디케이터만 보인다', (tester) async {
      final completer = Completer<bool>();
      await _pumpSignUp(
        tester,
        service: FakeSignUpService(nickname: (_) => completer.future),
      );
      await tester.enterText(_nicknameField, '무비러버');
      await tester.pump();

      await tester.tap(_nicknameCheck);
      await tester.pump();

      expect(_checkButton(tester, _nicknameCheck).onPressed, isNull);
      expect(
        find.descendant(
          of: _nicknameCheck,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _nicknameCheck, matching: find.text('중복 확인')),
        findsNothing,
      );

      completer.complete(true);
      await tester.pump();
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);
    });

    testWidgets('중복이면 에러 문구가 보이고, 값을 바꾸면 사라지며, 같은 값을 다시 입력하면 재요청 없이 에러로 돌아온다', (
      tester,
    ) async {
      final service = await _pumpSignUp(
        tester,
        service: FakeSignUpService(nickname: (_) async => false),
      );
      await tester.enterText(_nicknameField, '무비러버');
      await tester.pump();
      await tester.tap(_nicknameCheck);
      await tester.pump();

      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNull);

      await tester.enterText(_nicknameField, '무비러버2');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNotNull);

      // 앞뒤 공백은 같은 값으로 본다.
      await tester.enterText(_nicknameField, ' 무비러버 ');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNull);
      expect(service.nicknameCalls, ['무비러버']);
    });

    testWidgets('통신 실패는 중복과 다른 문구로 보여주고 다시 시도할 수 있다', (tester) async {
      await _pumpSignUp(
        tester,
        service: FakeSignUpService(email: (_) async => throw dioError()),
      );
      await tester.enterText(_emailField, 'movie@example.com');
      await tester.pump();
      await tester.tap(_emailCheck);
      await tester.pump();

      expect(find.text(SignUpViewModel.networkErrorMessage), findsOneWidget);
      expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
      expect(_checkButton(tester, _emailCheck).onPressed, isNotNull);
    });

    testWidgets('확인 버튼은 입력창 오른쪽에 8px 간격으로 놓이고 가입하기는 전체 너비다', (tester) async {
      await _pumpSignUp(tester);

      final field = tester.getRect(_nicknameField);
      final button = tester.getRect(_nicknameCheck);
      expect(button.left - field.right, 8);
      expect(button.top, field.top);
      expect(button.height, field.height);

      final formWidth = tester.getSize(find.byType(Form)).width;
      expect(tester.getSize(_submitFinder).width, formWidth);
    });
  });

  group('회원가입 제출', () {
    Future<void> readyToSubmit(WidgetTester tester) async {
      await _fillValidForm(tester);
      await _checkBoth(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
    }

    bool canPop(WidgetTester tester) => tester
        .widget<PopScope>(
          find.descendant(
            of: find.byType(SignUpScreen),
            matching: find.byType(PopScope),
          ),
        )
        .canPop;

    testWidgets('제출 중에는 버튼·입력·뒤로 가기가 막히고, 끝나면 다시 나갈 수 있다 (Challenge)', (
      tester,
    ) async {
      final completer = Completer<Never>();
      final service = await _pumpSignUp(
        tester,
        pushedFromAnotherScreen: true,
        service: FakeSignUpService(signUpHandler: (_) => completer.future),
      );
      expect(find.byType(BackButton), findsOneWidget);
      await readyToSubmit(tester);

      await tester.tap(_submitFinder);
      await tester.pump();

      // 가입하기는 인디케이터만 보이며 비활성화된다. (label이 사라진다)
      final submitButton = find.byType(MovieLogButton).last;
      expect(
        find.descendant(
          of: submitButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(submitButton);
      await tester.pump();
      expect(service.signUpCalls, 1);

      expect(tester.widget<TextFormField>(_passwordField).enabled, isFalse);
      expect(_checkButton(tester, _nicknameCheck).onPressed, isNull);
      expect(canPop(tester), isFalse);
      expect(find.byType(BackButton), findsNothing);

      // 시스템 뒤로 가기를 눌러도 화면에 남는다.
      await tester.binding.handlePopRoute();
      // 인디케이터가 계속 돌아 pumpAndSettle은 끝나지 않으므로 시간만 흘린다.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SignUpScreen), findsOneWidget);

      completer.completeError(
        commonError(409, 'COMMON409', '이미 사용 중인 이메일입니다.'),
      );
      await tester.pumpAndSettle();

      expect(canPop(tester), isTrue);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.text(_previousMarker), findsOneWidget);
    });

    testWidgets('409는 Snackbar로 보여주고 입력을 유지하며 해당 입력란을 중복 상태로 되돌린다', (
      tester,
    ) async {
      await _pumpSignUp(
        tester,
        service: FakeSignUpService(
          signUpHandler: (_) async =>
              throw commonError(409, 'COMMON409', '이미 사용 중인 이메일입니다.'),
        ),
      );
      await readyToSubmit(tester);

      await tester.tap(_submitFinder);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('이미 사용 중인 이메일입니다.'),
        ),
        findsOneWidget,
      );
      expect(find.text('movie@example.com'), findsOneWidget);
      expect(_checkButton(tester, _emailCheck).onPressed, isNull);
      expect(_submitButton(tester).onPressed, isNull);
      expect(_session.memberId, isNull);
    });

    testWidgets('비밀번호 400은 비밀번호 입력칸 errorText로 보이고, 고치면 사라진다', (tester) async {
      const message = '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.';
      await _pumpSignUp(
        tester,
        service: FakeSignUpService(
          signUpHandler: (_) async =>
              throw commonError(400, 'COMMON400', message),
        ),
      );
      await readyToSubmit(tester);

      await tester.tap(_submitFinder);
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.enterText(_passwordField, 'Movie1234!');
      await tester.pump();
      expect(find.text(message), findsNothing);
    });
  });
}
