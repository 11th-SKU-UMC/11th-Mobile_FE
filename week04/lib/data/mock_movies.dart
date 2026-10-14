import '../models/movie.dart';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/movie_1.png',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/movie_2.png',
  ),
  Movie(
    id: 3,
    title: '봄날의 기억',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/movie_3.png',
  ),
  Movie(
    id: 4,
    title: '마지막 행성',
    genre: 'SF',
    year: 2025,
    posterAsset: 'assets/images/movie_4.png',
  ),
  Movie(
    id: 5,
    title: '우리들의 여름',
    genre: '로맨스',
    year: 2024,
    posterAsset: 'assets/images/movie_5.png',
  ),
  Movie(
    id: 6,
    title: '두 번째 편지',
    genre: '로맨스',
    year: 2023,
    posterAsset: 'assets/images/movie_6.png',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) {
      return movie;
    }
  }

  return null;
}