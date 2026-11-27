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
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/genre_filter_chips.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';
import 'package:movielog/widgets/movie_page_footer.dart';
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

  group('MovieListScreen', () {
    Future<void> pumpList(WidgetTester tester, _FakeTmdbMovieService service) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 2000);
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider(
            create: (_) => PagedMoviesViewModel(tmdbApi: service)
              ..loadGenres()
              ..loadInitial(),
            child: const MovieListScreen(),
          ),
        ),
      );
    }

    testWidgets('첫 page 실패는 오류 화면에서 재시도하고, 성공하면 첫 page와 더 보기를 보여준다', (
      tester,
    ) async {
      final pending = Completer<TmdbMoviePageDto>();
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) => pending.future;

      await pumpList(tester, service);
      await tester.pump();
      expect(find.byType(MovieListLoading), findsOneWidget);

      pending.completeError(_networkError());
      await tester.pump();
      expect(find.byType(MovieListError), findsOneWidget);

      service.discover = (page, genreId) async =>
          _page(page, [page * 10 + 1, page * 10 + 2], totalPages: 2);
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump();

      // 5주차처럼 30개를 모으지 않고 첫 page만 요청한다.
      expect(service.discoverCalls, [(1, null), (1, null)]);
      expect(find.text('영화 11'), findsOneWidget);
      expect(find.text(MoviePageFooter.loadMoreLabel), findsOneWidget);

      await tester.tap(find.text(MoviePageFooter.loadMoreLabel));
      await tester.pump();
      await tester.pump();

      expect(service.discoverCalls.last, (2, null));
      expect(find.text('영화 21'), findsOneWidget);
      expect(find.text(MoviePageFooter.endMessage), findsOneWidget);
    });

    testWidgets('로딩 중에도 장르를 바꿀 수 있고, 이전 장르의 늦은 응답은 섞이지 않는다', (tester) async {
      final slowAll = Completer<TmdbMoviePageDto>();
      final service = _FakeTmdbMovieService()
        ..discover = (page, genreId) => genreId == null
            ? slowAll.future
            : Future.value(_page(page, [28], totalPages: 1));

      await pumpList(tester, service);
      await tester.pump();

      expect(
        tester.widget<GenreFilterChips>(find.byType(GenreFilterChips)).enabled,
        isTrue,
      );
      await tester.tap(find.text('액션'));
      await tester.pump();
      await tester.pump();
      expect(find.text('영화 28'), findsOneWidget);

      slowAll.complete(_page(1, [1], totalPages: 1));
      await tester.pump();

      expect(find.text('영화 1'), findsNothing);
      expect(find.text('영화 28'), findsOneWidget);
    });
  });
}
