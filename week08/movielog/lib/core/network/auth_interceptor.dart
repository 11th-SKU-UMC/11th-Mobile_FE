import 'package:dio/dio.dart';

import '../../data/services/api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._origin, this._credentials, this._onExpired);

  static const _versionKey = 'movielog.sessionVersion';
  final Uri _origin;
  final ({int version, String? token}) Function() _credentials;
  final Future<void> Function(int version) _onExpired;

  bool _isProtected(Uri uri) {
    if (uri.scheme != _origin.scheme ||
        uri.host != _origin.host ||
        uri.port != _origin.port) {
      return false;
    }
    return uri.path == '/v7/members/me' ||
        uri.path == '/v7/ratings' ||
        RegExp(r'^/v7/ratings/[0-9]+$').hasMatch(uri.path);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.remove('authorization');
    options.extra.remove(_versionKey);
    if (_isProtected(options.uri)) {
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
    if (version is int && _isProtected(options.uri) && isExpiredSession(err)) {
      await _onExpired(version);
    }
    handler.next(err);
  }
}
