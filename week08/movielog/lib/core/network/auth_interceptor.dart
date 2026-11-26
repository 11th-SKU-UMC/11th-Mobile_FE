import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// 보호 요청에만 `Authorization: Bearer {MovieLog JWT}`를 붙인다.
///
/// - 대상: workbook.devnoco.com의 `/v7/members/me`, `/v7/ratings`, `/v7/ratings/*`
/// - 그 외(공개 평점 조회, 로그인, TMDB, 외부 이미지)에는 붙이지 않는다.
/// - 토큰·헤더 값을 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const String protectedHost = 'workbook.devnoco.com';

  final TokenStorage _storage;

  static bool isProtected(Uri uri) {
    final path = uri.path;
    return uri.host == protectedHost &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 이전 요청의 토큰이 남아 다른 경로로 새지 않도록 먼저 지운다.
    options.headers.remove('Authorization');
    if (!isProtected(options.uri)) {
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
