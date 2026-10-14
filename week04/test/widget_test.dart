import 'package:flutter_test/flutter_test.dart';
import 'package:movielog_week04/main.dart';

void main() {
  testWidgets('MovieLog 시작 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('MovieLog'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}