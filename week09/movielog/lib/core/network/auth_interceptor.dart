import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// MovieLog 보호 API에만 `Authorization: Bearer {accessToken}`을 붙입니다.
///
/// - 외부 이미지·TMDB 같은 다른 host에는 절대 붙이지 않습니다.
/// - 토큰이나 헤더를 로그로 남기지 않습니다.
/// - Interceptor는 BuildContext를 쓰지 않습니다. 401 처리는 ViewModel이 담당합니다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {this.host = 'workbook.devnoco.com'});

  final TokenStorage _storage;
  final String host;

  static final _favoriteByMovieId = RegExp(r'^/v8/favorites/[1-9]\d*$');

  /// 보호 요청(JWT를 붙일 요청)인지 판단합니다.
  /// 로그인·회원가입·중복 확인·유저별 평점 조회는 공개 요청이라 붙이지 않습니다.
  bool isProtected(RequestOptions options) {
    final uri = options.uri;
    // MovieLog 서버가 아닌 곳(TMDB 등)에는 JWT를 붙이지 않습니다.
    if (uri.host != host) return false;
    final path = uri.path;
    final method = options.method.toUpperCase();

    // 8주차의 /v7 보호 경로를 /v8로 옮겼습니다.
    final member = path == '/v8/members/me';
    final ratings = path == '/v8/ratings' || path.startsWith('/v8/ratings/');

    // 9주차 즐겨찾기: 등록(POST)·목록(GET) / 여부 조회(GET)·해제(DELETE)
    final favorites =
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (_favoriteByMovieId.hasMatch(path) &&
            (method == 'GET' || method == 'DELETE'));

    // Challenge: 평점·즐겨찾기 통합 저장
    final movieRecord = path == '/v8/movie-records' && method == 'POST';

    return member || ratings || favorites || movieRecord;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isProtected(options)) {
      handler.next(options);
      return;
    }
    options.headers.remove('Authorization'); // 이전 요청의 토큰을 재사용하지 않습니다.
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류이므로 code 없는 오류로 거절합니다.
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
