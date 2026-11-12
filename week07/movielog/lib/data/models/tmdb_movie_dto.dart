import 'tmdb_genre_dto.dart';

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
    this.genres = const [],
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;
  final List<TmdbGenreDto> genres;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    final genres = (json['genres'] as List<dynamic>? ?? const [])
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: json['genre_ids'] == null
          ? genres.map((genre) => genre.id).toList()
          : (json['genre_ids'] as List<dynamic>)
                .map((value) => (value as num).toInt())
                .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
      genres: genres,
    );
  }
}
