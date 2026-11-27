import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';

import 'support/fake_services.dart';

/// AuthInterceptor를 지난 뒤의 요청을 기록하고 네트워크 없이 200으로 끝낸다.
class _Capture {
  final List<RequestOptions> requests = [];

  Interceptor get interceptor => InterceptorsWrapper(
    onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    },
  );

  /// 기록된 요청에 Bearer가 붙었는지. 헤더 값 자체는 출력하지 않는다.
  bool hasBearer(int index) =>
      requests[index].headers['Authorization'] == 'Bearer $testToken';

  bool hasNoAuthorization(int index) =>
      !requests[index].headers.containsKey('Authorization');
}

void main() {
  late MemoryTokenStorage storage;
  late _Capture capture;
  late Dio dio;

  setUp(() {
    storage = MemoryTokenStorage(token: testToken);
    capture = _Capture();
    dio = createAuthMovieLogClient(storage)
      ..interceptors.add(capture.interceptor);
  });

  test(
    '보호 경로(/v8/members/me, /v8/ratings, /v8/ratings/*)에는 Bearer를 붙인다',
    () async {
      await dio.get('/v8/members/me');
      await dio.patch('/v8/members/me');
      await dio.post('/v8/ratings');
      await dio.patch('/v8/ratings/3');
      await dio.delete('/v8/ratings/3');

      expect(capture.requests, hasLength(5));
      for (var i = 0; i < capture.requests.length; i++) {
        expect(capture.hasBearer(i), isTrue, reason: capture.requests[i].path);
      }
    },
  );

  test('즐겨찾기 보호 경로(POST·GET /v8/favorites, GET·DELETE /v8/favorites/{id})에는 '
      'Bearer를 붙인다', () async {
    await dio.post('/v8/favorites', data: {'movieId': 550});
    await dio.get('/v8/favorites');
    await dio.get('/v8/favorites/550');
    await dio.delete('/v8/favorites/550');

    expect(capture.requests, hasLength(4));
    for (var i = 0; i < capture.requests.length; i++) {
      expect(
        capture.hasBearer(i),
        isTrue,
        reason: '${capture.requests[i].method} ${capture.requests[i].path}',
      );
    }
  });

  test('즐겨찾기 경로라도 계약에 없는 method·id 형식에는 붙이지 않는다', () async {
    await dio.delete('/v8/favorites');
    await dio.patch('/v8/favorites');
    await dio.post('/v8/favorites/550');
    await dio.patch('/v8/favorites/550');
    await dio.get('/v8/favorites/0');
    await dio.get('/v8/favorites/abc');
    await dio.get('/v8/favorites/550/x');

    for (var i = 0; i < capture.requests.length; i++) {
      expect(
        capture.hasNoAuthorization(i),
        isTrue,
        reason: '${capture.requests[i].method} ${capture.requests[i].path}',
      );
    }
  });

  test('공개 경로(로그인·유저별 평점 조회·중복 확인·회원가입)와 이전 버전 경로에는 붙이지 않는다', () async {
    await dio.post('/v8/auth/login');
    await dio.get('/v8/members/7/ratings');
    await dio.get('/v8/members/nickname/abc');
    await dio.get('/v8/members/email/a%40b.com');
    await dio.post('/v8/members');
    await dio.get('/v8/ratingsX');
    await dio.post('/v8/movie-records');
    // 9주차부터 /v7은 보호 경로가 아니다.
    await dio.get('/v7/members/me');
    await dio.post('/v7/ratings');
    await dio.get('/v6/members/7/ratings');

    for (var i = 0; i < capture.requests.length; i++) {
      expect(
        capture.hasNoAuthorization(i),
        isTrue,
        reason: capture.requests[i].path,
      );
    }
  });

  test('다른 host(TMDB·외부 이미지)에는 같은 path라도 붙이지 않는다', () async {
    await dio.get('https://api.themoviedb.org/v8/ratings');
    await dio.get('https://api.themoviedb.org/v8/favorites');
    await dio.get('https://image.tmdb.org/t/p/w500/a.jpg');
    await dio.get('https://evil.example/v8/members/me');

    for (var i = 0; i < capture.requests.length; i++) {
      expect(
        capture.hasNoAuthorization(i),
        isTrue,
        reason: capture.requests[i].uri.toString(),
      );
    }
  });

  test('공개 경로에 미리 넣은 Authorization도 지워 토큰이 새지 않게 한다', () async {
    await dio.get(
      '/v8/members/7/ratings',
      options: Options(headers: {'Authorization': 'Bearer leftover'}),
    );

    expect(capture.hasNoAuthorization(0), isTrue);
  });

  test('저장된 토큰이 없으면 보호 경로에도 Authorization을 붙이지 않는다', () async {
    storage.token = null;

    await dio.get('/v8/members/me');
    await dio.get('/v8/favorites');

    expect(capture.hasNoAuthorization(0), isTrue);
    expect(capture.hasNoAuthorization(1), isTrue);
  });

  test('저장소를 읽지 못하면 서버 401과 구분되는 오류로 요청을 막는다', () async {
    storage.readError = StateError('keychain');

    // 보호 경로는 토큰 읽기를 거치므로 저장소 오류로 막힌다.
    for (final request in [
      () => dio.get('/v8/members/me'),
      () => dio.get('/v8/favorites/550'),
    ]) {
      await expectLater(
        request(),
        throwsA(
          isA<DioException>()
              .having((e) => e.response, 'response', isNull)
              .having((e) => e.error, 'error', isA<StateError>())
              .having(
                (e) => (e.error as StateError).message,
                'message',
                '인증 저장소를 읽지 못했습니다.',
              ),
        ),
      );
    }
    expect(capture.requests, isEmpty);

    // 공개 경로는 토큰을 읽지 않으므로 같은 저장소 오류에도 그대로 나간다.
    await dio.post('/v8/auth/login');
    expect(capture.requests.single.path, '/v8/auth/login');
  });

  test('isProtected는 workbook host의 v8 보호 경로만 true다', () {
    bool check(String url, [String method = 'GET']) =>
        AuthInterceptor.isProtected(Uri.parse(url), method);
    const host = 'https://workbook.devnoco.com';

    expect(check('$host/v8/ratings/12'), isTrue);
    expect(check('$host/v8/members/me'), isTrue);
    expect(check('$host/v8/favorites', 'POST'), isTrue);
    expect(check('$host/v8/favorites', 'get'), isTrue);
    expect(check('$host/v8/favorites/550', 'DELETE'), isTrue);
    expect(check('$host/v8/favorites/550', 'POST'), isFalse);
    expect(check('$host/v8/members/me/x'), isFalse);
    expect(check('$host/v8/auth/login', 'POST'), isFalse);
    expect(check('$host/v8/movie-records', 'POST'), isFalse);
    expect(check('$host/v7/members/me'), isFalse);
  });
}
