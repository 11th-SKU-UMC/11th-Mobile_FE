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
    '보호 경로(/v7/members/me, /v7/ratings, /v7/ratings/*)에는 Bearer를 붙인다',
    () async {
      await dio.get('/v7/members/me');
      await dio.patch('/v7/members/me');
      await dio.post('/v7/ratings');
      await dio.patch('/v7/ratings/3');
      await dio.delete('/v7/ratings/3');

      for (var i = 0; i < capture.requests.length; i++) {
        expect(capture.hasBearer(i), isTrue, reason: capture.requests[i].path);
      }
    },
  );

  test('공개 경로(로그인·유저별 평점 조회·중복 확인·v6)에는 붙이지 않는다', () async {
    await dio.post('/v7/auth/login');
    await dio.get('/v7/members/7/ratings');
    await dio.get('/v7/members/nickname/abc');
    await dio.get('/v7/ratingsX');
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
    await dio.get('https://api.themoviedb.org/v7/ratings');
    await dio.get('https://image.tmdb.org/t/p/w500/a.jpg');
    await dio.get('https://evil.example/v7/members/me');

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
      '/v7/members/7/ratings',
      options: Options(headers: {'Authorization': 'Bearer leftover'}),
    );

    expect(capture.hasNoAuthorization(0), isTrue);
  });

  test('저장된 토큰이 없으면 보호 경로에도 Authorization을 붙이지 않는다', () async {
    storage.token = null;

    await dio.get('/v7/members/me');

    expect(capture.hasNoAuthorization(0), isTrue);
  });

  test('저장소를 읽지 못하면 서버 401과 구분되는 오류로 요청을 막는다', () async {
    storage.readError = StateError('keychain');

    await expectLater(
      dio.get('/v7/members/me'),
      throwsA(
        isA<DioException>()
            .having((e) => e.response, 'response', isNull)
            .having((e) => e.error, 'error', isA<StateError>()),
      ),
    );
    expect(capture.requests, isEmpty);
  });

  test('isProtected는 workbook host의 보호 경로만 true다', () {
    bool check(String url) => AuthInterceptor.isProtected(Uri.parse(url));

    expect(check('https://workbook.devnoco.com/v7/ratings/12'), isTrue);
    expect(check('https://workbook.devnoco.com/v7/members/me'), isTrue);
    expect(check('https://workbook.devnoco.com/v7/members/me/x'), isFalse);
    expect(check('https://workbook.devnoco.com/v7/auth/login'), isFalse);
  });
}
