import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/genre_filter_chips.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:provider/provider.dart';

TmdbMovieDto _movie(int id) => TmdbMovieDto(
  id: id,
  title: '영화 $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: '2024-01-01',
  genreIds: const [28],
  voteAverage: 7,
  popularity: 1,
);

TmdbMoviePageDto _page(int page, List<int> ids, {int totalPages = 100}) =>
    TmdbMoviePageDto(
      page: page,
      results: [for (final id in ids) _movie(id)],
      totalPages: totalPages,
      totalResults: totalPages * ids.length,
    );

/// 네트워크 없이 정해둔 응답을 돌려주는 Service. 받은 요청을 기록한다.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService() : super(Dio());

  Future<TmdbMoviePageDto> Function(int page)? popular;
  Future<TmdbMoviePageDto> Function(int page, int? genreId)? discover;
  Future<List<TmdbGenreDto>> Function()? genres;

  final List<(int, int?)> discoverCalls = [];

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) => popular!(page);

  @override
  Future<TmdbMoviePageDto> discoverMovies({required int page, int? genreId}) {
    discoverCalls.add((page, genreId));
    return discover!(page, genreId);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() =>
      genres?.call() ?? Future.value(const [TmdbGenreDto(id: 28, name: '액션')]);
}

DioException _networkError() => DioException(
  requestOptions: RequestOptions(path: '/discover/movie'),
  type: DioExceptionType.connectionError,
);

void main() {
  group('MovieHomeViewModel', () {
    test('Popular 결과에서 앞의 5개만 보관한다', () async {
      final service = _FakeTmdbMovieService()
        ..popular = (page) async => _page(page, List.generate(20, (i) => i));
      final viewModel = MovieHomeViewModel(service);

      await viewModel.loadPopular();

      expect(viewModel.status, MovieHomeLoadStatus.success);
      expect(viewModel.popularMovies.map((m) => m.id), [0, 1, 2, 3, 4]);
    });

    test('5개보다 적어도 범위 오류 없이 있는 만큼 보여준다', () async {
      final service = _FakeTmdbMovieService()
        ..popular = (page) async => _page(page, [1, 2]);
      final viewModel = MovieHomeViewModel(service);

      await viewModel.loadPopular();

      expect(viewModel.popularMovies.length, 2);
    });

    test('DioException이 아닌 변환 오류도 Error 상태가 된다', () async {
      final service = _FakeTmdbMovieService()
        ..popular = (page) async => TmdbMoviePageDto.fromJson({'page': '1'});
      final viewModel = MovieHomeViewModel(service);

      await viewModel.loadPopular();

      expect(viewModel.status, MovieHomeLoadStatus.error);
      expect(viewModel.message, isNotNull);
    });
  });

  group('MovieListViewModel', () {
    test('여러 페이지에서 id 중복을 제거하며 최대 30개를 모은다', () async {
      // 한 페이지 20개, 2페이지는 1페이지와 5개가 겹친다.
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) async =>
            _page(page, List.generate(20, (i) => (page - 1) * 15 + i));
      final viewModel = MovieListViewModel(service);

      await viewModel.loadInitial();

      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.movies.length, 30);
      expect(viewModel.movies.map((m) => m.id).toSet().length, 30);
      expect(service.discoverCalls, [(1, null), (2, null)]);
      expect(viewModel.genres.single.name, '액션');
    });

    test('마지막 페이지에 도달하면 30개보다 적어도 성공으로 끝난다', () async {
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) async =>
            _page(page, [page * 10, page * 10 + 1], totalPages: 2);
      final viewModel = MovieListViewModel(service);

      await viewModel.loadInitial();

      expect(viewModel.movies.length, 4);
      expect(service.discoverCalls.length, 2);
    });

    test('결과가 없으면 Empty, 네트워크 오류면 Error 상태가 된다', () async {
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) async => _page(page, [], totalPages: 0);
      final viewModel = MovieListViewModel(service);

      await viewModel.loadInitial();
      expect(viewModel.status, MovieListLoadStatus.empty);

      service.discover = (page, genreId) async => throw _networkError();
      await viewModel.selectGenre(28);
      expect(viewModel.status, MovieListLoadStatus.error);
    });

    test('장르를 고르면 with_genres로 page 1부터 다시 요청한다', () async {
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) async =>
            _page(page, [genreId ?? 0], totalPages: 1);
      final viewModel = MovieListViewModel(service);
      await viewModel.loadInitial();

      await viewModel.selectGenre(28);
      expect(viewModel.selectedGenreId, 28);
      expect(service.discoverCalls.last, (1, 28));
      expect(viewModel.movies.single.id, 28);

      await viewModel.selectGenre(null);
      expect(service.discoverCalls.last, (1, null));
    });

    test('요청 중에는 장르를 바꾸지 않는다', () async {
      final pending = Completer<TmdbMoviePageDto>();
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) => pending.future;
      final viewModel = MovieListViewModel(service);

      final loading = viewModel.loadInitial();
      await Future<void>.delayed(Duration.zero);
      await viewModel.selectGenre(28);

      expect(viewModel.selectedGenreId, isNull);
      pending.complete(_page(1, [1], totalPages: 1));
      await loading;
      expect(viewModel.status, MovieListLoadStatus.success);
    });

    test('dispose 이후 도착한 응답은 무시한다', () async {
      final pending = Completer<TmdbMoviePageDto>();
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) => pending.future;
      final viewModel = MovieListViewModel(service);

      final loading = viewModel.loadInitial();
      viewModel.dispose();
      pending.complete(_page(1, [1], totalPages: 1));

      // dispose 후 notifyListeners를 부르면 예외가 나므로, 끝까지 예외 없이 끝나야 한다.
      await loading;
      expect(viewModel.movies, isEmpty);
    });
  });

  group('MovieListScreen', () {
    testWidgets('Loading 중에는 장르 칩이 비활성화되고, 실패하면 재시도할 수 있다', (tester) async {
      final pending = Completer<TmdbMoviePageDto>();
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) => pending.future;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider(
            create: (_) => MovieListViewModel(service)..loadInitial(),
            child: const MovieListScreen(),
          ),
        ),
      );
      await tester.pump();

      final chips = tester.widget<GenreFilterChips>(
        find.byType(GenreFilterChips),
      );
      expect(chips.enabled, isFalse);

      pending.completeError(_networkError());
      await tester.pump();
      expect(find.byType(MovieListError), findsOneWidget);

      service.discover = (page, genreId) async =>
          _page(page, [1], totalPages: 1);
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump();

      expect(find.text('영화 1'), findsOneWidget);
      expect(
        tester.widget<GenreFilterChips>(find.byType(GenreFilterChips)).enabled,
        isTrue,
      );
    });
  });
}
