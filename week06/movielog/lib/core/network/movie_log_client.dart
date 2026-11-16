import 'package:dio/dio.dart';

/// 워크북 자체 백엔드(MovieLog API) 전용 Dio Client.
///
/// TMDB Client와 baseUrl·헤더(인증)가 다르므로 절대 하나로 합치지 않는다.
/// MemberCheckService와 RatingApiService가 이 인스턴스 하나를 공유한다.
Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
