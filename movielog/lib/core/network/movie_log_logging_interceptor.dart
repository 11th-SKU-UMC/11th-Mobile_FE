import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// 워크북 서버 요청 로그. 토큰·비밀번호 원문은 절대 찍지 않습니다.
class MovieLogLoggingInterceptor extends Interceptor {
  static const _secretKeys = {'password', 'accessToken'};

  Object? _mask(Object? data) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          entry.key: _secretKeys.contains(entry.key)
              ? '***'
              : _mask(entry.value),
      };
    }
    if (data is List) return data.map(_mask).toList();
    return data;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }
    debugPrint('[MovieLog 요청] ${options.method} ${options.uri.path}');
    if (headers.containsKey('Authorization')) {
      debugPrint('[MovieLog 요청 Header] Authorization: ${headers['Authorization']}');
    }
    if (options.data != null) {
      debugPrint('[MovieLog 요청 Body] ${_mask(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[MovieLog 응답] ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    debugPrint('[MovieLog 응답 Body] ${_mask(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[MovieLog 오류] ${err.response?.statusCode} ${err.requestOptions.uri.path}',
    );
    debugPrint('[MovieLog 오류 Body] ${_mask(err.response?.data)}');
    handler.next(err);
  }
}
