import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/load_status.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'fakes.dart';

RatingDto rating(int id, int movieId, {int score = 4, String? comment}) =>
    RatingDto(
      ratingId: id,
      movieId: movieId,
      score: score,
      comment: comment,
      createdAt: DateTime.utc(2026, 11, 19),
    );

/// 요청 헤더를 기록하고 고정 응답을 돌려주는 가짜 HTTP 어댑터입니다.
class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter({this.statusCode = 200, this.body = const {}});

  final int statusCode;
  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio dioWith(RecordingAdapter adapter, {FakeTokenStorage? storage}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
    ..httpClientAdapter = adapter;
  if (storage != null) dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}

void main() {
  group('authRedirect', () {
    test('초기화·재시도 중에는 스플래시에 머문다', () {
      expect(authRedirect(AuthStatus.initializing, '/home'), '/start');
      expect(authRedirect(AuthStatus.retryRequired, '/login'), '/start');
      expect(authRedirect(AuthStatus.initializing, '/start'), isNull);
    });

    test('로그아웃 상태는 공개 화면만 허용한다', () {
      expect(authRedirect(AuthStatus.signedOut, '/my/ratings'), '/login');
      expect(authRedirect(AuthStatus.signedOut, '/start'), '/login');
      expect(authRedirect(AuthStatus.signedOut, '/register'), isNull);
      expect(authRedirect(AuthStatus.authenticating, '/login'), isNull);
    });

    test('로그인 상태는 스플래시·로그인·회원가입에서 홈으로 보낸다', () {
      expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/my/profile/edit'), isNull);
    });
  });

  group('AuthInterceptor', () {
    test('보호 경로에만 Bearer 헤더를 붙인다', () async {
      final adapter = RecordingAdapter();
      final dio = dioWith(adapter, storage: FakeTokenStorage('abc'));

      await dio.get('/v7/members/me');
      await dio.post('/v7/ratings');
      await dio.delete('/v7/ratings/3');
      await dio.post('/v7/auth/login');
      await dio.get('/v7/members/1/ratings');

      final headers = adapter.requests
          .map((r) => r.headers['Authorization'])
          .toList();
      expect(headers, ['Bearer abc', 'Bearer abc', 'Bearer abc', null, null]);
    });

    test('다른 host에는 토큰을 보내지 않는다', () async {
      final adapter = RecordingAdapter();
      final dio = dioWith(adapter, storage: FakeTokenStorage('abc'));

      await dio.get('https://api.themoviedb.org/v7/members/me');

      expect(adapter.requests.single.headers['Authorization'], isNull);
    });

    test('토큰이 없으면 헤더 없이 보내고, 저장소 실패는 code 없는 오류로 거절한다', () async {
      final adapter = RecordingAdapter();
      final storage = FakeTokenStorage();
      final dio = dioWith(adapter, storage: storage);

      await dio.get('/v7/members/me');
      expect(adapter.requests.single.headers['Authorization'], isNull);

      storage.failRead = true;
      await expectLater(
        dio.get('/v7/members/me'),
        throwsA(
          isA<DioException>().having((e) => e.response, 'response', isNull),
        ),
      );
    });
  });

  group('RatingApiService v7', () {
    test('등록 result를 Rating 객체로 파싱하고 path·body에 memberId가 없다', () async {
      final adapter = RecordingAdapter(
        statusCode: 201,
        body: {
          'isSuccess': true,
          'code': 'COMMON201',
          'message': '평점을 등록했습니다.',
          'result': {
            'ratingId': 12,
            'movieId': 550,
            'score': 5,
            'comment': null,
            'createdAt': '2026-11-19T12:00:00.000Z',
            'updatedAt': '2026-11-19T12:00:00.000Z',
          },
        },
      );
      final service = RatingApiService(Dio(), dioWith(adapter));
      final created = await service.createRating(
        const CreateRatingRequest(movieId: 550, score: 5),
      );

      expect(created.ratingId, 12);
      final request = adapter.requests.single;
      expect(request.path, '/v7/ratings');
      expect((request.data as Map).containsKey('memberId'), isFalse);
    });

    test('삭제는 200 + result null을 성공으로 본다', () async {
      final adapter = RecordingAdapter(
        body: {
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '삭제했습니다.',
          'result': null,
        },
      );
      final service = RatingApiService(Dio(), dioWith(adapter));
      await service.deleteRating(12);
      expect(adapter.requests.single.path, '/v7/ratings/12');
    });
  });

  group('AuthViewModel', () {
    test('저장된 토큰이 없으면 signedOut이 된다', () async {
      final auth = AuthViewModel(
        FakeAuthApiService(),
        FakeMemberApiService(),
        FakeTokenStorage(),
      );
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isFalse);
    });

    test('토큰이 있어도 GET me 검증이 끝난 뒤에만 signedIn이 된다', () async {
      final memberApi = FakeMemberApiService()..fetchGate = Completer<void>();
      final auth = AuthViewModel(
        FakeAuthApiService(),
        memberApi,
        FakeTokenStorage('saved'),
      );
      final restoring = auth.restoreSession();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.initializing);

      memberApi.fetchGate!.complete();
      await restoring;
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '무비러버');
    });

    test('만료 토큰(AUTH401_4)이면 토큰을 지우고 만료 안내를 켠다', () async {
      final storage = FakeTokenStorage('old');
      final memberApi = FakeMemberApiService()
        ..fetchError = expiredError('/v7/members/me');
      final auth = AuthViewModel(FakeAuthApiService(), memberApi, storage);

      await auth.restoreSession();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('네트워크 실패는 토큰을 지우지 않고 재시도 상태가 된다', () async {
      final storage = FakeTokenStorage('valid');
      final memberApi = FakeMemberApiService()
        ..fetchError = dioError(500, '/v7/members/me');
      final auth = AuthViewModel(FakeAuthApiService(), memberApi, storage);

      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'valid');

      memberApi.fetchError = null;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
    });

    test('로그인 성공은 토큰을 저장하고 signedIn이 된다', () async {
      final storage = FakeTokenStorage();
      final auth = await signedInAuth(storage: storage);

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'token-movie@umc.com');
      expect(auth.member, isNull); // 내 정보는 MainScreen이 loadMember()로 불러옵니다.
    });

    test('로그인 실패 AUTH401_1은 Form 오류이며 만료 안내를 켜지 않는다', () async {
      final storage = FakeTokenStorage();
      final auth = AuthViewModel(
        FakeAuthApiService(),
        FakeMemberApiService(),
        storage,
      );
      await auth.login('movie@umc.com', 'wrong');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(auth.sessionExpired, isFalse);
      expect(storage.saveCalls, 0);
    });

    test('loadMember의 401은 세션을 정리하고, 네트워크 실패는 로그아웃하지 않는다', () async {
      final memberApi = FakeMemberApiService()
        ..fetchError = dioError(500, '/v7/members/me');
      final auth = await signedInAuth(memberApi: memberApi);

      await auth.loadMember();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.memberStatus, MemberLoadStatus.error);

      memberApi.fetchError = expiredError('/v7/members/me', code: 'AUTH401_3');
      await auth.loadMember(force: true);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
    });

    test('직접 로그아웃은 토큰을 지우지만 만료 안내는 켜지 않는다', () async {
      final storage = FakeTokenStorage();
      final auth = await signedInAuth(storage: storage);
      await auth.loadMember();

      await auth.logout();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
      expect(storage.token, isNull);
      expect(auth.sessionExpired, isFalse);
    });

    test('로그아웃 뒤 늦게 도착한 내 정보 응답은 반영하지 않는다', () async {
      final memberApi = FakeMemberApiService()..fetchGate = Completer<void>();
      final auth = await signedInAuth(memberApi: memberApi);

      final loading = auth.loadMember();
      await auth.logout();
      memberApi.fetchGate!.complete();
      await loading;

      expect(auth.member, isNull);
      expect(auth.status, AuthStatus.signedOut);
    });

    test('동시에 여러 번 만료돼도 토큰 삭제는 한 번만 실행한다', () async {
      final storage = FakeTokenStorage();
      final auth = await signedInAuth(storage: storage);

      await Future.wait([auth.expireSession(), auth.expireSession()]);

      expect(storage.deleteCalls, 1);
    });
  });

  group('EditProfileViewModel', () {
    Future<(AuthViewModel, FakeMemberApiService)> setup() async {
      final memberApi = FakeMemberApiService();
      final auth = await signedInAuth(memberApi: memberApi);
      await auth.loadMember();
      return (auth, memberApi);
    }

    test('2~12자 규칙은 요청 전에 검사한다', () async {
      final (auth, memberApi) = await setup();
      final viewModel = EditProfileViewModel(memberApi, auth);

      expect(await viewModel.save('가'), isFalse);
      expect(viewModel.nicknameError, '닉네임은 2~12자로 입력해 주세요.');
      expect(memberApi.updateCalls, isEmpty);
    });

    test('현재 닉네임과 같으면 요청 없이 완료한다', () async {
      final (auth, memberApi) = await setup();
      final viewModel = EditProfileViewModel(memberApi, auth);

      expect(await viewModel.save(' 무비러버 '), isTrue);
      expect(memberApi.updateCalls, isEmpty);
    });

    test('성공하면 AuthViewModel.member를 교체한다', () async {
      final (auth, memberApi) = await setup();
      final viewModel = EditProfileViewModel(memberApi, auth);

      expect(await viewModel.save('새닉네임'), isTrue);
      expect(auth.member?.nickname, '새닉네임');
    });

    test('MEMBER409_1은 필드 오류, 네트워크 실패는 Snackbar 문구이며 로그아웃하지 않는다', () async {
      final (auth, memberApi) = await setup();
      final viewModel = EditProfileViewModel(memberApi, auth);

      memberApi.updateError = dioError(
        409,
        '/v7/members/me',
        code: 'MEMBER409_1',
        message: '이미 사용 중인 닉네임입니다.',
      );
      expect(await viewModel.save('영화광'), isFalse);
      expect(viewModel.nicknameError, '이미 사용 중인 닉네임이에요.');

      memberApi.updateError = dioError(500, '/v7/members/me');
      expect(await viewModel.save('영화광2'), isFalse);
      expect(viewModel.message, '네트워크 상태를 확인하고 다시 시도해 주세요.');
      expect(auth.status, AuthStatus.signedIn);
    });

    test('401은 세션을 만료시킨다', () async {
      final (auth, memberApi) = await setup();
      final viewModel = EditProfileViewModel(memberApi, auth);
      memberApi.updateError = expiredError('/v7/members/me');

      expect(await viewModel.save('새닉네임'), isFalse);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
    });
  });

  group('MovieDetailViewModel v7 등록', () {
    test('등록 result를 세션 평점 목록에 영화 정보와 함께 넣는다', () async {
      final auth = await signedInAuth();
      final ratings = FakeRatingApiService();
      final store = MyRatingsViewModel(ratings, auth);
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        auth,
        store,
        550,
        initialMovie: movieDto(550),
      );
      await viewModel.load();
      await viewModel.createRating(score: 5, comment: '  최고  ');

      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(ratings.createCalls.single.toJson(), {
        'movieId': 550,
        'score': 5,
        'comment': '최고',
      });
      expect(store.ratings.single.rating.movieId, 550);
      expect(store.ratings.single.movie?.title, 'TMDB 영화 550');
    });

    test('RATING409_1은 서버 message를 보여주고 로그인을 유지한다', () async {
      final auth = await signedInAuth();
      final ratings = FakeRatingApiService()
        ..createError = dioError(
          409,
          '/v7/ratings',
          code: 'RATING409_1',
          message: '이미 이 영화에 평점을 남기셨습니다.',
        );
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        auth,
        MyRatingsViewModel(ratings, auth),
        550,
      );
      await viewModel.load();
      await viewModel.createRating(score: 3);

      expect(viewModel.submitMessage, '이미 이 영화에 평점을 남기셨습니다.');
      expect(auth.status, AuthStatus.signedIn);
    });

    test('만료 401이면 세션을 정리한다', () async {
      final auth = await signedInAuth();
      final ratings = FakeRatingApiService()
        ..createError = expiredError('/v7/ratings');
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        auth,
        MyRatingsViewModel(ratings, auth),
        550,
      );
      await viewModel.load();
      expect(viewModel.status, LoadStatus.success);
      await viewModel.createRating(score: 3);

      expect(auth.status, AuthStatus.signedOut);
      expect(viewModel.submitMessage, '로그인이 만료됐어요. 다시 로그인해 주세요.');
    });

    test('로그아웃 뒤 늦게 도착한 등록 응답은 목록에 넣지 않는다', () async {
      final auth = await signedInAuth();
      final ratings = FakeRatingApiService()..createGate = Completer<void>();
      final store = MyRatingsViewModel(ratings, auth);
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        auth,
        store,
        550,
      );
      await viewModel.load();

      final pending = viewModel.createRating(score: 4);
      await auth.logout();
      ratings.createGate!.complete();
      await pending;

      expect(store.ratings, isEmpty);
    });
  });

  group('MyRatingsViewModel (세션 평점)', () {
    test('수정 성공 result로 카드를 교체하고 영화 정보는 유지한다', () async {
      final auth = await signedInAuth();
      final service = FakeRatingApiService();
      final store = MyRatingsViewModel(service, auth)
        ..addCreated(rating(1, 550, comment: '좋아요'), movieDto(550));

      await store.updateRating(ratingId: 1, score: 2, comment: '다시 보니 별로');

      final entry = store.ratings.single;
      expect(entry.rating.score, 2);
      expect(entry.rating.comment, '다시 보니 별로');
      expect(entry.movie?.id, 550);
    });

    test('RATING403_1은 다시 던지지만 로그아웃하지 않고 카드도 남긴다', () async {
      final auth = await signedInAuth();
      final service = FakeRatingApiService()
        ..updateError = dioError(
          403,
          '/v7/ratings/1',
          code: 'RATING403_1',
          message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
        );
      final store = MyRatingsViewModel(service, auth)
        ..addCreated(rating(1, 550), null);

      await expectLater(
        store.updateRating(ratingId: 1, score: 3),
        throwsA(isA<DioException>()),
      );
      expect(auth.status, AuthStatus.signedIn);
      expect(store.ratings, hasLength(1));
    });

    test('RATING404_1이면 서버에 없는 평점이므로 목록에서 지운다', () async {
      final auth = await signedInAuth();
      final service = FakeRatingApiService();
      service.deleteErrors[1] = dioError(
        404,
        '/v7/ratings/1',
        code: 'RATING404_1',
        message: '해당 평점을 찾을 수 없습니다.',
      );
      final store = MyRatingsViewModel(service, auth)
        ..addCreated(rating(1, 550), null);

      await expectLater(store.deleteRating(1), throwsA(isA<DioException>()));
      expect(store.ratings, isEmpty);
    });

    test('세션이 바뀌면 이전 세션의 평점을 비운다', () async {
      final auth = await signedInAuth();
      final store = MyRatingsViewModel(FakeRatingApiService(), auth)
        ..addCreated(rating(1, 550), null);

      await auth.logout();
      expect(store.ratings, isEmpty);
    });

    test('다중 삭제 중 만료되면 남은 요청을 보내지 않고 세션을 정리한다', () async {
      final auth = await signedInAuth();
      final service = FakeRatingApiService();
      service.deleteErrors[1] = expiredError('/v7/ratings/1');
      final store = MyRatingsViewModel(service, auth)
        ..addCreated(rating(2, 13), null)
        ..addCreated(rating(1, 550), null);

      store.enterEditMode();
      store.toggleSelection(1);
      store.toggleSelection(2);
      await store.deleteSelectedRatings();

      expect(service.deleteCalls, [1]);
      expect(auth.status, AuthStatus.signedOut);
      expect(store.ratings, isEmpty);
    });

    test('다중 삭제에서 일부만 실패하면 실패한 항목만 선택 상태로 남긴다', () async {
      final auth = await signedInAuth();
      final service = FakeRatingApiService();
      service.deleteErrors[2] = dioError(500, '/v7/ratings/2');
      final store = MyRatingsViewModel(service, auth)
        ..addCreated(rating(3, 680), null)
        ..addCreated(rating(2, 13), null)
        ..addCreated(rating(1, 550), null);

      store.enterEditMode();
      store.toggleSelection(1);
      store.toggleSelection(2);
      final failed = await store.deleteSelectedRatings();

      expect(failed, 1);
      expect(store.selectedRatingIds, {2});
      expect(store.isEditMode, isTrue);
      expect(store.ratings.map((e) => e.rating.ratingId), [2, 3]);
    });
  });
}
