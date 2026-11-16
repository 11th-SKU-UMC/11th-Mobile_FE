import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 목록 화면의 상태.
///
/// - Genre API 결과로 장르 칩을 만들고, Discover API를 page 1부터 불러
///   TMDB id 기준으로 중복 없는 영화를 최대 [maxMovies]개 모은다.
/// - 장르를 고르면 로컬 필터가 아니라 `with_genres`로 다시 요청한다.
/// - 늦게 도착한 이전 요청의 응답은 [_requestVersion]으로 버린다.
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  static const int maxMovies = 30;

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// null이면 '전체'.
  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading => status == MovieListLoadStatus.loading;

  /// 응답이 버려야 하는 오래된 결과인지. (새 요청이 시작됐거나 화면이 사라짐)
  bool _isStale(int version) => _disposed || version != _requestVersion;

  /// 카드에 보여줄 대표 장르 이름. 장르 목록에 없는 id면 null.
  String? genreNameOf(TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      for (final genre in genres) {
        if (genre.id == id) return genre.name;
      }
    }
    return null;
  }

  /// 결과가 [maxMovies]개가 되거나 더 이상 페이지가 없을 때까지 Discover를 요청한다.
  /// 한 페이지 개수는 가정하지 않는다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        // 같은 id가 다음 페이지에 또 와도 Map key라서 하나만 남는다.
        byId[movie.id] = movie;
        if (byId.length == maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovies).toList();
  }

  /// 처음 진입할 때. 장르 목록과 영화 목록을 함께 불러온다.
  Future<void> loadInitial() async {
    final version = _startLoading();

    try {
      final loadedGenres = await _service.fetchGenres();
      final discovered = await fetchUpToThirtyMovies(genreId: selectedGenreId);
      if (_isStale(version)) return;

      genres = loadedGenres;
      _applyMovies(discovered);
    } catch (error, stackTrace) {
      if (_isStale(version)) return;
      _applyError(error, stackTrace, '영화를 불러오지 못했어요.');
    }

    notifyListeners();
  }

  /// 장르 칩을 눌렀을 때. 로딩 중에는 바꾸지 않는다.
  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return;
    if (genreId == selectedGenreId && status == MovieListLoadStatus.success) {
      return;
    }

    selectedGenreId = genreId;
    final version = _startLoading();

    try {
      final discovered = await fetchUpToThirtyMovies(genreId: genreId);
      if (_isStale(version)) return;
      _applyMovies(discovered);
    } catch (error, stackTrace) {
      if (_isStale(version)) return;
      _applyError(error, stackTrace, '해당 장르 영화를 불러오지 못했어요.');
    }

    notifyListeners();
  }

  /// 오류 화면의 '다시 시도'. 장르 목록부터 실패했다면 처음부터 다시 불러온다.
  Future<void> retry() {
    if (genres.isEmpty) return loadInitial();
    return selectGenre(selectedGenreId);
  }

  int _startLoading() {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();
    return version;
  }

  void _applyMovies(List<TmdbMovieDto> result) {
    movies = result;
    status = result.isEmpty
        ? MovieListLoadStatus.empty
        : MovieListLoadStatus.success;
  }

  /// 네트워크 오류(DioException)뿐 아니라 DTO 변환 실패 같은 다른 예외도 Error 상태로 보낸다.
  void _applyError(Object error, StackTrace stackTrace, String networkMessage) {
    if (error is DioException) {
      debugPrint('영화 목록 로드 실패: ${error.type} ${error.response?.statusCode}');
      message = '$networkMessage\n잠시 후 다시 시도해주세요.';
    } else {
      debugPrint('영화 목록 변환 실패: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
      message = '영화 정보를 읽지 못했어요.\n잠시 후 다시 시도해주세요.';
    }
    status = MovieListLoadStatus.error;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
