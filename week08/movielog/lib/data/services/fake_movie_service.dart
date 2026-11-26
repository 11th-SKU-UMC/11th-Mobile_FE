import '../../models/movie.dart';

enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

/// 4주차 Mock Service입니다. 5주차에 같은 호출 경계를 TmdbMovieService로 교체했고,
/// 지금은 네트워크 없이 Loading·Empty·Error·Success 흐름을 테스트할 때 사용합니다.
class FakeMovieService {
  const FakeMovieService({this.delay = const Duration(seconds: 1)});

  final Duration delay;

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
    String genre = '전체',
  }) async {
    await Future<void>.delayed(delay);

    return switch (mode) {
      MovieLoadMode.success =>
        genre == '전체'
            ? mockMovies
            : mockMovies.where((movie) => movie.genre == genre).toList(),
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
