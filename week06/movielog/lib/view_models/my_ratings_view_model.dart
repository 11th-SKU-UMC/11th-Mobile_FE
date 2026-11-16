import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

/// 6주차 조회 대상. 로그인한 '내 계정'이 아니라 학습용 공개 데이터다.
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// '내가 등록한 평점' 화면의 상태.
///
/// - 빈 배열은 Empty, 평점 조회 실패만 Error로 구분한다.
/// - 각 평점의 movieId로 TMDB 영화 정보를 붙인다. 같은 movieId는 한 번만 조회하고 캐시한다.
/// - 영화 정보 조회가 실패해도 평점은 그대로 남기고, 영화만 placeholder로 표시한다.
/// - 화면 이탈이나 새 요청 이후 도착한 이전 응답은 [_requestVersion]으로 버린다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  static const String missingMoviesMessage =
      '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
  static const String unknownErrorMessage = '평점 정보를 읽지 못했습니다. 잠시 후 다시 시도해 주세요.';

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  /// movieId → 영화. TMDB에 없는 영화(404)는 null로 캐시한다.
  /// 일시적인 실패는 캐시하지 않아 다음 로딩에서 다시 시도한다.
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;

  /// Error면 실패 문구, Success면 일부 영화를 못 가져왔을 때의 안내 문구.
  String? message;

  bool _isStale(int version) => _disposed || version != _requestVersion;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_isStale(version)) return;

      await _fillMovieCache(rawRatings);
      if (_isStale(version)) return;

      final entries = [
        for (final rating in rawRatings)
          RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
      ];
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (entries.any((entry) => entry.movie == null)) {
        message = missingMoviesMessage;
      }
    } on DioException catch (error) {
      if (_isStale(version)) return;
      debugPrint('평점 조회 실패: ${error.type} ${error.response?.statusCode}');
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (error) {
      // 응답 파싱 실패 등 DioException 외 예외도 loading에 멈추지 않게 Error로 보낸다.
      if (_isStale(version)) return;
      debugPrint('평점 응답 처리 실패: $error');
      status = MyRatingsLoadStatus.error;
      message = unknownErrorMessage;
    }

    if (!_isStale(version)) notifyListeners();
  }

  /// 캐시에 없는 movieId만 TMDB에 묻는다. 실패한 영화는 캐시하지 않고 넘어간다.
  Future<void> _fillMovieCache(List<RatingDto> rawRatings) async {
    final missingIds = {
      for (final rating in rawRatings)
        if (!_movieCache.containsKey(rating.movieId)) rating.movieId,
    };

    await Future.wait(
      missingIds.map((movieId) async {
        try {
          _movieCache[movieId] = await _movieService.findMovieById(movieId);
        } catch (error) {
          // 영화 조회 실패가 평점 목록을 지우지 않도록 여기서 삼킨다.
          debugPrint('영화 $movieId 조회 실패: $error');
        }
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
