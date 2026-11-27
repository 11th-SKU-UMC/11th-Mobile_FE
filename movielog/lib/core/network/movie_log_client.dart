import 'package:dio/dio.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_logging_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';

BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

// 공개 요청용 (6주차 코드 유지): 로그인, 회원가입, 중복 체크, 유저별 평점 조회 / Interceptor 없음
Dio createMovieLogClient() {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(MovieLogLoggingInterceptor()); // 토큰·비밀번호는 *** 처리
  return dio;
}

// 보호 요청용 (8주차 추가): 내 정보, 평점 등록/수정/삭제 / Interceptor 등록
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  // AuthInterceptor 뒤에 등록해야 Bearer가 붙은 것을 *** 로 확인할 수 있습니다.
  dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}
