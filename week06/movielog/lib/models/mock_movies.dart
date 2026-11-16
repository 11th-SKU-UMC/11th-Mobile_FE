import '../models/movie.dart';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    rating: 4.8,
    runtime: 124,
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.\n\n'
        '잔잔한 감동과 함께 삶의 의미를 다시 한번 되돌아보게 만드는 수작입니다.',
    tags: ['로맨스', '드라마', '감동적인'],
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    rating: 4.2,
    runtime: 110,
    synopsis: '우주 끝에서 홀로 남겨진 우주비행사의 고독과 발견을 그린 SF 영화입니다.',
    tags: ['SF', '모험'],
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2024,
    rating: 4.9,
    runtime: 98,
    synopsis: '신비로운 숲에서 만난 작은 존재와의 우정을 그린 애니메이션입니다.',
    tags: ['애니메이션', '힐링'],
    posterAsset:
        'assets/images/posters/poster_whispering_woods.jpg', // 실제 파일명으로 교체
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    rating: 3.8,
    runtime: 105,
    synopsis: '어둠이 내린 도시에서 사라진 단서를 쫓는 한 남자의 이야기입니다.',
    tags: ['스릴러', '미스터리'],
    posterAsset:
        'assets/images/posters/poster_night_shadows.jpg', // 실제 파일명으로 교체
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
