import '../models/movie.dart';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/movie_1.png',
    description: '서로 다른 삶을 살아온 두 사람이 별빛 아래에서 만나게 되는 이야기입니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/movie_2.png',
    description: '미지의 우주를 향해 떠난 탐사대의 이야기를 그린 SF 영화입니다.',
  ),
  Movie(
    id: 3,
    title: '여름의 기억',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/movie_3.png',
    description: '오랜 시간이 지난 뒤 다시 마주한 여름의 기억을 다룹니다.',
  ),
  Movie(
    id: 4,
    title: '로봇의 꿈',
    genre: '애니메이션',
    year: 2024,
    posterAsset: 'assets/images/movie_4.png',
    description: '꿈을 꾸기 시작한 로봇의 특별한 모험 이야기입니다.',
  ),
  Movie(
    id: 5,
    title: '화성으로',
    genre: 'SF',
    year: 2025,
    posterAsset: 'assets/images/movie_5.png',
    description: '인류 최초의 화성 정착을 준비하는 사람들의 이야기입니다.',
  ),
  Movie(
    id: 6,
    title: '우리들의 하루',
    genre: '애니메이션',
    year: 2023,
    posterAsset: 'assets/images/movie_6.png',
    description: '평범한 하루 속에서 발견하는 소소한 행복을 담았습니다.',
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
