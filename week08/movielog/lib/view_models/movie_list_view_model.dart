import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/genre_preference.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_status.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, this._preference);

  static const maxMovies = 30;

  final TmdbMovieService _service;
  final GenrePreference _preference;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// 비어 있으면 "전체"입니다.
  List<int> selectedGenreIds = const [];
  LoadStatus status = LoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading => status == LoadStatus.loading;

  /// 요청 중에는 장르를 바꾸지 못하게 합니다.
  bool get canChangeGenre => !isLoading;

  Future<List<TmdbMovieDto>> _fetchUpToThirtyMovies() async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: selectedGenreIds,
      );

      for (final movie in page.results) {
        // TMDB id를 key로 사용해 페이지 사이 중복을 제거합니다.
        byId[movie.id] = movie;
        if (byId.length == maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovies).toList();
  }

  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    status = LoadStatus.loading;
    message = null;
    notifyListeners();

    selectedGenreIds = await _readSavedGenres();

    try {
      genres = await _service.fetchGenres();

      // 저장된 장르가 더 이상 존재하지 않으면 무시합니다.
      final validIds = genres.map((genre) => genre.id).toSet();
      selectedGenreIds = selectedGenreIds
          .where(validIds.contains)
          .toList(growable: false);

      final discovered = await _fetchUpToThirtyMovies();
      if (_isStale(version)) return;
      _applyMovies(discovered);
    } on DioException catch (error) {
      if (_isStale(version)) return;
      status = LoadStatus.error;
      message = tmdbErrorMessage(error, '영화를 불러오지 못했어요. 다시 시도해 주세요.');
    }

    if (!_isStale(version)) notifyListeners();
  }

  /// 장르 Chip·BottomSheet에서 호출합니다. 선택이 바뀌면 page 1부터 다시 요청합니다.
  Future<void> selectGenres(List<int> genreIds) async {
    if (!canChangeGenre) return;
    if (listEquals(genreIds, selectedGenreIds) &&
        status == LoadStatus.success) {
      return;
    }

    selectedGenreIds = List.unmodifiable(genreIds);
    try {
      await _preference.save(selectedGenreIds);
    } catch (error) {
      // 로컬 저장 실패는 목록 조회를 막지 않습니다.
      debugPrint('장르 저장 실패: $error');
    }
    await reload();
  }

  Future<List<int>> _readSavedGenres() async {
    try {
      return await _preference.read();
    } catch (error) {
      debugPrint('저장된 장르 읽기 실패: $error');
      return const [];
    }
  }

  /// 현재 장르 조건으로 목록을 처음부터 다시 불러옵니다(재시도).
  Future<void> reload() async {
    if (genres.isEmpty) return loadInitial();

    final version = ++_requestVersion;
    status = LoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await _fetchUpToThirtyMovies();
      if (_isStale(version)) return;
      _applyMovies(result);
    } on DioException catch (error) {
      if (_isStale(version)) return;
      status = LoadStatus.error;
      message = tmdbErrorMessage(error, '해당 장르 영화를 불러오지 못했어요.');
    }

    if (!_isStale(version)) notifyListeners();
  }

  /// Pull to Refresh: 기존 목록을 지우지 않고 유지한 채 다시 요청합니다.
  /// 실패하면 false를 반환하고, 화면은 최근 목록을 유지한 채 재시도 Dialog를 띄웁니다.
  Future<bool> refresh() async {
    if (isLoading) return true;
    final version = ++_requestVersion;

    try {
      final result = await _fetchUpToThirtyMovies();
      if (_isStale(version)) return true;
      _applyMovies(result);
      notifyListeners();
      return true;
    } on DioException {
      return false;
    }
  }

  void _applyMovies(List<TmdbMovieDto> result) {
    movies = result;
    status = result.isEmpty ? LoadStatus.empty : LoadStatus.success;
  }

  bool _isStale(int version) => _disposed || version != _requestVersion;

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
