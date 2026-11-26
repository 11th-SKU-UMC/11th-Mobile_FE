/// 앱 전체를 fake 서비스로 띄우는 위젯 테스트용 도우미입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'fakes.dart';

export 'fakes.dart';

class TestApp {
  TestApp({
    String? token,
    FakeAuthApiService? authApi,
    FakeMemberApiService? memberApi,
    FakeRatingApiService? ratingApi,
    FakeSignUpService? signUp,
    FakeEmailPreference? emailPreference,
  }) : storage = FakeTokenStorage(token),
       authApi = authApi ?? FakeAuthApiService(),
       memberApi = memberApi ?? FakeMemberApiService(),
       ratingApi = ratingApi ?? FakeRatingApiService(),
       signUp = signUp ?? FakeSignUpService(),
       emailPreference = emailPreference ?? FakeEmailPreference(),
       tmdb = FakeTmdbMovieService() {
    favoriteApi = FakeFavoriteApiService(storage);
    recordApi = FakeMovieRecordApiService(favorites: favoriteApi);
  }

  final FakeTokenStorage storage;
  final FakeAuthApiService authApi;
  final FakeMemberApiService memberApi;
  final FakeRatingApiService ratingApi;
  final FakeSignUpService signUp;
  final FakeEmailPreference emailPreference;
  final FakeTmdbMovieService tmdb;
  late final FakeFavoriteApiService favoriteApi;
  late final FakeMovieRecordApiService recordApi;

  Widget build() => MovieLogApp(
    tokenStorage: storage,
    tmdbMovieService: tmdb,
    authApiService: authApi,
    memberApiService: memberApi,
    signUpService: signUp,
    ratingApiService: ratingApi,
    genrePreference: FakeGenrePreference(),
    emailPreference: emailPreference,
    favoriteApiService: favoriteApi,
    movieRecordApiService: recordApi,
  );
}

ElevatedButton buttonOf(WidgetTester tester, String label) {
  final movieLogButton = find.widgetWithText(MovieLogButton, label);
  return tester.widget<ElevatedButton>(
    find.descendant(of: movieLogButton, matching: find.byType(ElevatedButton)),
  );
}

Future<void> login(
  WidgetTester tester, {
  String email = 'movie@umc.com',
  String password = 'Umc1234!',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.tap(find.widgetWithText(MovieLogButton, '로그인'));
  await tester.pumpAndSettle();
}

void go(WidgetTester tester, String location) {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
}

/// RatingDialog 안의 [count]번째 별을 누릅니다.
Future<void> tapStar(WidgetTester tester, int count) async {
  final stars = find.descendant(
    of: find.byType(RatingDialog),
    matching: find.byIcon(Icons.star),
  );
  await tester.tap(stars.at(count - 1));
  await tester.pump();
}

/// 영화 탭 → 첫 영화 상세 → 평점 Dialog에서 별점과 코멘트를 저장합니다.
Future<void> createRatingFromDetail(
  WidgetTester tester, {
  int stars = 4,
  String comment = '다시 보고 싶어요',
}) async {
  await tester.tap(find.text('영화').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('영화 1'));
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('평점 남기기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('평점 남기기'));
  await tester.pumpAndSettle();
  await tapStar(tester, stars);
  await tester.enterText(
    find.descendant(
      of: find.byType(RatingDialog),
      matching: find.byType(TextField),
    ),
    comment,
  );
  await tester.tap(find.text('평점 저장'));
  await tester.pumpAndSettle();
}
