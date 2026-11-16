import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/movie.dart';
import 'package:movielog/data/movie_sort.dart';
import 'package:movielog/services/movie_service.dart';

void main() {
  group('FakeMovieService', () {
    // 테스트가 느려지지 않도록 지연 시간을 0으로 줄인다.
    FakeMovieService service(MovieLoadMode mode) =>
        FakeMovieService(initialMode: mode, delay: Duration.zero, slowDelay: Duration.zero);

    test('기본 지연 시간은 Loading 화면이 보이도록 800ms 이상이다', () {
      expect(
        FakeMovieService.defaultDelay,
        greaterThanOrEqualTo(const Duration(milliseconds: 800)),
      );
      expect(FakeMovieService().delay, FakeMovieService.defaultDelay);
    });

    test('success 모드는 Mock 영화 전체를 돌려준다', () async {
      final result = await service(MovieLoadMode.success).fetchMovies();

      expect(result, movies);
    });

    test('empty 모드는 빈 목록으로 정상 완료된다', () async {
      final result = await service(MovieLoadMode.empty).fetchMovies();

      expect(result, isEmpty);
    });

    test('failure 모드는 MovieLoadException으로 완료되고 매번 실패한다', () async {
      final fake = service(MovieLoadMode.failure);

      await expectLater(fake.fetchMovies(), throwsA(isA<MovieLoadException>()));
      await expectLater(fake.fetchMovies(), throwsA(isA<MovieLoadException>()));
    });

    test('flaky 모드는 첫 요청만 실패하고 재시도부터 성공한다', () async {
      final fake = service(MovieLoadMode.flaky);

      await expectLater(fake.fetchMovies(), throwsA(isA<MovieLoadException>()));
      expect(await fake.fetchMovies(), movies);
      expect(await fake.fetchMovies(), movies);
    });

    test('모드를 다시 flaky로 바꾸면 다시 한 번 실패부터 시작한다', () async {
      final fake = service(MovieLoadMode.flaky);
      await expectLater(fake.fetchMovies(), throwsA(isA<MovieLoadException>()));
      await fake.fetchMovies();

      fake.mode = MovieLoadMode.flaky;

      await expectLater(fake.fetchMovies(), throwsA(isA<MovieLoadException>()));
    });

    test('slow 모드는 slowDelay만큼 기다린 뒤 영화를 돌려준다', () async {
      final fake = FakeMovieService(
        initialMode: MovieLoadMode.slow,
        delay: Duration.zero,
        slowDelay: const Duration(milliseconds: 50),
      );
      final stopwatch = Stopwatch()..start();

      final result = await fake.fetchMovies();

      expect(stopwatch.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 50)));
      expect(result, movies);
    });

    test('예외 메시지는 사용자에게 보여줄 수 있는 문장만 담는다', () async {
      try {
        await service(MovieLoadMode.failure).fetchMovies();
        fail('예외가 발생해야 한다');
      } on MovieLoadException catch (error) {
        expect(error.message, isNotEmpty);
        expect(error.message, isNot(contains('Exception')));
      }
    });
  });

  group('sortMovies', () {
    test('최신순은 연도 내림차순이고 같은 연도는 ID 순서다', () {
      final sorted = sortMovies(movies, MovieSort.latest);

      for (var i = 1; i < sorted.length; i++) {
        final prev = sorted[i - 1];
        final current = sorted[i];
        expect(prev.year, greaterThanOrEqualTo(current.year));
        if (prev.year == current.year) {
          expect(prev.id, lessThan(current.id));
        }
      }
    });

    test('평점순은 평균 평점 내림차순이다', () {
      final ratings = sortMovies(
        movies,
        MovieSort.rating,
      ).map((movie) => movie.averageRating).toList();

      expect(ratings, [...ratings]..sort((a, b) => b.compareTo(a)));
    });

    test('원본 목록은 바꾸지 않고 빈 목록도 처리한다', () {
      final before = [...movies];

      sortMovies(movies, MovieSort.title);

      expect(movies, before);
      expect(sortMovies(const [], MovieSort.rating), isEmpty);
    });

    test('저장된 이름이 없거나 잘못됐으면 최신순으로 되돌린다', () {
      expect(MovieSort.fromName('rating'), MovieSort.rating);
      expect(MovieSort.fromName(null), MovieSort.latest);
      expect(MovieSort.fromName('unknown'), MovieSort.latest);
    });
  });

  group('filterMoviesByGenres', () {
    test('넘겨준 목록 안에서만 거른다', () {
      final source = [movies.first];

      expect(filterMoviesByGenres(const ['SF'], from: source), isEmpty);
      expect(filterMoviesByGenres(const [], from: source), source);
    });
  });
}
