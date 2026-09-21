import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/login_prompt.dart';

const _phone = Size(390, 844);
const _wide = Size(1280, 800);

Future<void> _pumpSignUp(
  WidgetTester tester, {
  Size size = _phone,
  double keyboardHeight = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const SignUpScreen()),
  );
}

Finder get _nicknameField => find.byType(TextFormField).at(0);
Finder get _emailField => find.byType(TextFormField).at(1);
Finder get _passwordField => find.byType(TextFormField).at(2);

ElevatedButton _submitButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

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
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull);

      await tester.enterText(_emailField, 'movie@');
      await tester.pump();

      expect(_submitButton(tester).onPressed, isNull);
      expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    });

    testWidgets('가입하기를 누르면 Form을 검증하고 완료 안내를 보여준다', (tester) async {
      await _pumpSignUp(tester);
      await _fillValidForm(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('회원가입이 완료되었습니다.'), findsOneWidget);
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
      expect(tester.getTopLeft(find.byType(Checkbox)).dy - passwordBottom, greaterThan(100));
    });

    testWidgets('키보드가 열린 작은 화면에서도 Overflow 없이 스크롤로 버튼에 접근할 수 있다', (tester) async {
      await _pumpSignUp(tester, size: const Size(390, 500), keyboardHeight: 300);

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byType(ElevatedButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('화면이 제거되어도 Controller와 FocusNode 정리 중 오류가 나지 않는다', (tester) async {
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
}
