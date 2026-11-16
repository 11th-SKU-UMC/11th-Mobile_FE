import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 실제 요청 헤더는 유지하고, 로그용 복사본만 마스킹합니다.
    final maskedHeaders = options.headers.map(
      (key, value) => MapEntry(
        key,
        key.toLowerCase() == 'authorization' ? 'Bearer ***' : value,
      ),
    );

    debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
    debugPrint('[TMDB 요청 Header] $maskedHeaders');
    debugPrint('[TMDB 요청 Query] ${options.queryParameters}');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[TMDB 응답] ${response.statusCode}');
    debugPrint('[TMDB 응답 Body] ${response.data}');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[TMDB 오류] ${err.requestOptions.uri}');
    debugPrint('[TMDB 오류 내용] ${err.message}');

    handler.next(err);
  }
}
