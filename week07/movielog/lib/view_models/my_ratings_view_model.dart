import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/api_error.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, empty, error, success }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning;
  String? writeMessage;
  bool isWriting = false;
  bool isDeletingSelected = false;
  bool isEditing = false;
  final Set<int> _selectedRatingIds = {};
  Set<int> get selectedRatingIds => Set.unmodifiable(_selectedRatingIds);
  int get selectedCount => _selectedRatingIds.length;
  int _requestVersion = 0;
  bool _disposed = false;

  void toggleEditing() {
    if (_disposed || isWriting) return;
    isEditing = !isEditing;
    _selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelected(int ratingId) {
    if (_disposed ||
        isWriting ||
        !isEditing ||
        !ratings.any((entry) => entry.rating.ratingId == ratingId)) {
      return;
    }
    if (!_selectedRatingIds.add(ratingId)) _selectedRatingIds.remove(ratingId);
    notifyListeners();
  }

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;
      final entries = <RatingWithMovie>[];
      final moviesById = <int, TmdbMovieDto?>{};
      var missingMovies = 0;
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;
        if (!moviesById.containsKey(rating.movieId)) {
          TmdbMovieDto? movie;
          if (_movieCache.containsKey(rating.movieId)) {
            movie = _movieCache[rating.movieId];
          } else {
            try {
              movie = await _movieService.findMovieById(rating.movieId);
              if (_disposed || version != _requestVersion) return;
              _movieCache[rating.movieId] = movie;
            } catch (_) {
              if (_disposed || version != _requestVersion) return;
              // A transient TMDB failure must not hide the saved rating.
            }
          }
          moviesById[rating.movieId] = movie;
        }
        final movie = moviesById[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _requestVersion) return;
      ratings = entries;
      _selectedRatingIds.retainAll(rawRatings.map((rating) => rating.ratingId));
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      refreshWarning = null;
      if (missingMovies > 0) message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    } catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    await load(); // load records GET failures; it never turns a write into a failure.
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  Future<void> _write(Future<void> Function() action) async {
    if (_disposed || isWriting) throw const ApiException('이미 처리 중입니다.');
    isWriting = true;
    writeMessage = null;
    ++_requestVersion; // Ignore a GET started before this write.
    notifyListeners();
    try {
      try {
        await action();
      } catch (error) {
        if (!_disposed) {
          writeMessage = apiErrorMessage(error);
          if (shouldRefreshAfterRatingError(error)) await load();
        }
        rethrow;
      }
      if (!_disposed) await _refreshAfterWrite();
    } finally {
      if (!_disposed) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) => _write(
    () => _service.updateRating(
      memberId: memberId,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ),
  );

  Future<void> deleteRating(int ratingId) => _write(() async {
    await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    if (_disposed) return;
    ratings = ratings
        .where((entry) => entry.rating.ratingId != ratingId)
        .toList();
    _selectedRatingIds.remove(ratingId);
  });

  Future<void> deleteSelectedRatings() async {
    if (_disposed || isWriting || _selectedRatingIds.isEmpty) return;
    isWriting = true;
    isDeletingSelected = true;
    writeMessage = null;
    ++_requestVersion;
    notifyListeners();
    var failed = 0;
    try {
      // Remove from the Set while iterating over a separate snapshot.
      for (final ratingId in _selectedRatingIds.toList()) {
        if (_disposed) return;
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          if (_disposed) return;
          _selectedRatingIds.remove(ratingId);
          ratings = ratings
              .where((entry) => entry.rating.ratingId != ratingId)
              .toList();
        } catch (_) {
          if (_disposed) return;
          failed++;
        }
      }
      if (_disposed) return;
      await _refreshAfterWrite();
      if (_disposed) return;
      writeMessage = failed == 0
          ? '선택한 평점을 삭제했습니다.'
          : '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      if (_selectedRatingIds.isEmpty) isEditing = false;
    } finally {
      if (!_disposed) {
        isWriting = false;
        isDeletingSelected = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_requestVersion;
    super.dispose();
  }
}
