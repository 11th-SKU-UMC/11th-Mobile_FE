import '../models/movie.dart';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    rating: 4.8,
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. '
        '매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 '
        '남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 됩니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    rating: 4.2,
    synopsis: '미지의 신호를 따라 우주의 끝으로 향한 탐사대가 마주한 선택과 희망을 그린 SF 영화입니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    rating: 4.9,
    synopsis: '사라진 기억을 찾아 신비한 숲으로 들어간 주인공의 따뜻한 모험을 담았습니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    rating: 3.8,
    synopsis: '도시의 밤마다 반복되는 수수께끼를 추적하는 인물들의 긴장감 넘치는 이야기입니다.',
  ),
  Movie(
    id: 5,
    title: '네 번째 오후',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    rating: 4.4,
    synopsis: '평범한 오후에 다시 만난 네 친구가 각자의 지난 시간을 마주하는 잔잔한 드라마입니다.',
  ),
  Movie(
    id: 6,
    title: '심연을 걷는 자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    rating: 4.1,
    synopsis: '깊은 심연 속 단서를 좇으며 자신의 과거와 맞서는 한 탐험가의 이야기입니다.',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
