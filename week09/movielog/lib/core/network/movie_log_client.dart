import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드(회원·평점) 주소입니다.
/// TMDB Client와 baseUrl·헤더가 다르므로 절대 하나로 합치지 않습니다.
const movieLogHost = 'workbook.devnoco.com';

BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://$movieLogHost',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

/// 공개 요청용: 로그인, 회원가입, 중복 확인, 유저별 평점 조회. Interceptor가 없어 토큰이 붙지 않습니다.
Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

/// 보호 요청용: 내 정보, 평점 등록·수정·삭제, 즐겨찾기, 영화 기록. 보호 경로에만 Bearer 헤더를 붙입니다.
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
