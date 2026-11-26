import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'test_app.dart';

void main() {
  testWidgets('토큰이 없으면 로그인 화면, 실패는 Form 오류, 성공하면 홈과 내 정보로 이동한다', (
    tester,
  ) async {
    final app = TestApp();
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    expect(find.text('MovieLog에 로그인'), findsOneWidget);

    await login(tester, password: 'wrong');
    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);

    await login(tester);
    expect(find.text('인기 1위'), findsOneWidget);
    expect(app.storage.token, 'token-movie@umc.com');

    // 어느 탭으로 진입해도 MainScreen이 불러온 내 정보를 마이페이지에서 씁니다.
    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('movie@umc.com'), findsOneWidget);
    expect(find.text('2026.10.10 가입'), findsOneWidget);
    expect(app.memberApi.fetchCalls, 1);
  });

  testWidgets('저장된 토큰은 GET me 검증 뒤 바로 홈으로 복원한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    expect(find.text('인기 1위'), findsOneWidget);
    expect(app.authApi.loginCalls, isEmpty);
    expect(app.memberApi.fetchCalls, 1); // 재시작 복원 뒤 MainScreen은 다시 부르지 않습니다.
  });

  testWidgets('세션 확인이 네트워크로 실패하면 스플래시에서 다시 시도한다', (tester) async {
    final memberApi = FakeMemberApiService()
      ..fetchError = dioError(500, '/v8/members/me');
    final app = TestApp(token: 'saved', memberApi: memberApi);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    expect(find.text('로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(app.storage.token, 'saved');

    memberApi.fetchError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('인기 1위'), findsOneWidget);
  });

  testWidgets('만료된 토큰으로 시작하면 로그인 화면에서 만료를 한 번 안내한다', (tester) async {
    final memberApi = FakeMemberApiService()
      ..fetchError = expiredError('/v8/members/me');
    final app = TestApp(token: 'old', memberApi: memberApi);
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    expect(find.text('MovieLog에 로그인'), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(app.storage.token, isNull);
  });

  testWidgets('로그아웃하면 토큰을 지우고, 보호 화면 접근은 로그인으로 돌려보낸다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(find.text('MovieLog에 로그인'), findsOneWidget);
    expect(app.storage.token, isNull);
    // 직접 로그아웃은 만료 안내를 띄우지 않습니다.
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);

    go(tester, '/my/ratings');
    await tester.pumpAndSettle();
    expect(find.text('MovieLog에 로그인'), findsOneWidget);
  });

  testWidgets('회원가입에 성공하면 로그인 화면으로 가서 이메일을 채워준다', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('아직 계정이 없으신가요? 회원가입'));
    await tester.pumpAndSettle();
    expect(find.text('회원가입'), findsOneWidget);

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

    expect(app.signUp.signUpRequests.single.email, 'lover@umc.com');
    expect(find.text('MovieLog에 로그인'), findsOneWidget);
    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.controller?.text, 'lover@umc.com');
  });

  testWidgets('이메일 저장을 체크하면 이메일만 저장하고 다음 로그인 화면에 채운다', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('이메일 저장'));
    await tester.pump();
    await login(tester);
    expect(app.emailPreference.saved, 'movie@umc.com');

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.controller?.text, 'movie@umc.com');
  });

  testWidgets('토큰으로 평점을 등록하고, 내가 등록한 평점에서 수정·삭제한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await createRatingFromDetail(tester);
    expect(find.textContaining('평점을 저장했습니다.'), findsOneWidget);
    // 아직 즐겨찾기하지 않은 영화라 movie-records로 저장합니다(체크하지 않으면 false).
    expect(app.recordApi.calls.single.toJson(), {
      'movieId': 1,
      'score': 4,
      'comment': '다시 보고 싶어요',
      'addToFavorites': false,
    });
    expect(app.ratingApi.createCalls, isEmpty);
    // 같은 세션에서 다시 들어오면 내 평점이 보입니다.
    expect(find.text('내 평점 관리하기'), findsOneWidget);

    await tester.tap(find.text('내 평점 관리하기'));
    await tester.pumpAndSettle();
    expect(find.text('이번 로그인에서 등록한 평점 1개'), findsOneWidget);
    expect(find.text('TMDB 영화 1'), findsOneWidget);

    // 수정 Dialog에는 기존 별점·코멘트가 채워져 있습니다.
    await tester.tap(find.byTooltip('수정'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byType(RatingDialog),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, '다시 보고 싶어요');
    await tapStar(tester, 2);
    await tester.enterText(find.byType(TextField), '다시 보니 아쉬워요');
    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();
    expect(app.ratingApi.updateCalls.single.score, 2);
    expect(find.text('다시 보니 아쉬워요'), findsOneWidget);

    // 삭제는 확인 Dialog를 거치고, 취소하면 요청하지 않습니다.
    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(app.ratingApi.deleteCalls, isEmpty);

    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MovieLogButton, '삭제'));
    await tester.pumpAndSettle();
    expect(app.ratingApi.deleteCalls, [300]);
    expect(find.textContaining('이번 로그인에서 등록한 평점이 없어요.'), findsOneWidget);
  });

  testWidgets('평점 등록 중 토큰이 만료되면 로그인 화면으로 보내고 안내한다', (tester) async {
    final app = TestApp(token: 'saved');
    app.recordApi.error = expiredError('/v8/movie-records');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await createRatingFromDetail(tester);

    expect(find.text('MovieLog에 로그인'), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(app.storage.token, isNull);
  });

  testWidgets('RATING409_1은 Dialog를 닫고 Snackbar로 안내하며 로그인을 유지한다', (
    tester,
  ) async {
    final app = TestApp(token: 'saved');
    // 이미 즐겨찾기한 영화는 기존 평점 API(POST /v8/ratings)로 평점만 저장합니다.
    app.favoriteApi.seed('saved', [1]);
    app.ratingApi.createError = dioError(
      409,
      '/v8/ratings',
      code: 'RATING409_1',
      message: '이미 이 영화에 평점을 남기셨습니다.',
    );
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await createRatingFromDetail(tester, comment: '코멘트');

    expect(app.ratingApi.createCalls.single.movieId, 1);
    expect(app.recordApi.calls, isEmpty);
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
    expect(app.storage.token, 'saved');
  });

  testWidgets('COMMON400은 Dialog를 열어 둔 채 입력값을 유지한다', (tester) async {
    final app = TestApp(token: 'saved');
    app.recordApi.error = dioError(
      400,
      '/v8/movie-records',
      code: 'COMMON400',
      message: '별점은 5점 이하여야 합니다.',
    );
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await createRatingFromDetail(tester, comment: '코멘트 유지');

    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('별점은 5점 이하여야 합니다.'), findsOneWidget);
    expect(find.text('코멘트 유지'), findsOneWidget);
  });

  testWidgets('프로필 수정은 마이페이지에 바로 반영되고, 409는 입력값을 유지한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    app.memberApi.updateError = dioError(
      409,
      '/v8/members/me',
      code: 'MEMBER409_1',
      message: '이미 사용 중인 닉네임입니다.',
    );
    await tester.enterText(find.byType(TextField).last, '영화광');
    await tester.tap(find.widgetWithText(MovieLogButton, '저장'));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
    expect(find.text('영화광'), findsOneWidget);

    app.memberApi.updateError = null;
    await tester.enterText(find.byType(TextField).last, '새닉네임');
    await tester.tap(find.widgetWithText(MovieLogButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('새닉네임'), findsOneWidget);
    expect(find.text('프로필을 수정했어요.'), findsOneWidget);
  });

  testWidgets('변경 내용이 있으면 뒤로가기 전에 확인 Dialog를 띄운다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '바꾸는중');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('수정을 취소할까요?'), findsOneWidget);

    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(find.text('바꾸는중'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);
    expect(app.memberApi.updateCalls, isEmpty);
  });

  testWidgets('편집 모드에서 여러 개를 선택해 삭제한다', (tester) async {
    final app = TestApp(token: 'saved');
    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    await createRatingFromDetail(tester);
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영화 2'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tapStar(tester, 3);
    await tester.tap(find.text('평점 저장'));
    await tester.pumpAndSettle();

    go(tester, '/my/ratings');
    await tester.pumpAndSettle();
    expect(find.text('이번 로그인에서 등록한 평점 2개'), findsOneWidget);

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

    expect(app.ratingApi.deleteCalls.toSet(), {300, 301});
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
