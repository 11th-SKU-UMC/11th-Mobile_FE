class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.runtime,
    required this.synopsis,
    required this.tags,
    required this.posterAsset,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final double rating;
  final int runtime;
  final String synopsis;
  final List<String> tags;
  final String posterAsset;
}