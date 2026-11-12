import 'package:dio/dio.dart';

/// 워크북 자체 백엔드(회원·평점)용 Client입니다.
/// TMDB Client와 baseUrl·헤더가 다르므로 절대 하나로 합치지 않습니다.
Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
