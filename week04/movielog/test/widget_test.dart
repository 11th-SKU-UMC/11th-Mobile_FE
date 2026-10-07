
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/movie_log_app.dart';

void main() {
  testWidgets('ProfileScreen이 프로필 정보를 정상적으로 표시한다', (
    WidgetTester tester,
  ) async {
    // 앱을 렌더링
    await tester.pumpWidget(const MovieLogApp());

    // AppBar 타이틀 확인
    expect(find.text('내 프로필'), findsOneWidget);

    // 통계 항목 라벨 확인
    expect(find.text('본 영화'), findsOneWidget);
    expect(find.text('평점'), findsOneWidget);
    expect(find.text('즐겨찾기'), findsOneWidget);

    // 통계 값 확인
    expect(find.text('342'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);

    // 선호 장르 섹션 확인
    expect(find.text('선호하는 장르'), findsOneWidget);
    expect(find.text('드라마'), findsOneWidget);
    expect(find.text('SF'), findsOneWidget);
    expect(find.text('애니메이션'), findsOneWidget);
  });
}