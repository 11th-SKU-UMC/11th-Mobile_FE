import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_page.dart';

/// TMDB Popular·Discover·Genre API를 호출하고 응답을 DTO로 바꾼다.
///
/// HTTP와 DTO 변환만 담당한다. '인기 5개', '최대 30개', '선택된 장르' 같은
/// 화면 정책은 ViewModel이 정한다. 상태가 없어서 여러 ViewModel이 함께 써도 된다.
class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// [genreId]가 null이면 `with_genres`를 보내지 않는다. ('전체')
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        'with_genres': ?genreId,
      },
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

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
