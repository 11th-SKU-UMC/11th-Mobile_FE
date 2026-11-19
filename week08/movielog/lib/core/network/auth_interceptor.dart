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

  bool isProtected(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path;
    return uri.host == host &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
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
