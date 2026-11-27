import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 영화 목록(Discover)과 검색(Search)의 page 단위 상태. 화면마다 별도 인스턴스를 쓴다.
///
/// - [loadInitial]: 조건(장르·검색어)을 바꾸고 page 1부터 다시 불러온다.
/// - [loadNextPage]: "더 보기". 성공했을 때만 [nextPage]를 올리므로 실패하면 같은 page를 재시도한다.
/// - 조건이 바뀌면 [_requestGeneration]을 올려 이전 조건의 늦은 응답·오류를 버린다.
/// - TMDB는 page가 달라도 같은 영화를 다시 줄 수 있어 movieId로 중복을 제거한다.
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi});

  /// TMDB가 허용하는 최대 page. total_pages가 더 커도 501은 요청하지 않는다.
  static const int maxTmdbPage = 500;

  static const String listFailedMessage = '영화 목록을 불러오지 못했습니다.';
  static const String searchFailedMessage = '검색 결과를 불러오지 못했습니다.';
  static const String nextPageFailedMessage =
      '다음 페이지를 불러오지 못했습니다. 같은 페이지를 다시 요청합니다.';

  final TmdbMovieService tmdbApi;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> movies = [];

  /// 다음에 요청할 page. 실패하면 그대로 둔다.
  int nextPage = 1;

  /// 서버 total_pages와 [maxTmdbPage] 중 작은 값.
  int totalPages = 1;
  bool isLoadingMore = false;
  String? errorMessage;
  String? loadMoreError;

  bool get hasMore => nextPage <= totalPages;

  int _requestGeneration = 0;
  ({int? genreId, String query}) _condition = (genreId: null, query: '');

  int? get genreId => _condition.genreId;
  String get query => _condition.query;

  /// 영화 목록 화면의 장르 칩. 검색 화면에서는 쓰지 않는다.
  List<TmdbGenreDto> genres = const [];

  /// 장르 칩을 불러온다. 실패해도 목록은 '전체' 칩만으로 계속 쓸 수 있다.
  Future<void> loadGenres() async {
    try {
      final loaded = await tmdbApi.fetchGenres();
      if (isDisposed) return;
      genres = loaded;
      notifyIfAlive();
    } catch (error) {
      _log('장르 목록 조회 실패', error);
    }
  }

  /// 카드에 보여줄 대표 장르 이름. 장르 목록에 없는 id면 null.
  String? genreNameOf(TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      for (final genre in genres) {
        if (genre.id == id) return genre.name;
      }
    }
    return null;
  }

  /// 조건을 바꾸고 목록·page·추가 로딩 상태를 모두 초기화한 뒤 첫 page를 요청한다.
  /// [query]가 비어 있지 않으면 Search, 비어 있으면 Discover를 부른다.
  Future<void> loadInitial({int? genreId, String query = ''}) async {
    if (isDisposed) return;
    final condition = (genreId: genreId, query: query.trim());
    _condition = condition;
    final generation = ++_requestGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;
    movies.clear();
    nextPage = 1;
    totalPages = 1;
    notifyIfAlive();
    try {
      final page = await _fetchPage(1, condition);
      if (generation != _requestGeneration || isDisposed) return;
      _applyFirstPage(page);
    } catch (error) {
      if (generation != _requestGeneration || isDisposed) return;
      _log('첫 page 조회 실패', error);
      phase = LoadPhase.error;
      errorMessage = condition.query.isEmpty
          ? listFailedMessage
          : searchFailedMessage;
    } finally {
      if (generation == _requestGeneration && !isDisposed) notifyIfAlive();
    }
  }

  /// 현재 조건 그대로 첫 page부터 다시 불러온다. (첫 조회 오류의 '다시 시도')
  Future<void> retryInitial() =>
      loadInitial(genreId: _condition.genreId, query: _condition.query);

  /// "더 보기" / "다음 페이지 다시 시도". 실패해도 [nextPage]를 올리지 않는다.
  Future<void> loadNextPage() async {
    if (isDisposed || isLoadingMore || !hasMore || phase != LoadPhase.ready) {
      return;
    }
    final generation = _requestGeneration;
    final condition = _condition;
    final pageToLoad = nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(pageToLoad, condition);
      if (generation != _requestGeneration || isDisposed) return;
      _appendPage(page);
    } catch (error) {
      if (generation != _requestGeneration || isDisposed) return;
      _log('다음 page($pageToLoad) 조회 실패', error);
      loadMoreError = nextPageFailedMessage;
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(
    int page,
    ({int? genreId, String query}) condition,
  ) async {
    final result = condition.query.isNotEmpty
        ? await tmdbApi.searchMovies(page: page, query: condition.query)
        : await tmdbApi.discoverMovies(page: page, genreId: condition.genreId);
    if (result.page != page || result.totalPages < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _applyFirstPage(TmdbMoviePageDto page) {
    movies
      ..clear()
      ..addAll(_dedupe(page.results));
    _updatePaging(page);
    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  void _appendPage(TmdbMoviePageDto page) {
    movies.addAll(_dedupe(page.results));
    _updatePaging(page);
  }

  void _updatePaging(TmdbMoviePageDto page) {
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    nextPage = page.page + 1;
  }

  /// 이미 가진 movieId와 같은 page 안의 중복을 함께 제외한다.
  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = movies.map((movie) => movie.id).toSet();
    return incoming.where((movie) => seen.add(movie.id)).toList();
  }

  /// 검색어·토큰 같은 요청 값은 남기지 않고 오류 종류만 기록한다.
  void _log(String label, Object error) {
    if (error is DioException) {
      debugPrint('$label: ${error.type} ${error.response?.statusCode}');
    } else {
      debugPrint('$label: ${error.runtimeType}');
    }
  }
}
