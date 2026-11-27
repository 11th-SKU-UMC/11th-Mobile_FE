import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드(MovieLog API) 전용 Dio Client.
///
/// TMDB Client와 baseUrl·헤더(인증)가 다르므로 절대 하나로 합치지 않는다.
/// 요청 body에 비밀번호가 들어가므로 body·헤더를 찍는 로그 Interceptor를 붙이지 않는다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

/// 공개 요청용: 로그인, 회원가입, 중복 확인, 유저별 평점 조회. Interceptor 없음.
Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

/// 보호 요청용: 내 정보, 평점 등록·수정·삭제. [AuthInterceptor]가 토큰을 붙인다.
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
