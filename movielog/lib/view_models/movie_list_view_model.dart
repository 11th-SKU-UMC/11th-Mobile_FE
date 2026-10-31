import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  static const maxMovies = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  int? selectedGenreId; // null = "전체"
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading => status == MovieListLoadStatus.loading;

  // 처음 진입 + 재시도 + 장르 변경 모두 이 함수로 page 1부터 다시 불러옴
  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      if (genres.isEmpty) {
        genres = await _service.fetchGenres();
      }
      final result = await _fetchUpToThirtyMovies(genreId: selectedGenreId);

      if (_isStale(version)) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_isStale(version)) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    notifyListeners();
  }

  // 장르 Chip 선택 (null = 전체)
  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return; // 요청 중에는 장르 변경 막기 (Required 7)
    if (genreId == selectedGenreId) return; // 같은 장르 다시 누르면 무시
    selectedGenreId = genreId;
    await loadInitial();
  }

  // Discover를 page 1부터 요청해서 id 기준 중복 없이 최대 30개 모으기
  Future<List<TmdbMovieDto>> _fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.toList();
  }

  // 화면이 사라졌거나, 더 최신 요청이 시작됐으면 이 응답은 버림
  bool _isStale(int version) => _disposed || version != _requestVersion;

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
