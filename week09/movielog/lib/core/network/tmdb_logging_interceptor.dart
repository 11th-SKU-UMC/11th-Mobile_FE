import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[TMDB 요청] ${options.method} ${options.uri.path}');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[TMDB 응답] ${response.requestOptions.uri.path} ${response.statusCode}',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[TMDB 오류] ${err.requestOptions.uri.path} ${err.response?.statusCode ?? err.type.name}',
    );

    handler.next(err);
  }
}
