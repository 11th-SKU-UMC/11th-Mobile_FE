import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const service = FakeMovieService(delay: Duration.zero);

  test('success 모드는 Mock 영화 목록을 반환한다', () async {
    expect(await service.fetchMovies(), movies);
  });

  test('empty 모드는 빈 목록을 반환한다', () async {
    expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
  });

  test('failure 모드는 MovieLoadException을 던진다', () {
    expect(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });
}
