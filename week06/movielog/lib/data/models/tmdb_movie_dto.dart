/// TMDB Popular·Discover 응답의 영화 한 편.
///
/// [id]는 TMDB가 영화를 식별하는 값이라, 이후 평점을 저장할 때 `movieId`로 그대로 쓴다.
class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;

  /// `yyyy-MM-dd`. 개봉일이 없으면 null 또는 빈 문자열이 온다.
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }
}
