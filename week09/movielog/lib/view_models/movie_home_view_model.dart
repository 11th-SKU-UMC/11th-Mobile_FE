import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_status.dart';

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> popularMovies = const [];
  LoadStatus status = LoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> loadPopular() async {
    status = LoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      // 결과가 5개보다 적어도 take(5)는 있는 만큼만 반환합니다.
      popularMovies = page.results.take(5).toList();
      status = popularMovies.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on DioException catch (error) {
      status = LoadStatus.error;
      message = tmdbErrorMessage(error, '인기 영화를 불러오지 못했어요.');
    }

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
