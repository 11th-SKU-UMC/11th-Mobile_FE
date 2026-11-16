import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../models/tmdb_movie_page.dart';

class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  // 인기 영화 조회
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );

    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  // 전체 또는 특정 장르의 영화 조회
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        if (genreIds != null && genreIds.isNotEmpty)
          'with_genres': genreIds.join('|'),
      },
    );

    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  // 영화 상세 조회
  Future<TmdbMovieDto> fetchMovieDetails(int movieId) async {
    final response = await _dio.get(
      '/movie/$movieId',
      queryParameters: {'language': 'ko-KR'},
    );
    return TmdbMovieDto.fromJson(response.data as Map<String, dynamic>);
  }

  // 영화 장르 목록 조회
  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );

    final data = response.data as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>? ?? const [];

    return genres
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
