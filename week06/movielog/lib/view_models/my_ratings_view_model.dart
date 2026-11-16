import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

const int sampleMemberId = 1; // 인증된 ‘내 계정’이 아닌 학습용 데이터입니다.

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  // 같은 movieId는 한 번만 조회하고 캐시합니다. (null = TMDB에 없는 영화)
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      // 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;

        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] =
                await _movieService.findMovieById(rating.movieId);
          } catch (_) {
            // 일시적 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }

        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }

      if (_disposed || version != _requestVersion) return;

      ratings = entries;
      // 빈 배열은 실패가 아니라 Empty 상태입니다.
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      // 응답 형식이 예상과 다른 경우에도 loading 상태에 머물지 않게 합니다.
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
