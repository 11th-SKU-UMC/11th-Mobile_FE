import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/screens/movie_search_screen.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'test_app.dart';

Future<void> openMovieTab(WidgetTester tester) async {
  await tester.tap(find.text('영화').last);
  await tester.pumpAndSettle();
}

Future<void> openMyFavorites(WidgetTester tester) async {
  await tester.tap(find.text('마이').last);
  await tester.pumpAndSettle();
  // 테스트 화면(800x600)에서는 행이 아래에 있어 먼저 보이게 스크롤합니다.
  await tester.ensureVisible(find.text('내 즐겨찾기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('내 즐겨찾기'));
  await tester.pumpAndSettle();
}

/// 영화 목록 격자의 세로 Scrollable입니다(가로 장르 Chip 목록과 구분).
final verticalScrollable = find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

void main() {
  testWidgets('상세 북마크는 서버 결과로 바뀌고 Snackbar로 안내한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.text('영화 1'));
    await tester.pumpAndSettle();
    expect(app.favoriteApi.checkCalls, [1]);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byTooltip('즐겨찾기 추가'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
    expect(app.favoriteApi.movieIdsOf('saved'), [1]);

    await tester.tap(find.byTooltip('즐겨찾기 해제'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('즐겨찾기에서 삭제했습니다.'), findsOneWidget);
    expect(app.favoriteApi.movieIdsOf('saved'), isEmpty);
  });

  testWidgets('등록 실패면 이전 아이콘을 유지하고 실패를 안내한다', (tester) async {
    final app = TestApp(token: 'saved');
    app.favoriteApi.addError = dioError(500, '/v8/favorites');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.text('영화 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('즐겨찾기 추가'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('즐겨찾기 등록에 실패했습니다.'), findsOneWidget);
    expect(app.storage.token, 'saved');
  });

  testWidgets('즐겨찾기 등록 중 토큰이 만료되면 로그인 화면으로 보낸다', (tester) async {
    final app = TestApp(token: 'saved');
    app.favoriteApi.addError = expiredError('/v8/favorites');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.text('영화 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('즐겨찾기 추가'));
    await tester.pumpAndSettle();

    expect(find.text('MovieLog에 로그인'), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(app.storage.token, isNull);
  });

  testWidgets('마이페이지 → 내 즐겨찾기 → 상세에서 해제 → 뒤로가기하면 목록이 갱신된다', (tester) async {
    final app = TestApp(token: 'saved');
    app.favoriteApi.seed('saved', [1, 2]);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMyFavorites(tester);
    expect(find.text('내 즐겨찾기'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('TMDB 영화 1'), findsOneWidget);
    expect(find.text('TMDB 영화 2'), findsOneWidget);

    await tester.tap(find.text('TMDB 영화 1'));
    await tester.pumpAndSettle();
    expect(find.text('영화 상세'), findsOneWidget);
    await tester.tap(find.byTooltip('즐겨찾기 해제'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('내 즐겨찾기'), findsOneWidget);
    expect(find.text('TMDB 영화 1'), findsNothing);
    expect(find.text('TMDB 영화 2'), findsOneWidget);
    expect(app.favoriteApi.listCalls, 2);
  });

  testWidgets('영화 정보 한 건만 실패하면 그 카드만 placeholder와 재조회 버튼을 보여 준다', (
    tester,
  ) async {
    final app = TestApp(token: 'saved');
    app.favoriteApi.seed('saved', [1, 2]);
    app.tmdb.failingDetailIds.add(2);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMyFavorites(tester);
    expect(find.text('TMDB 영화 1'), findsOneWidget);
    expect(find.text('영화 #2'), findsOneWidget);
    expect(find.text('영화 정보를 불러오지 못했습니다.'), findsOneWidget);

    app.tmdb.failingDetailIds.clear();
    await tester.tap(find.text('정보 재조회'));
    await tester.pumpAndSettle();
    expect(find.text('TMDB 영화 2'), findsOneWidget);
    expect(find.text('영화 #2'), findsNothing);
  });

  testWidgets('빈 목록과 조회 오류를 다른 화면으로 보여 준다', (tester) async {
    final app = TestApp(token: 'saved');
    app.favoriteApi.listError = dioError(500, '/v8/favorites');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMyFavorites(tester);
    expect(find.text('내 즐겨찾기 목록을 불러오지 못했습니다.'), findsOneWidget);

    app.favoriteApi.listError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 즐겨찾기한 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('로그아웃 후 다른 계정으로 로그인하면 이전 계정의 즐겨찾기가 보이지 않는다', (tester) async {
    final app = TestApp(
      authApi: FakeAuthApiService(
        accounts: const {
          'movie@umc.com': 'Umc1234!',
          'other@umc.com': 'Other123!',
        },
      ),
    );
    app.favoriteApi.seed('token-movie@umc.com', [1]);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await login(tester);
    await openMyFavorites(tester);
    expect(find.text('TMDB 영화 1'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    app.memberApi.member = MemberInfo(
      email: 'other@umc.com',
      nickname: '다른계정',
      createdAt: DateTime.utc(2026, 11, 1),
    );
    await login(tester, email: 'other@umc.com', password: 'Other123!');
    await openMyFavorites(tester);

    expect(find.text('TMDB 영화 1'), findsNothing);
    expect(find.textContaining('아직 즐겨찾기한 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('영화 목록은 첫 page만 보이고, 다음 page 실패 뒤 같은 page를 다시 요청한다', (
    tester,
  ) async {
    final app = TestApp(token: 'saved');
    app.tmdb.failDiscoverPages.add(2);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    expect(find.text('20편 표시 중'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(app.tmdb.discoverCalls.map((c) => c.page), [1]);

    // 끝까지 내리면 다음 page를 요청하고, 실패하면 기존 카드와 함께 재시도 버튼을 보여 줍니다.
    await tester.scrollUntilVisible(
      find.text('다음 페이지 다시 시도'),
      400,
      scrollable: verticalScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('20편 표시 중'), findsOneWidget);
    expect(app.tmdb.discoverCalls.map((c) => c.page), [1, 2]);

    app.tmdb.failDiscoverPages.clear();
    await tester.tap(find.text('다음 페이지 다시 시도'));
    await tester.pumpAndSettle();
    expect(app.tmdb.discoverCalls.map((c) => c.page).take(3), [1, 2, 2]);
    expect(find.textContaining('편 표시 중'), findsOneWidget);
    expect(find.text('20편 표시 중'), findsNothing);
  });

  testWidgets('마지막 page에서는 더 보기 대신 끝 상태를 보여 준다', (tester) async {
    final app = TestApp(token: 'saved');
    app.tmdb
      ..totalPages = 1
      ..failDiscover = false;
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.scrollUntilVisible(
      find.text('더 이상 조회할 페이지가 없습니다.'),
      400,
      scrollable: verticalScrollable,
    );
    expect(find.text('더 보기'), findsNothing);
  });

  testWidgets('장르를 바꾸면 이전 목록을 비우고 첫 page부터 다시 불러온다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.text('액션'));
    await tester.pumpAndSettle();

    expect(app.tmdb.discoverCalls.last.page, 1);
    expect(app.tmdb.discoverCalls.last.genreIds, [28]);
    expect(find.text('영화 1'), findsNothing);
    expect(find.text('영화 28001'), findsOneWidget);
  });

  testWidgets('검색 아이콘 → 검색 화면에서 결과·결과 없음을 확인하고 상세로 이동한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.byTooltip('영화 검색'));
    await tester.pumpAndSettle();
    expect(find.text('영화 검색'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('보고 싶은 영화를 검색해 보세요.'), findsOneWidget);

    // 빈 검색어는 서버에 보내지 않습니다.
    await tester.tap(find.byTooltip('검색'));
    await tester.pump();
    expect(find.text('검색어를 입력해 주세요.'), findsOneWidget);
    expect(app.tmdb.searchCalls, isEmpty);

    await tester.enterText(find.byType(TextField), '없는영화');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('"없는영화" 검색 결과가 없습니다.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '아이언맨');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('"아이언맨" 검색 결과 8편'), findsOneWidget);
    expect(app.tmdb.searchCalls.last, (page: 1, query: '아이언맨'));

    await tester.tap(find.text('아이언맨 결과 1'));
    await tester.pumpAndSettle();
    expect(find.text('영화 상세'), findsOneWidget);
  });

  testWidgets('Challenge: 입력을 500ms 멈추면 한 번만 검색한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.byTooltip('영화 검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '어');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), '어벤져스');
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.tmdb.searchCalls, isEmpty);

    await tester.pump(MovieSearchScreen.debounceDuration);
    await tester.pumpAndSettle();
    expect(app.tmdb.searchCalls.map((c) => c.query), ['어벤져스']);
    expect(find.text('어벤져스 결과 1'), findsOneWidget);
  });

  testWidgets('Challenge: 평점 Dialog에서 즐겨찾기에도 추가하면 한 번에 저장하고 북마크를 맞춘다', (
    tester,
  ) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.text('영화 1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();

    await tapStar(tester, 5);
    await tester.tap(find.text('즐겨찾기에도 추가'));
    await tester.pump();
    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(app.recordApi.calls.single.addToFavorites, isTrue);
    expect(app.favoriteApi.movieIdsOf('saved'), [1]);
    expect(find.textContaining('평점을 저장했습니다.'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('이미 즐겨찾기한 영화는 체크박스 없이 평점만 저장한다', (tester) async {
    final app = TestApp(token: 'saved');
    app.favoriteApi.seed('saved', [1]);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await openMovieTab(tester);
    await tester.tap(find.text('영화 1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();

    expect(find.text('즐겨찾기에도 추가'), findsNothing);
    await tapStar(tester, 3);
    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();

    expect(app.ratingApi.createCalls.single.movieId, 1);
    expect(app.recordApi.calls, isEmpty);
  });
}
