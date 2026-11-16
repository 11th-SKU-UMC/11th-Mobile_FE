import 'package:dio/dio.dart';

/// 워크북 자체 백엔드(/v5)용 Dio Client.
/// TMDB Client(createTmdbClient)와 baseUrl·헤더가 다르므로 절대 합치지 않습니다.
Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
