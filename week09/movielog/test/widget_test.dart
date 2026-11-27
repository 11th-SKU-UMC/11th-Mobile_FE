import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'support/fake_services.dart';

void main() {
  testWidgets('SplashScreen은 확인 중에 인디케이터, 실패하면 문구와 다시 시도 버튼을 보여준다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('시작하기'), findsNothing);

    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(message: '확인 실패', onRetry: () => retried++),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('확인 실패'), findsOneWidget);

    await tester.tap(find.widgetWithText(MovieLogButton, '다시 시도'));
    expect(retried, 1);
  });

  testWidgets('저장된 토큰이 없으면 로그인 화면으로 가고, 회원가입으로 이동할 수 있다', (tester) async {
    await tester.pumpWidget(MovieLogApp(tokenStorage: MemoryTokenStorage()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    // 직접 들어온 로그인 화면에서는 만료 안내를 띄우지 않는다.
    expect(find.text(LoginScreen.sessionExpiredMessage), findsNothing);

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('가입하기'), findsOneWidget);
  });
}
