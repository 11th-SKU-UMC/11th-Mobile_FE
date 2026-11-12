import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class TmdbConfig {
  static String get accessToken {
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('TMDB_ACCESS_TOKEN') ?? '';
  }

  static bool get hasAccessToken => accessToken.trim().isNotEmpty;
}
