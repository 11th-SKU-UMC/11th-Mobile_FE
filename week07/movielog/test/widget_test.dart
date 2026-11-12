import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'fakes.dart';

RatingDto sampleRating() => RatingDto(
  ratingId: 1,
  movieId: 550,
  score: 5,
  comment: '최고의 영화!',
  createdAt: DateTime.utc(2026, 11, 7),
);

Widget buildApp({
  String initialLocation = '/start',
  int? memberId,
  FakeRatingApiService? ratingApiService,
  FakeSignUpService? signUpService,
}) {
  return MovieLogApp(
    router: AppRouter.createRouter(initialLocation: initialLocation),
    tmdbMovieService: FakeTmdbMovieService(),
    signUpService: signUpService ?? FakeSignUpService(),
    ratingApiService:
        ratingApiService ?? FakeRatingApiService(ratings: [sampleRating()]),
    genrePreference: FakeGenrePreference(),
    learningMemberSession: LearningMemberSession(memberId),
  );
}

ElevatedButton buttonOf(WidgetTester tester, String label) {
  final movieLogButton = find.widgetWithText(MovieLogButton, label);
  return tester.widget<ElevatedButton>(
    find.descendant(of: movieLogButton, matching: find.byType(ElevatedButton)),
  );
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

void main() {
  testWidgets('시작 → 회원가입 POST → memberId 보관 → 영화 목록, 뒤로 갈 수 없다', (
    tester,
  ) async {
    final signUp = FakeSignUpService(createdMemberId: 42);
    await tester.pumpWidget(buildApp(signUpService: signUp));
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(buttonOf(tester, '가입하기').onPressed, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '영화광');
    await tester.pump();
    await tester.tap(find.widgetWithText(MovieLogButton, '중복 확인').first);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);

    await tester.enterText(fields.at(0), '무비러버');
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    await tester.tap(find.widgetWithText(MovieLogButton, '중복 확인').first);
    await tester.pumpAndSettle();
    expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'lover@umc.com');
    await tester.pump();
    await tester.tap(find.widgetWithText(MovieLogButton, '중복 확인').last);
    await tester.pumpAndSettle();
    expect(find.text('사용할 수 있는 이메일입니다.'), findsOneWidget);

    // 서버 규칙(대·소문자, 숫자, 특수문자 포함 8자 이상)을 만족하지 않으면 가입할 수 없습니다.
    await tester.enterText(fields.at(2), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(buttonOf(tester, '가입하기').onPressed, isNull);

    await tester.enterText(fields.at(2), 'Movie123!');
    await tester.pumpAndSettle();
    expect(buttonOf(tester, '가입하기').onPressed, isNotNull);

    await tester.ensureVisible(find.text('가입하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(signUp.signUpRequests.single.toJson()['email'], 'lover@umc.com');
    expect(find.text('30편'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    final listContext = tester.element(find.text('30편'));
    expect(GoRouter.of(listContext).canPop(), isFalse);
  });

  testWidgets('최종 409는 Snackbar로 안내하고 회원가입 화면에 머문다', (tester) async {
    final signUp = FakeSignUpService()
      ..signUpError = dioError(
        409,
        '/v6/members',
        code: 'COMMON409',
        message: '이미 사용 중인 이메일입니다.',
      );
    await tester.pumpWidget(
      buildApp(initialLocation: '/register', signUpService: signUp),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '무비러버');
    await tester.pump();
    await tester.tap(find.widgetWithText(MovieLogButton, '중복 확인').first);
    await tester.enterText(fields.at(1), 'lover@umc.com');
    await tester.pump();
    await tester.tap(find.widgetWithText(MovieLogButton, '중복 확인').last);
    await tester.enterText(fields.at(2), 'Movie123!');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 사용 중인 이메일입니다.'), findsWidgets);
    expect(find.text('회원가입'), findsOneWidget);
    expect(buttonOf(tester, '가입하기').onPressed, isNull);
  });

  testWidgets('NavigationBar로 영화 탭을 열고 상세로 push한 뒤 돌아온다', (tester) async {
    await tester.pumpWidget(buildApp(initialLocation: '/home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('영화').last);
    await tester.pumpAndSettle();
    expect(find.text('30편'), findsOneWidget);
    expect(find.text('액션'), findsOneWidget);

    await tester.tap(find.text('영화 1'));
    await tester.pumpAndSettle();
    expect(find.text('영화 상세'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('30편'), findsOneWidget);
  });

  testWidgets('회원가입 전에는 영화 상세의 평점 등록 버튼이 비활성화된다', (tester) async {
    await tester.pumpWidget(buildApp(initialLocation: '/movies/550'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(buttonOf(tester, '평점 남기기').onPressed, isNull);
    expect(find.text('평점을 남기려면 먼저 학습용 회원가입을 완료해 주세요.'), findsOneWidget);
  });

  testWidgets('영화 상세에서 별점·코멘트로 평점을 등록하고 Snackbar를 보여준다', (tester) async {
    final ratings = FakeRatingApiService();
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/movies/550',
        memberId: 42,
        ratingApiService: ratings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();

    // 별점을 고르기 전에는 코멘트가 있어도 저장할 수 없습니다.
    await tester.enterText(
      find.descendant(
        of: find.byType(RatingDialog),
        matching: find.byType(TextField),
      ),
      '다시 보고 싶어요',
    );
    await tester.pump();
    expect(buttonOf(tester, '평점 저장').onPressed, isNull);

    await tapStar(tester, 4);
    expect(find.text('4점'), findsOneWidget);
    expect(buttonOf(tester, '평점 저장').onPressed, isNotNull);

    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(find.textContaining('평점을 등록했습니다.'), findsOneWidget);
    final call = ratings.createCalls.single;
    expect(call.memberId, 42);
    expect(call.request.toJson(), {
      'movieId': 550,
      'score': 4,
      'comment': '다시 보고 싶어요',
    });
  });

  testWidgets('등록이 실패하면 Dialog를 유지하고 입력을 보존한 채 서버 message를 보여준다', (
    tester,
  ) async {
    final ratings = FakeRatingApiService()
      ..createError = dioError(
        409,
        '/v6/members/42/ratings',
        code: 'COMMON409',
        message: '이미 이 영화에 평점을 남기셨습니다.',
      );
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/movies/550',
        memberId: 42,
        ratingApiService: ratings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tapStar(tester, 3);
    await tester.enterText(find.byType(TextField), '코멘트 유지');
    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
    expect(find.text('코멘트 유지'), findsOneWidget);
    expect(buttonOf(tester, '평점 저장').onPressed, isNotNull);
  });

  testWidgets('회원가입 전에는 내가 등록한 평점 대신 회원가입 안내를 보여준다', (tester) async {
    await tester.pumpWidget(buildApp(initialLocation: '/my'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
  });

  testWidgets('마이페이지 → 내가 등록한 평점은 하단 탭 없이 학습용 회원 목록을 연다', (tester) async {
    await tester.pumpWidget(buildApp(initialLocation: '/my', memberId: 42));
    await tester.pumpAndSettle();

    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('TMDB 영화 550'), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.textContaining('memberId 42'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
  });

  testWidgets('수정 버튼은 기존 별점·코멘트를 채운 Dialog를 열고, 저장 뒤 목록을 다시 읽는다', (
    tester,
  ) async {
    final ratings = FakeRatingApiService(ratings: [sampleRating()]);
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/my/ratings',
        memberId: 42,
        ratingApiService: ratings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('수정'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(RatingDialog), matching: find.text('5점')),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '최고의 영화!');

    await tapStar(tester, 2);
    await tester.enterText(find.byType(TextField), '다시 보니 아쉬워요');
    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();

    expect(ratings.updateCalls.single.score, 2);
    expect(ratings.updateCalls.single.comment, '다시 보니 아쉬워요');
    expect(find.text('다시 보니 아쉬워요'), findsOneWidget);
    expect(find.text('2점'), findsOneWidget);
  });

  testWidgets('삭제는 확인 Dialog를 거치고, 취소하면 요청하지 않으며 마지막 삭제 뒤 Empty가 된다', (
    tester,
  ) async {
    final ratings = FakeRatingApiService(ratings: [sampleRating()]);
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/my/ratings',
        memberId: 42,
        ratingApiService: ratings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('평점을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(ratings.deleteCalls, isEmpty);
    expect(find.text('최고의 영화!'), findsOneWidget);

    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
    await tester.pumpAndSettle();

    expect(ratings.deleteCalls.single.ratingId, 1);
    expect(find.text('아직 등록한 평점이 없어요.'), findsOneWidget);
  });

  testWidgets('편집 모드에서 여러 개를 선택해 삭제한다', (tester) async {
    final ratings = FakeRatingApiService(
      ratings: [
        sampleRating(),
        RatingDto(
          ratingId: 2,
          movieId: 13,
          score: 3,
          comment: null,
          createdAt: DateTime.utc(2026, 11, 8),
        ),
      ],
    );
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/my/ratings',
        memberId: 42,
        ratingApiService: ratings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('수정'), findsNothing);
    expect(buttonOf(tester, '선택한 0개 삭제').onPressed, isNull);

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(find.text('2개 선택됨'), findsOneWidget);

    await tester.tap(find.text('선택한 2개 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
    await tester.pumpAndSettle();

    expect(ratings.deleteCalls.map((call) => call.ratingId).toSet(), {1, 2});
    expect(find.text('아직 등록한 평점이 없어요.'), findsOneWidget);
    expect(find.text('선택한 평점을 삭제했어요.'), findsOneWidget);
  });

  testWidgets('MovieLogButton은 통신 중이면 비활성화되고 인디케이터만 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieLogButton(
            label: '중복 확인',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('중복 확인'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
}
