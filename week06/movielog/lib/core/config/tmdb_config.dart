import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env`에서 TMDB 설정값을 읽는 곳.
///
/// 키 문자열을 여러 파일에서 반복하지 않도록 한곳에 모은다.
/// `main()`에서 `dotenv.load()`가 끝난 뒤에 읽어야 한다.
abstract final class TmdbConfig {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
