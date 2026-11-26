import 'package:dio/dio.dart';

import '../../data/services/api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._origin, this._credentials, this._onExpired);

  static const _versionKey = 'movielog.sessionVersion';
  final Uri _origin;
  final ({int version, String? token}) Function() _credentials;
  final Future<void> Function(int version) _onExpired;

  bool _isProtected(RequestOptions options) {
    final uri = options.uri;
    if (uri.scheme != _origin.scheme ||
        uri.host != _origin.host ||
        uri.port != _origin.port) {
      return false;
    }
    final method = options.method.toUpperCase();
    final path = uri.path;
    return path == '/v8/members/me' ||
        path == '/v8/ratings' ||
        RegExp(r'^/v8/ratings/[0-9]+$').hasMatch(path) ||
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (RegExp(r'^/v8/favorites/[1-9][0-9]*$').hasMatch(path) &&
            (method == 'GET' || method == 'DELETE')) ||
        (path == '/v8/movie-records' && method == 'POST');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.remove('authorization');
    options.extra.remove(_versionKey);
    if (_isProtected(options)) {
      final session = _credentials();
      if (session.token == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: const ApiException('로그인이 필요합니다.'),
          ),
        );
        return;
      }
      options.headers['Authorization'] = 'Bearer ${session.token}';
      options.extra[_versionKey] = session.version;
      options.followRedirects = false;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final version = options.extra[_versionKey];
    if (version is int && _isProtected(options) && isExpiredSession(err)) {
      await _onExpired(version);
    }
    handler.next(err);
  }
}
