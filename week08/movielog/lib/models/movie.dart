/// 3~4주차에서 사용한 Mock 영화 모델입니다.
/// 5주차부터 화면은 TMDB DTO를 사용하고, 이 데이터는 FakeMovieService 테스트에 사용합니다.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
}

const mockMovies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
  ),
  Movie(
    id: 2,
    title: '우주의 메아리',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
  ),
  Movie(
    id: 3,
    title: '심연을 걷는 자',
    genre: 'SF',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
  ),
  Movie(
    id: 4,
    title: '네 번째 오후',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
  ),
  Movie(
    id: 5,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
  ),
  Movie(
    id: 6,
    title: '속삭이는 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
