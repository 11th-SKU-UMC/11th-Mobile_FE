class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.genreNames,
    required this.voteAverage,
    required this.popularity,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final List<int> genreIds;

  /// 상세 조회(`/movie/{id}`)는 `genre_ids` 대신 `genres` 객체 배열을 반환합니다.
  final List<String> genreNames;
  final double voteAverage;
  final double popularity;

  /// release_date가 비어 있으면 연도를 표시하지 않습니다.
  String? get releaseYear {
    final date = releaseDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }

  /// TMDB 평균(10점 만점)을 5점 만점으로 변환합니다.
  double get fiveStarAverage => voteAverage / 2;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    final genres = json['genres'] as List<dynamic>? ?? const [];

    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: json['genre_ids'] != null
          ? (json['genre_ids'] as List<dynamic>)
                .map((value) => (value as num).toInt())
                .toList()
          : genres
                .map(
                  (genre) =>
                      ((genre as Map<String, dynamic>)['id'] as num).toInt(),
                )
                .toList(),
      genreNames: genres
          .map((genre) => (genre as Map<String, dynamic>)['name'] as String)
          .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }
}
