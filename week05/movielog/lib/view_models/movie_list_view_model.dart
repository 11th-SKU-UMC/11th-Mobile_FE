import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  static const int _maxCount = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// 선택된 장르 ID 목록. 비어 있으면 "전체"
  List<int> selectedGenreIds = const [];

  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// Pull to Refresh 진행 중 (이 동안 기존 목록은 화면에 그대로 유지)
  bool isRefreshing = false;

  /// 요청 실패 Dialog에 보여줄 문구. null이 아니면 화면이 Dialog를 띄운다.
  String? retryMessage;

  /// 마지막으로 "성공한" 목록의 장르 ID. Dialog에서 취소하면 이 값으로 되돌린다.
  List<int> _lastSuccessGenreIds = const [];

  int _requestVersion = 0; // 오래된 응답을 버리기 위한 번호
  bool _disposed = false;

  bool get isLoading => status == MovieListLoadStatus.loading;
  bool get isBusy => isLoading || isRefreshing;
  bool get hasRetryPrompt => retryMessage != null;

  /// 장르 ID 목록 -> with_genres 값. 비어 있으면 null (파라미터 자체를 보내지 않음)
  String? get _withGenres =>
      selectedGenreIds.isEmpty ? null : selectedGenreIds.join('|');

  /// 중복 없는 영화를 최대 30개 모은다. (page 1부터)
  Future<List<TmdbMovieDto>> _fetchUpToThirtyMovies({
    String? withGenres,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < _maxCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        withGenres: withGenres,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == _maxCount) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(_maxCount).toList();
  }

  bool _isStale(int version) => _disposed || version != _requestVersion;

  /// 첫 진입: 장르 목록 + 전체 영화
  Future<void> loadInitial() async {
    selectedGenreIds = const [];
    _lastSuccessGenreIds = const [];
    status = MovieListLoadStatus.loading;
    message = null;
    retryMessage = null;
    notifyListeners();

    try {
      genres = await _service.fetchGenres();
    } catch (_) {
      genres = const []; // 장르 조회 실패가 영화 목록까지 막지 않게 한다.
    }
    if (_disposed) return;

    await _load(showSpinner: true);
  }

  /// 현재 선택된 장르 그대로 page 1부터 다시 조회 (오류 화면의 "다시 시도")
  Future<void> reload() => _load(showSpinner: true);

  /// 장르 다중 선택 적용. 빈 목록이면 "전체"
  Future<void> applyGenres(List<int> genreIds) async {
    if (isBusy) return; // 요청 중에는 장르 변경 불가
    final next = [...genreIds]..sort();
    if (listEquals(next, selectedGenreIds)) return;

    selectedGenreIds = next;
    await _load(showSpinner: true);
  }

  /// Pull to Refresh: 기존 목록은 유지한 채 현재 장르 그대로 page 1부터 다시 조회
  Future<void> refresh() async {
    if (isBusy) return; // 로딩 중에는 새로고침 불가
    await _load(showSpinner: false);
  }

  /// 실패 Dialog의 "재시도": 마지막으로 선택한 장르 ID 목록으로 30개 로딩 전체를 다시 실행
  Future<void> retry() => _load(showSpinner: true);

  /// 실패 Dialog의 "취소": 마지막으로 성공한 목록의 장르 선택으로 되돌린다.
  void cancelRetry() {
    retryMessage = null;
    selectedGenreIds = _lastSuccessGenreIds;
    notifyListeners();
  }

  /// showSpinner true: Loading 상태로 전환 (목록은 화면에서 숨김, 데이터는 보관)
  /// showSpinner false: 목록을 그대로 보여주며 백그라운드로 갱신 (Pull to Refresh)
  Future<void> _load({required bool showSpinner}) async {
    final version = ++_requestVersion;
    final requestedGenres = [...selectedGenreIds];

    if (showSpinner) {
      status = MovieListLoadStatus.loading;
    } else {
      isRefreshing = true;
    }
    message = null;
    retryMessage = null;
    notifyListeners();

    try {
      final result = await _fetchUpToThirtyMovies(withGenres: _withGenres);
      if (_isStale(version)) return;
      movies = result;
      _lastSuccessGenreIds = requestedGenres;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_isStale(version)) return;
      _applyFailure('영화를 불러오지 못했어요. 네트워크 상태를 확인해 주세요.');
    } catch (_) {
      if (_isStale(version)) return;
      _applyFailure('데이터를 처리하지 못했어요.');
    }

    isRefreshing = false;
    notifyListeners();
  }

  /// 최근에 성공한 목록이 있으면 비우지 않고 Dialog로 알린다. 없으면 오류 화면.
  void _applyFailure(String text) {
    if (movies.isNotEmpty) {
      status = MovieListLoadStatus.success;
      retryMessage = text;
    } else {
      status = MovieListLoadStatus.error;
      message = text;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
