import 'package:dio/dio.dart';

enum LoadStatus { idle, loading, success, empty, error }

/// 내부 Exception을 그대로 보여주지 않고 사용자 안내 문구로 바꿉니다.
String tmdbErrorMessage(DioException error, String fallback) {
  if (error.response?.statusCode == 401) {
    return 'TMDB 인증에 실패했어요. .env의 TMDB_ACCESS_TOKEN을 확인해 주세요.';
  }
  return fallback;
}
