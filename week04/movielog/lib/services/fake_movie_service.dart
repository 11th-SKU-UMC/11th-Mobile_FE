import '../models/movie.dart';
import '../models/mock_movies.dart';

// 가짜 서버에게 시킬 시나리오
enum MovieLoadMode { success, empty, failure }

// 서버 오류를 표현하는 예외
class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService();

  //TODO (5주차 유저별 평점 조회 API): FakeMovieService를 실제 API Service로 교체
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    // 서버에서 받아오는 척 1초 기다리기
    await Future<void>.delayed(const Duration(seconds: 1));

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure =>
        throw const MovieLoadException('영화를 불러오지 못했습니다.'),
    };
  }
}