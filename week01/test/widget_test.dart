import 'package:flutter_test/flutter_test.dart';
import 'package:movielog_week01/main.dart';

void main() {
  testWidgets('MovieLog 프로필 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('본 영화'), findsOneWidget);
    expect(find.text('평균 평점'), findsOneWidget);
    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('선호 장르'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
  });
}