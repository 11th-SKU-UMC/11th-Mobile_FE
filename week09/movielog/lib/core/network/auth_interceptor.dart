import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// 보호 요청에만 `Authorization: Bearer {MovieLog JWT}`를 붙인다.
///
/// - 대상: workbook.devnoco.com의 `/v8/members/me`, `/v8/ratings`, `/v8/ratings/*`,
///   `/v8/favorites`(GET·POST), `/v8/favorites/{movieId}`(GET·DELETE)
/// - 그 외(공개 평점 조회, 로그인, 회원가입, 중복 확인, TMDB, 외부 이미지)에는 붙이지 않는다.
/// - `/v8/movie-records`는 Challenge 전용이라 이번 구현에서는 보호 경로에 넣지 않는다.
/// - 토큰·헤더 값을 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const String protectedHost = 'workbook.devnoco.com';

  static final RegExp _favoriteByMovieId = RegExp(r'^/v8/favorites/[1-9]\d*$');

  final TokenStorage _storage;

  /// 보호 요청(JWT를 붙일 요청)인지 판단한다. [method]는 즐겨찾기 경로 판정에만 쓴다.
  static bool isProtected(Uri uri, [String method = 'GET']) {
    // MovieLog 서버가 아닌 곳(TMDB 등)에는 JWT를 붙이지 않는다.
    if (uri.host != protectedHost) return false;
    final path = uri.path;
    final verb = method.toUpperCase();

    // 8주차의 /v7 보호 경로를 /v8로 옮긴 것. 로그인·회원가입·중복 확인은 공개 요청이다.
    final w8Protected =
        path == '/v8/members/me' ||
        path == '/v8/ratings' ||
        path.startsWith('/v8/ratings/');

    // 9주차 즐겨찾기: 등록(POST)·목록(GET) / 여부 조회(GET)·해제(DELETE)
    final favorites =
        (path == '/v8/favorites' && (verb == 'GET' || verb == 'POST')) ||
        (_favoriteByMovieId.hasMatch(path) &&
            (verb == 'GET' || verb == 'DELETE'));

    return w8Protected || favorites;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 이전 요청의 토큰이 남아 다른 경로로 새지 않도록 먼저 지운다.
    options.headers.remove('Authorization');
    if (!isProtected(options.uri, options.method)) {
      handler.next(options);
      return;
    }
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
