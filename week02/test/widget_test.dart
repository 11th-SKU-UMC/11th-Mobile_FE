import 'package:flutter_test/flutter_test.dart';
import 'package:movielog_week02/main.dart';

void main() {
  testWidgets('회원가입 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('MovieLog 시작하기'), findsOneWidget);
    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
  });
}