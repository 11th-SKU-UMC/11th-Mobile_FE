import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/main.dart';
import 'package:movielog/services/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const login = LoginRequest(email: 'member@example.test', password: 'fixture');
const ratingRequest = CreateRatingRequest(movieId: 550, score: 4);
const member = {
  'email': 'member@example.test',
  'nickname': '시네마',
  'createdAt': '2026-10-10T12:00:00Z',
};
const rating = {
  'ratingId': 12,
  'movieId': 550,
  'score': 4,
  'comment': null,
  'createdAt': '2026-10-10T12:00:00Z',
};

class MemoryStorage implements TokenStorage {
  MemoryStorage([this.token]);

  String? token;
  int deletes = 0;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String value) async => token = value;

  @override
  Future<void> deleteAccessToken() async {
    deletes++;
    token = null;
  }
}

class WorkbookAdapter implements HttpClientAdapter {
  WorkbookAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object? data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody response(int status, Object? result, {String? error}) =>
    jsonBody(status, {
      'isSuccess': error == null,
      'code': error ?? 'COMMON$status',
      'message': 'fixture',
      'result': result,
    });

ResponseBody loggedIn([String token = 'fixture-token']) =>
    response(200, {'nickname': '시네마', 'accessToken': token});

class Fixture {
  Fixture(this.storage, WorkbookAdapter adapter) {
    publicClient.httpClientAdapter = adapter;
    protectedClient.httpClientAdapter = adapter;
    auth = AuthViewModel(
      storage,
      AuthApiService(publicClient),
      MemberApiService(protectedClient),
    );
    protectedClient.interceptors.add(
      AuthInterceptor(
        Uri.parse(protectedClient.options.baseUrl),
        () => auth.credentials,
        auth.expireSession,
      ),
    );
    api = RatingApiService(publicClient, protectedClient);
    ratings = SessionRatings(auth, api);
    addTearDown(() {
      ratings.dispose();
      auth.dispose();
      publicClient.close();
      protectedClient.close();
    });
  }

  final MemoryStorage storage;
  final publicClient = createMovieLogClient();
  final protectedClient = createMovieLogClient();
  late final AuthViewModel auth;
  late final RatingApiService api;
  late final SessionRatings ratings;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'v8 writes return Rating objects and isolate Bearer by origin and path',
    () async {
      const external = 'https://example.test/v8/ratings/12';
      final fixture = Fixture(
        MemoryStorage(),
        WorkbookAdapter((request) {
          final protected =
              request.uri.host == 'workbook.devnoco.com' &&
              request.uri.path.startsWith('/v8/ratings');
          expect(
            request.headers['Authorization'],
            protected ? 'Bearer fixture-token' : null,
          );
          switch ((request.method, request.path)) {
            case ('POST', '/v8/auth/login'):
              return loggedIn();
            case ('GET', '/v8/members/8/ratings'):
              return jsonBody(200, [rating]);
            case ('GET', external):
              return jsonBody(200, null);
            case ('POST', '/v8/ratings'):
              expect(request.data, {'movieId': 550, 'score': 4});
              return response(201, rating);
            case ('PATCH', '/v8/ratings/12'):
              expect(request.data, {'score': 5, 'comment': null});
              return response(200, {...rating, 'score': 5});
            case ('DELETE', '/v8/ratings/12'):
              return response(200, null);
            default:
              throw StateError('Unexpected fixture path');
          }
        }),
      );

      await fixture.auth.restoreSession();
      expect(await fixture.auth.login(login), isTrue);
      expect((await fixture.api.fetchMyRatings(8)).single.ratingId, 12);
      await fixture.protectedClient.get(
        external,
        options: Options(headers: {'authorization': 'Bearer fixture-token'}),
      );
      await fixture.protectedClient.get('/v8/members/8/ratings');
      final version = fixture.ratings.version;
      await fixture.ratings.create(version, ratingRequest, null);
      final created = fixture.ratings.forMovie(550)!;
      expect(created.ratingId, 12);
      await fixture.ratings.update(version, created, 5, null);
      expect(fixture.ratings.forMovie(550)?.score, 5);
      await fixture.ratings.delete(version, created);
      expect(fixture.ratings.entries, isEmpty);
    },
  );

  test(
    'offline restore retries GET me and concurrent expiry clears storage once',
    () async {
      final storage = MemoryStorage('stored-fixture');
      final fixture = Fixture(
        storage,
        WorkbookAdapter((request) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        }),
      );
      await fixture.auth.restoreSession();
      expect(fixture.auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'stored-fixture');
      expect(storage.deletes, 0);

      final verification = Completer<ResponseBody>();
      fixture.protectedClient.httpClientAdapter = WorkbookAdapter((request) {
        expect(request.path, '/v8/members/me');
        expect(request.headers['Authorization'], 'Bearer stored-fixture');
        return verification.future;
      });
      final retry = fixture.auth.restoreSession();
      expect(fixture.auth.status, AuthStatus.initializing);
      expect(fixture.auth.member, isNull);
      verification.complete(response(200, member));
      await retry;
      expect(fixture.auth.member?.nickname, '시네마');

      final bothStarted = Completer<void>();
      final expiry = Completer<ResponseBody>();
      var requests = 0;
      fixture.protectedClient.httpClientAdapter = WorkbookAdapter((_) {
        if (++requests == 2) bothStarted.complete();
        return expiry.future;
      });
      final api = MemberApiService(fixture.protectedClient);
      final first = expectLater(api.fetchMe(), throwsA(isA<DioException>()));
      final second = expectLater(api.fetchMe(), throwsA(isA<DioException>()));
      await bothStarted.future;
      expiry.complete(response(401, null, error: 'AUTH401_4'));
      await Future.wait([first, second]);
      expect(fixture.auth.status, AuthStatus.signedOut);
      expect(storage.deletes, 1);
      expect(storage.token, isNull);
      expect(fixture.auth.consumeSessionExpired(), isTrue);
      expect(fixture.auth.consumeSessionExpired(), isFalse);
    },
  );

  test(
    'late 401 and successful writes from old account leave new session intact',
    () async {
      final pending = List.generate(2, (_) => Completer<ResponseBody>());
      final started = Completer<void>();
      final storage = MemoryStorage();
      var requests = 0;
      var logins = 0;
      final fixture = Fixture(
        storage,
        WorkbookAdapter((request) {
          if (request.path == '/v8/auth/login') {
            return loggedIn('fixture-${++logins}');
          }
          final index = requests++;
          if (requests == 2) started.complete();
          return pending[index].future;
        }),
      );

      await fixture.auth.restoreSession();
      await fixture.auth.login(login);
      final version = fixture.ratings.version;
      final stale401 = expectLater(
        fixture.ratings.create(version, ratingRequest, null),
        throwsA(isA<DioException>()),
      );
      final staleSuccess = fixture.ratings.create(version, ratingRequest, null);
      await started.future;
      await fixture.auth.logout();
      await fixture.auth.login(login);
      pending[0].complete(response(401, null, error: 'AUTH401_4'));
      pending[1].complete(response(201, rating));
      await Future.wait([stale401, staleSuccess]);
      expect(fixture.auth.status, AuthStatus.signedIn);
      expect(storage.token, 'fixture-2');
      expect(storage.deletes, 1);
      expect(fixture.ratings.entries, isEmpty);
      expect(fixture.auth.consumeSessionExpired(), isFalse);
    },
  );

  testWidgets(
    'login errors, profile update, and protected redirect after logout',
    (tester) async {
      dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=fixture');
      var attempts = 0;
      final storage = MemoryStorage();
      final adapter = WorkbookAdapter((request) {
        if (request.path == '/v8/auth/login') {
          return ++attempts == 1
              ? response(401, null, error: 'AUTH401_1')
              : loggedIn();
        }
        if (request.method == 'GET') return response(200, member);
        final nickname = (request.data as Map)['nickname'];
        if (nickname == '중복닉네임') {
          return response(409, null, error: 'MEMBER409_1');
        }
        if (nickname == '연결오류') {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        }
        return response(200, {...member, 'nickname': nickname});
      });
      await tester.pumpWidget(
        MovieLogApp(tokenStorage: storage, movieLogAdapter: adapter),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.text('MovieLog 로그인')));
      router.go('/my/profile/edit');
      await tester.pumpAndSettle();
      expect(find.text('MovieLog 로그인'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), login.email);
      await tester.enterText(find.byType(TextFormField).at(1), login.password);
      final loginButton = find.widgetWithText(ElevatedButton, '로그인');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
      expect(find.textContaining('로그인이 만료'), findsNothing);
      await tester.tap(find.text('이메일 저장'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), {'movielog.saved_email'});
      expect(preferences.getString('movielog.saved_email'), login.email);
      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();
      expect(find.text('시네마'), findsOneWidget);
      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);

      final nickname = find.byType(TextFormField).at(1);
      final save = find.widgetWithText(ElevatedButton, '저장');
      await tester.enterText(nickname, '한');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('2~12자'), findsOneWidget);
      await tester.enterText(nickname, '중복닉네임');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
      expect(find.text('중복닉네임'), findsOneWidget);
      await tester.enterText(nickname, '연결오류');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('프로필을 수정하지 못했어요'), findsOneWidget);
      expect(find.text('연결오류'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('편집을 그만할까요?'), findsOneWidget);
      await tester.tap(find.text('계속 편집'));
      await tester.pumpAndSettle();
      expect(find.text('연결오류'), findsOneWidget);
      await tester.enterText(nickname, '새시네마');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('새시네마'), findsOneWidget);

      await tester.tap(find.byTooltip('로그아웃'));
      await tester.pumpAndSettle();
      expect(storage.token, isNull);
      expect(find.textContaining('로그인이 만료'), findsNothing);
      router.go('/my/ratings');
      await tester.pumpAndSettle();
      expect(find.text('MovieLog 로그인'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid stored token routes to login and announces expiry once',
    (tester) async {
      dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=fixture');
      final storage = MemoryStorage('invalid-fixture');
      await tester.pumpWidget(
        MovieLogApp(
          tokenStorage: storage,
          movieLogAdapter: WorkbookAdapter(
            (_) => response(401, null, error: 'AUTH401_3'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MovieLog 로그인'), findsOneWidget);
      expect(find.textContaining('로그인이 만료'), findsOneWidget);
      expect(storage.deletes, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.textContaining('로그인이 만료'), findsNothing);
    },
  );
}
