import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, success, empty, error }

/// 홈 화면의 상태. Popular 첫 페이지에서 앞의 5개만 보관한다.
class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  /// 홈 인기 영역에 보여줄 개수. 화면 정책이라 Service가 아니라 여기서 정한다.
  static const int popularCount = 5;

  final TmdbMovieService _service;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> loadPopular() async {
    status = MovieHomeLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      // 5개보다 적게 와도 take는 있는 만큼만 돌려준다. ([0]~[4] 직접 접근 금지)
      popularMovies = page.results.take(popularCount).toList();
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } on DioException catch (error) {
      debugPrint('인기 영화 로드 실패: ${error.type} ${error.response?.statusCode}');
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.\n잠시 후 다시 시도해주세요.';
    } catch (error, stackTrace) {
      // 응답 모양이 예상과 달라 DTO 변환(as 캐스팅)에서 실패한 경우 등.
      debugPrint('인기 영화 변환 실패: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
      status = MovieHomeLoadStatus.error;
      message = '인기 영화 정보를 읽지 못했어요.\n잠시 후 다시 시도해주세요.';
    }

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
