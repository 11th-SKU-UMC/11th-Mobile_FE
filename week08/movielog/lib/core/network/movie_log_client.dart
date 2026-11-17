import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드용 Dio Client 공통 설정입니다.
/// TMDB Client(createTmdbClient)와 baseUrl·헤더가 다르므로 절대 합치지 않습니다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

/// 공개 요청용: 로그인, 중복 체크, 유저별 평점 조회 / Interceptor 없음
Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

/// 보호 요청용(8주차 추가): 내 정보, 평점 등록/수정/삭제 / AuthInterceptor 등록
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
