import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';

Dio createTmdbClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer ${TmdbConfig.accessToken}',
        'accept': 'application/json',
      },
    ),
  );

  // 로그는 개발 중 확인용이므로 debug 모드에서만 켠다.
  if (kDebugMode) {
    dio.interceptors.add(TmdbLoggingInterceptor());
  }

  return dio;
}