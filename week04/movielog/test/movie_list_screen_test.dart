import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_states.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _selectLoadMode(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('로드 모드 (테스트용)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Loading 후 Success 상태로 영화 Grid를 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListScreen()));

    expect(find.byType(MovieListLoading), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('빈 목록이면 Empty 화면을 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListScreen()));
    await tester.pumpAndSettle();

    await _selectLoadMode(tester, '빈 목록');
    expect(find.byType(MovieListLoading), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MovieListEmpty), findsOneWidget);
  });

  testWidgets('실패하면 Error 화면을 보여주고 재시도하면 성공한다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListScreen()));
    await tester.pumpAndSettle();

    await _selectLoadMode(tester, '실패');
    await tester.pumpAndSettle();

    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('장르 Chip 선택값을 저장하고 다시 진입하면 복원한다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pumpAndSettle();

    expect(await GenrePreference().read(), 'SF');

    // 화면을 제거한 뒤 다시 만들어 앱 재실행 상황을 재현한다.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_wrap(const MovieListScreen()));
    await tester.pumpAndSettle();

    final sfChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'SF'),
    );
    expect(sfChip.selected, isTrue);
  });
}
