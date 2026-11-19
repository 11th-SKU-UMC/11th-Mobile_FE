import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_token_storage.dart';

const String _baseUrl = 'https://workbook.devnoco.com';

Dio createPublicMovieLogClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': 'application/json',
      },
    ),
  );

  _addLogInterceptor(dio);

  return dio;
}

Dio createAuthMovieLogClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken =
            await SecureTokenStorage.readAccessToken();

        if (accessToken != null &&
            accessToken.isNotEmpty) {
          options.headers['Authorization'] =
              'Bearer $accessToken';
        }

        handler.next(options);
      },
    ),
  );

  _addLogInterceptor(dio);

  return dio;
}

void _addLogInterceptor(Dio dio) {
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: true,
      ),
    );
  }
}